// Same email rule as firestore.rules and functions/src/students.js. Keep all three in sync.
final RegExp _studentEmail = RegExp(
  r'^[A-Za-z0-9._%+-]+@(ogr\.)?agu\.edu\.tr$',
  caseSensitive: false,
);

String? validateUniversityEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Enter your university email.';
  if (!_studentEmail.hasMatch(email)) return 'Use your @agu.edu.tr email address.';
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').length < 6) return 'Password must be at least 6 characters.';
  return null;
}

/// Light client-side check (10 or 13 digits). The Cloud Function does the real checksum test.
String? validateIsbn(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
  if (!RegExp(r'^(\d{13}|\d{9}[\dXx])$').hasMatch(digits)) {
    return 'ISBN must have 10 or 13 digits.';
  }
  return null;
}

String? validatePriceTry(String? value) {
  final n = int.tryParse((value ?? '').trim());
  if (n == null || n <= 0) return 'Enter a whole price in TL.';
  if (n >= 100000) return 'Price looks too high.';
  return null;
}

String? validateRequired(String? value, String label) {
  if ((value ?? '').trim().isEmpty) return 'Enter $label.';
  return null;
}
