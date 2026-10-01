import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:md_codebar_scanner/models/batch_label_item.dart';
import 'package:md_codebar_scanner/services/batch_label_controller.dart';
import 'package:md_codebar_scanner/services/scan_feedback.dart';
import 'package:md_codebar_scanner/utils/colors.dart';
import 'package:md_codebar_scanner/utils/constants.dart';
import 'package:md_codebar_scanner/utils/messages.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'batch_print_screen.dart';

enum BatchInputMode {
  camera,
  reader;

  static BatchInputMode fromString(String? value) =>
      value == BatchInputMode.reader.name
      ? BatchInputMode.reader
      : BatchInputMode.camera;
}

/// Escaneo continuo para re-etiquetación masiva: la cámara no se cierra y cada
/// código se agrega a la lista mientras el producto se consulta en segundo plano.
class BatchScanScreen extends StatefulWidget {
  const BatchScanScreen({super.key});

  @override
  State<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends State<BatchScanScreen> {
  final BatchLabelController _batch = BatchLabelController();
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();

  // Última vez que la cámara vio cada código: mientras el código siga frente a
  // la cámara no se vuelve a contar.
  final Map<String, DateTime> _lastSeen = {};

  MobileScannerController? _scannerController;
  BatchInputMode _inputMode = BatchInputMode.camera;
  bool _isStartingCamera = false;
  // En modo lector el teclado en pantalla va oculto: el lector óptico escribe
  // como teclado físico. Se muestra solo para capturar a mano.
  bool _softKeyboard = false;

  String? _lastScanMessage;
  Timer? _lastScanTimer;

  // Detección de ráfaga del lector óptico, para lectores sin sufijo Enter
  DateTime? _burstStart;
  Timer? _autoSubmitTimer;

  bool get _showCamera => _inputMode == BatchInputMode.camera;

  @override
  void initState() {
    super.initState();
    _codeFocus.onKeyEvent = _onReaderKey;
    _batch.onLookupFailed = (_) => ScanFeedback.error();
    _batch.load();
    _loadInputMode();
  }

  Future<void> _loadInputMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = BatchInputMode.fromString(
      prefs.getString(AppConstants.prefsBatchInputMode),
    );
    if (!mounted) return;
    await _setInputMode(mode, save: false);
  }

  Future<void> _setInputMode(BatchInputMode mode, {bool save = true}) async {
    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefsBatchInputMode, mode.name);
    }
    if (!mounted) return;

    if (mode == BatchInputMode.camera) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _inputMode = mode;
        _softKeyboard = false;
      });
      await _startCamera();
    } else {
      _stopCamera();
      setState(() {
        _inputMode = mode;
        _softKeyboard = false;
      });
      _focusReader();
    }
  }

  void _focusReader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_showCamera) _codeFocus.requestFocus();
    });
  }

  /// Cambiar el tipo de teclado requiere reconectar el campo con el IME.
  void _toggleSoftKeyboard() {
    _codeFocus.unfocus();
    setState(() => _softKeyboard = !_softKeyboard);
    _focusReader();
  }

  @override
  void dispose() {
    _lastScanTimer?.cancel();
    _autoSubmitTimer?.cancel();
    _scannerController?.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    _batch.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (_scannerController != null) return;
    setState(() => _isStartingCamera = true);

    var status = await Permission.camera.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status != PermissionStatus.granted) {
      setState(() => _isStartingCamera = false);
      MessageUtils.showErrorMessage(context, 'Permiso de cámara denegado');
      await _setInputMode(BatchInputMode.reader, save: false);
      return;
    }

    setState(() {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      _isStartingCamera = false;
    });
  }

  void _stopCamera() {
    _scannerController?.dispose();
    _scannerController = null;
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final now = DateTime.now();

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) continue;

      final previous = _lastSeen[code];
      _lastSeen[code] = now;
      final stillInFront =
          previous != null &&
          now.difference(previous).inMilliseconds <
              AppConstants.batchRescanCooldownMs;

      if (!stillInFront) _addCode(code);
    }
  }

  /// Enter / Tab que manda el lector como tecla física. Con el teclado en
  /// pantalla oculto Android no los convierte en "enviar", por eso se
  /// capturan aquí antes de que lleguen al campo.
  KeyEventResult _onReaderKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isSubmitKey =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.tab;
    if (!isSubmitKey) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent) _submitManualCode();
    return KeyEventResult.handled;
  }

  /// Si el lector no manda sufijo, se agrega el código cuando termina la
  /// ráfaga. El lector escribe todo en milisegundos; una persona tecleando
  /// es más lenta y no dispara el envío automático.
  void _onReaderChanged(String text) {
    _autoSubmitTimer?.cancel();
    if (_softKeyboard || text.isEmpty) {
      _burstStart = null;
      return;
    }

    _burstStart ??= DateTime.now();
    _autoSubmitTimer = Timer(
      Duration(milliseconds: AppConstants.readerIdleMs),
      () {
        final start = _burstStart;
        _burstStart = null;
        final code = _codeController.text.trim();
        if (start == null || code.length < AppConstants.readerMinLength) {
          return;
        }

        final typingMs =
            DateTime.now().difference(start).inMilliseconds -
            AppConstants.readerIdleMs;
        if (typingMs <= code.length * AppConstants.readerMaxMsPerChar) {
          _submitManualCode();
        }
      },
    );
  }

  void _submitManualCode() {
    _autoSubmitTimer?.cancel();
    _burstStart = null;
    final code = _codeController.text.trim();
    _codeController.clear();
    if (code.isNotEmpty) _addCode(code);
    // El lector de hardware (teclado) sigue escribiendo en el mismo campo
    _codeFocus.requestFocus();
  }

  void _addCode(String code) {
    final result = _batch.addScan(code);

    switch (result) {
      case BatchScanResult.added:
        ScanFeedback.success();
        _showScanMessage('Agregado: $code');
      case BatchScanResult.incremented:
        ScanFeedback.success();
        _showScanMessage('+1 impresión: $code');
      case BatchScanResult.maxReached:
        ScanFeedback.error();
        _showScanMessage(
          'Máximo de ${AppConstants.batchMaxCopies} impresiones: $code',
        );
    }
  }

  void _showScanMessage(String message) {
    _lastScanTimer?.cancel();
    setState(() => _lastScanMessage = message);
    _lastScanTimer = Timer(Duration(seconds: 2), () {
      if (mounted) setState(() => _lastScanMessage = null);
    });
  }

  Future<void> _confirmClear() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_sweep, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Eliminar lista'),
          ],
        ),
        content: Text(
          '¿Deseas eliminar los ${_batch.items.length} productos escaneados?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _batch.clear();
      _lastSeen.clear();
    }
  }

  Future<void> _openPrintScreen() async {
    await _scannerController?.stop();
    if (!mounted) return;

    final printedAll = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => BatchPrintScreen(batch: _batch)),
    );

    if (!mounted) return;
    _lastSeen.clear();
    if (_showCamera) {
      await _scannerController?.start();
    } else {
      _focusReader();
    }

    if (printedAll == true && mounted) {
      MessageUtils.showSuccessMessage(context, 'Lote impreso correctamente');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _batch,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Impresión en Lote'),
            centerTitle: true,
            elevation: 0,
            actions: [
              if (_showCamera)
                IconButton(
                  icon: Icon(Icons.flash_on),
                  onPressed: () => _scannerController?.toggleTorch(),
                  tooltip: 'Flash',
                ),
              if (!_batch.isEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep),
                  onPressed: _confirmClear,
                  tooltip: 'Eliminar lista',
                ),
            ],
          ),
          body: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildModeSelector(),
                  if (_showCamera) _buildCamera() else _buildReaderInput(),
                  if (_lastScanMessage != null) _buildScanMessage(),
                  _buildListHeader(),
                  Expanded(child: _buildList()),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCamera() {
    return Container(
      height: 200,
      margin: EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_scannerController != null)
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onBarcodeDetected,
              ),
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Escanea productos uno tras otro',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<BatchInputMode>(
          segments: [
            ButtonSegment(
              value: BatchInputMode.camera,
              icon: Icon(Icons.camera_alt),
              label: Text('Cámara'),
            ),
            ButtonSegment(
              value: BatchInputMode.reader,
              icon: Icon(Icons.barcode_reader),
              label: Text('Lector / Teclado'),
            ),
          ],
          selected: {_inputMode},
          showSelectedIcon: false,
          onSelectionChanged: _isStartingCamera
              ? null
              : (selection) => _setInputMode(selection.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: Colors.white,
            foregroundColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildReaderInput() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _codeController,
        focusNode: _codeFocus,
        autofocus: true,
        showCursor: true,
        keyboardType: _softKeyboard ? TextInputType.text : TextInputType.none,
        textInputAction: TextInputAction.done,
        onChanged: _onReaderChanged,
        onSubmitted: (_) => _submitManualCode(),
        style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          hintText: _softKeyboard
              ? 'Escribe el código'
              : 'Escanea con el lector óptico',
          prefixIcon: Icon(Icons.qr_code, color: AppColors.primary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _softKeyboard ? Icons.keyboard_hide : Icons.keyboard,
                  color: AppColors.textSecondary,
                ),
                onPressed: _toggleSoftKeyboard,
                tooltip: _softKeyboard ? 'Ocultar teclado' : 'Mostrar teclado',
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary),
                onPressed: _submitManualCode,
                tooltip: 'Agregar',
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _buildScanMessage() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastScanMessage!,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            'Escaneados (${_batch.items.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Spacer(),
          Text(
            '${_batch.totalLabels} etiquetas',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_batch.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.qr_code_scanner,
              size: 56,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 12),
            Text(
              'Aún no hay productos escaneados',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _batch.items.length,
      itemBuilder: (context, index) {
        final item = _batch.items[index];
        return Dismissible(
          key: ObjectKey(item),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _batch.remove(item),
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            margin: EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: _buildItem(item),
        );
      },
    );
  }

  Widget _buildItem(BatchLabelItem item) {
    final isError = item.status == BatchItemStatus.error;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorLight : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isError ? AppColors.error : AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: _statusIcon(item)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (item.status) {
                    BatchItemStatus.ready => item.product!.itemName,
                    BatchItemStatus.loading => 'Buscando...',
                    BatchItemStatus.error => item.errorMessage ?? 'Error',
                  },
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isError ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  item.code,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isError)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primary),
              onPressed: () => _batch.retry(item),
              tooltip: 'Reintentar',
            )
          else
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    '${item.copies}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusIcon(BatchLabelItem item) {
    switch (item.status) {
      case BatchItemStatus.loading:
        return Padding(
          padding: EdgeInsets.all(3),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
      case BatchItemStatus.ready:
        return Icon(Icons.check_circle, color: AppColors.success);
      case BatchItemStatus.error:
        return Icon(Icons.error_outline, color: AppColors.error);
    }
  }

  Widget _buildBottomBar() {
    final canContinue = _batch.readyItems.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: canContinue ? _openPrintScreen : null,
          icon: Icon(Icons.checklist),
          label: Text(
            'Revisar e imprimir (${_batch.readyItems.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
