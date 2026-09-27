class InvoiceSettings {
  final String logo;
  final String primaryColor;
  final String secondaryColor;
  final String footerMessage;
  final String termsAndConditions;
  final String upiId;

  InvoiceSettings({
    this.logo = '',
    this.primaryColor = '#4A6CF7',
    this.secondaryColor = '#25D366',
    this.footerMessage = 'Thank you for choosing our garage!',
    this.termsAndConditions = '',
    this.upiId = '',
  });

  factory InvoiceSettings.fromJson(Map<String, dynamic> json) {
    return InvoiceSettings(
      logo: json['logo']?.toString() ?? '',
      primaryColor: json['primaryColor']?.toString() ?? '#4A6CF7',
      secondaryColor:
          json['secondaryColor']?.toString() ?? '#25D366',
      footerMessage: json['footerMessage']?.toString() ??
          'Thank you for choosing our garage!',
      termsAndConditions:
          json['termsAndConditions']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'footerMessage': footerMessage,
      'termsAndConditions': termsAndConditions,
      'upiId': upiId,
    };
  }

  InvoiceSettings copyWith({
    String? logo,
    String? primaryColor,
    String? secondaryColor,
    String? footerMessage,
    String? termsAndConditions,
    String? upiId,
  }) {
    return InvoiceSettings(
      logo: logo ?? this.logo,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      footerMessage: footerMessage ?? this.footerMessage,
      termsAndConditions:
          termsAndConditions ?? this.termsAndConditions,
      upiId: upiId ?? this.upiId,
    );
  }
}