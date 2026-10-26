import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

class PrintProgressDialog {
  static bool _isDialogClosed = false;
  static late BuildContext _dialogContext;

  /// [progress] es opcional: texto que se actualiza durante la impresión
  /// (p. ej. "3 de 12 productos" en la impresión en lote).
  static void show(
    BuildContext context,
    String printerName, {
    String title = 'Imprimiendo etiqueta...',
    ValueListenable<String>? progress,
  }) {
    _isDialogClosed = false;
    if (!context.mounted) {
      log('⚠️ Contexto no está montado, no se puede mostrar diálogo');
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        _dialogContext = ctx;
        return _buildDialog(printerName, title, progress);
      },
    );
  }

  static Widget _buildDialog(
    String printerName,
    String title,
    ValueListenable<String>? progress,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enviando a $printerName',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: progress,
                builder: (context, value, _) => Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void close() {
    if (!_isDialogClosed) {
      _isDialogClosed = true;
      try {
        if (_dialogContext.mounted) {
          Navigator.of(_dialogContext).pop();
          log('✅ Diálogo cerrado exitosamente');
        }
      } catch (e) {
        log('❌ Error cerrando diálogo: $e');
      }
    }
  }
}
