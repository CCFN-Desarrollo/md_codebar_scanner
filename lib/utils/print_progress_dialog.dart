import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

class PrintProgressDialog {
  static bool _isDialogClosed = false;
  static late BuildContext _dialogContext;

  static void show(BuildContext context, String printerName) {
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
        return _buildDialog(printerName);
      },
    );
  }

  static Widget _buildDialog(String printerName) {
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
            const Text(
              'Imprimiendo etiqueta...',
              style: TextStyle(
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
