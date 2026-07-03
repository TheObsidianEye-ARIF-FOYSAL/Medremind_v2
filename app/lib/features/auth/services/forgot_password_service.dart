import 'dart:convert';

import 'package:http/http.dart' as http;

// Deployed separately from the main SERVER_BASE_URL folder (server/) — see
// server_forgot_password/fp_config.php for why it must share the same
// medremind_users.db.
const _kDefaultBaseUrl = String.fromEnvironment(
  'FORGOT_PASSWORD_BASE_URL',
  defaultValue: 'https://ruetandroiddevelopers.com/ARIF(MRe)-forgot-password',
);

/// P5 Forgot password: request a BDApps OTP for a phone that's already
/// registered, then submit the OTP + new password together to reset it.
/// Talks to server_forgot_password/fp_request_reset.php and
/// fp_reset_password.php.
class ForgotPasswordService {
  final String _baseUrl;

  ForgotPasswordService({String? baseUrl})
      : _baseUrl = _sanitize(baseUrl ?? _kDefaultBaseUrl);

  Future<String> requestReset(String phone) async {
    final map = await _post('fp_request_reset.php', {'phone': phone});
    return map['referenceNo'] as String;
  }

  Future<void> resetPassword({
    required String phone,
    required String referenceNo,
    required String otp,
    required String newPassword,
  }) async {
    await _post('fp_reset_password.php', {
      'phone': phone,
      'referenceNo': referenceNo,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> _post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/$endpoint'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    final map = _json(response.body);
    if (response.statusCode != 200) {
      throw Exception(
          (map['error'] ?? 'Request failed (${response.statusCode})')
              .toString());
    }
    return map;
  }

  Map<String, dynamic> _json(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;
      throw const FormatException();
    } catch (_) {
      throw Exception('Invalid server response');
    }
  }

  String mapError(Object e) => e.toString().replaceFirst('Exception: ', '');

  static String _sanitize(String raw) {
    final t = raw.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
