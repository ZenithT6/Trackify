class Validators {
  /// Validates email with common enterprise format support
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailPattern =
        r"^[a-zA-Z0-9]+([._%+-]?[a-zA-Z0-9]+)*@[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+$";
    final regex = RegExp(emailPattern);

    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid business or personal email address';
    }

    return null;
  }

  /// Strong password validation (used in real login systems)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final errors = <String>[];

    if (value.length < 8) {
      errors.add('• Minimum 8 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      errors.add('• At least one uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      errors.add('• At least one lowercase letter');
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      errors.add('• At least one number');
    }
    if (!RegExp(r'[!@#\$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]').hasMatch(value)) {
      errors.add('• At least one special character');
    }

    if (errors.isNotEmpty) {
      return 'Password must contain:\n' + errors.join('\n');
    }

    return null;
  }

  /// Full name validation with international support
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }

    final namePattern = r"^[a-zA-ZÀ-ÿ ,.'-]+$";
    if (!RegExp(namePattern).hasMatch(value.trim())) {
      return 'Enter a valid name';
    }

    return null;
  }

  /// Phone number validation (10–15 digits)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phonePattern = r'^\d{10,15}$';
    if (!RegExp(phonePattern).hasMatch(value.trim())) {
      return 'Enter a valid phone number (10–15 digits)';
    }

    return null;
  }

  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Generic required field validator
  static String? validateRequired(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
