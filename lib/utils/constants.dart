class AppConstants {
  // Autenticación
  static const String correctPassword = "Chivas.2020";

  // Claves de SharedPreferences
  static const String prefsSucursal = 'sucursal';
  static const String prefsServidor = 'servidor';
  static const String prefsSelectedPrinter = 'selectedPrinterAddress';
  static const String prefsSelectedPrinterName = 'selectedPrinterName';

  // Configuración UI
  static const int notFoundDisplayDuration = 5; // seconds
  static const int scanAnimationDuration = 2; // seconds

  // URLs y endpoints (para futuro uso)
  static const String baseApiUrl = 'https://api.ejemplo.com';
  static const String productEndpoint = '/products';

  // Configuraciones de la app
  static const String appName = 'Barcode Scanner';
  static const String appVersion = '1.0.0';

  // Mensajes de error
  static const String errorIncorrectPassword = 'Contraseña incorrecta';
  static const String errorProductNotFound = 'Producto no encontrado';
  static const String errorNetworkConnection = 'Error de conexión';
  static const String errorUnknown = 'Error desconocido';

  // Mensajes de éxito
  static const String successConfigSaved =
      'Configuración guardada exitosamente';
  static const String successProductFound = 'Producto encontrado';

  // Configuraciones de impresión
  static const String printCompanyName = 'Mi Empresa';
  static const String printFooter = 'Gracias por su compra';
  static const String printerModel = 'TSC Alpha-3RB';
  static const String printerType = 'Térmica de etiquetas';

  // Configuraciones específicas de TSC
  static const double labelWidth = 58.0; // mm
  static const double labelHeight = 40.0; // mm
  static const double labelGap = 2.0; // mm

  //Configuraciones font size tool tips
  static const double titleFontSize = 16;
  static const double subtitleFontSize = 14;
}
