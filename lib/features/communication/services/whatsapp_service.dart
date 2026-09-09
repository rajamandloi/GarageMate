import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static Future<bool> sendMessage({
    required String phone,
    required String message,
  }) async {
    final cleanedPhone = _cleanPhoneNumber(phone);

    if (cleanedPhone.isEmpty) {
      return false;
    }

    final encodedMessage = Uri.encodeComponent(message);

    final uri = Uri.parse(
      'https://wa.me/$cleanedPhone?text=$encodedMessage',
    );

    if (!await canLaunchUrl(uri)) {
      return false;
    }

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  static String _cleanPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }

    return cleaned;
  }

  static String serviceReminderMessage({
    required String customerName,
    required String vehicle,
    required String registrationNumber,
    required String dueText,
    required String garageName,
  }) {
    return '''
Hello $customerName,

This is a friendly service reminder from $garageName.

Your vehicle:
$vehicle
Registration: $registrationNumber

Service status:
$dueText

Please contact us to schedule your vehicle service.

Thank you,
$garageName
''';
  }

  static String specialOfferMessage({
    required String customerName,
    required String offerTitle,
    required String offerDescription,
    required String validTill,
    required String garageName,
  }) {
    return '''
Hello $customerName,

We have a special offer for you from $garageName!

$offerTitle

$offerDescription

Offer valid till: $validTill

Contact us to book your service.

Thank you,
$garageName
''';
  }
}