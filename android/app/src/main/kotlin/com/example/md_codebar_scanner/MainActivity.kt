package com.example.md_codebar_scanner

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Beep al escanear (lado Dart: lib/services/scan_feedback.dart)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "md_codebar_scanner/beep")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "success" -> {
                        playTone(ToneGenerator.TONE_PROP_BEEP, 150)
                        result.success(null)
                    }
                    "error" -> {
                        playTone(ToneGenerator.TONE_PROP_NACK, 400)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun playTone(tone: Int, durationMs: Int) {
        try {
            // STREAM_MUSIC: suena aunque el teléfono esté en modo silencio/vibración
            val generator = toneGenerator
                ?: ToneGenerator(AudioManager.STREAM_MUSIC, 100).also { toneGenerator = it }
            generator.startTone(tone, durationMs)
        } catch (e: RuntimeException) {
            // Sin audio disponible: se omite el sonido
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
