import 'dart:developer';
import 'package:flutter/services.dart';

/// Sonido + vibración al escanear. El beep lo genera Android (ToneGenerator en
/// MainActivity.kt); si el canal no está disponible se usa el sonido del sistema.
class ScanFeedback {
  static const MethodChannel _channel = MethodChannel(
    'md_codebar_scanner/beep',
  );

  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await _play('success');
  }

  static Future<void> error() async {
    HapticFeedback.heavyImpact();
    await _play('error');
  }

  static Future<void> _play(String method) async {
    try {
      await _channel.invokeMethod(method);
    } on MissingPluginException {
      SystemSound.play(SystemSoundType.click);
    } on PlatformException catch (e) {
      log('Error reproduciendo beep: $e');
    }
  }
}
