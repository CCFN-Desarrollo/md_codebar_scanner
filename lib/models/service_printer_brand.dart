/// Perfil de la impresora conectada al Scanner Agent.
enum ServicePrinterBrand {
  zebra,
  bixolon;

  static ServicePrinterBrand fromString(String? value) =>
      value == 'bixolon' ? bixolon : zebra;

  String get label => this == bixolon ? 'BIXOLON' : 'Zebra';
}
