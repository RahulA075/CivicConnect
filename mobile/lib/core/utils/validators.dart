/// Form-field validators for CivicConnect.
/// Each method returns `null` on success or an error string.
abstract final class Validators {
  // ── Email ───────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false);
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  // ── Password ────────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  // ── Phone ────────────────────────────────────────────────────────
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10 || digits.length > 12) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ── OTP ──────────────────────────────────────────────────────────
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter the 6-digit OTP';
    return null;
  }

  // ── Name ─────────────────────────────────────────────────────────
  static String? name(String? value, {String label = 'Name'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (value.trim().length < 2) return '$label is too short';
    if (value.trim().length > 100) return '$label is too long';
    return null;
  }

  // ── Required text ────────────────────────────────────────────────
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  // ── Issue description ────────────────────────────────────────────
  static String? issueDescription(String? value) {
    if (value == null || value.trim().isEmpty) return 'Description is required';
    if (value.trim().length < 20) return 'Please provide at least 20 characters';
    if (value.trim().length > 2000) return 'Description must be under 2000 characters';
    return null;
  }

  // ── URL ──────────────────────────────────────────────────────────
  static String? url(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final pattern = RegExp(r'^https?://[\w-]+(\.[\w-]+)+([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?$');
    if (!pattern.hasMatch(value.trim())) return 'Enter a valid URL';
    return null;
  }
}
