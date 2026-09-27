class PhoneHelper {
  // ============================================================
  // COUNTRY CODE
  // ============================================================

  static const String countryCode = '91';
  static const String countryCodeDisplay = '+91';

  // ============================================================
  // VALIDATE INDIAN MOBILE NUMBER
  // (10 digits, starts with 6/7/8/9)
  // ============================================================

  static bool isValidIndianMobile(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) return false;

    // First digit must be 6, 7, 8, or 9
    final first = digits[0];
    if (!['6', '7', '8', '9'].contains(first)) {
      return false;
    }

    return true;
  }

  // ============================================================
  // EXTRACT 10-DIGIT NUMBER
  // (removes +91, 91, 0 prefix, spaces, etc.)
  // ============================================================

  static String extractTenDigits(String phone) {
    // Remove all non-digits
    var digits = phone.replaceAll(RegExp(r'\D'), '');

    // Remove leading "91" if present (but only if length > 10)
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    // Remove leading "0" if present
    if (digits.length > 10 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // If longer than 10, take last 10
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return digits;
  }

  // ============================================================
  // FORMAT FOR DISPLAY (+91 98765 43210)
  // ============================================================

  static String formatForDisplay(String phone) {
    final tenDigits = extractTenDigits(phone);

    if (tenDigits.length != 10) {
      return phone;
    }

    return '$countryCodeDisplay '
        '${tenDigits.substring(0, 5)} '
        '${tenDigits.substring(5)}';
  }

  // ============================================================
  // FOR WHATSAPP (919876543210 — no +, no spaces)
  // ============================================================

  static String toWhatsAppNumber(String phone) {
    final tenDigits = extractTenDigits(phone);

    if (tenDigits.length != 10) {
      // Return empty if invalid
      return '';
    }

    return '$countryCode$tenDigits';
  }

  // ============================================================
  // BUILD WHATSAPP URL
  // ============================================================

  static Uri buildWhatsAppUrl({
    required String phone,
    String? message,
  }) {
    final waNumber = toWhatsAppNumber(phone);

    if (waNumber.isEmpty) {
      return Uri.parse('https://wa.me/');
    }

    if (message == null || message.trim().isEmpty) {
      return Uri.parse('https://wa.me/$waNumber');
    }

    return Uri.parse(
      'https://wa.me/$waNumber?text=${Uri.encodeComponent(message)}',
    );
  }

  // ============================================================
  // VALIDATION MESSAGE
  // ============================================================

  static String? validateIndianMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length != 10) {
      return 'Enter 10-digit mobile number';
    }

    if (!isValidIndianMobile(digits)) {
      return 'Enter a valid mobile number';
    }

    return null;
  }
}