import 'package:flutter/material.dart';

class AppColors {
  // Color principal de la aplicación
  static const Color primary = Color(0xFF102d5c);

  // Colores secundarios
  static const Color secondary = Color(0xFF6B7280);
  static const Color accent = Color(0xFF3B82F6);

  // Colores de estado
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  // Colores de fondo
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF9FAFB);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Colores de texto
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Colores de bordes
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF102d5c), Color(0xFF1e40af)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFF9FAFB), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Métodos de utilidad
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1, 'Amount must be between 0 and 1');
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  // Métodos para obtener colores con transparencia predefinida
  static Color get primaryLight => primary.withOpacity(0.1);
  static Color get primaryMedium => primary.withOpacity(0.5);
  static Color get primaryDark => darken(primary, 0.2);

  static Color get successLight => success.withOpacity(0.1);
  static Color get errorLight => error.withOpacity(0.1);
  static Color get warningLight => warning.withOpacity(0.1);
  static Color get infoLight => info.withOpacity(0.1);

  // Colores específicos para diferentes estados de componentes
  static Color get inputBackground => Colors.white;
  static Color get inputBorder => border;
  static Color get inputFocusedBorder => primary;
  static Color get inputErrorBorder => error;

  // Colores para la app bar
  static Color get appBarBackground => primary;
  static Color get appBarForeground => Colors.white;

  // Colores para cards y containers
  static Color get cardShadow => Colors.grey.withOpacity(0.1);
  static Color get containerBorder => border;
}
