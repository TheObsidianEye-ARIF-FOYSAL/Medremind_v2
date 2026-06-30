import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// Server URL configured at build time:
//   flutter run --dart-define=SERVER_BASE_URL=https://your-server.com/path
const _kDefaultBaseUrl = String.fromEnvironment(
  'SERVER_BASE_URL',
  defaultValue: 'https://ruetandroiddevelopers.com/ARIF(Futrix)',
);

class AuthService {
  final Map<String, String> _referenceByPhone = {};
  final String _baseUrl;

  AuthService({String? baseUrl})
      : _baseUrl = _sanitize(baseUrl ?? _kDefaultBaseUrl);

  // ── OTP flow ──────────────────────────────────────────────────────────────

  Future<void> sendOtp(String phone) async {
    final normalized = _normalize(phone);
    final response = await http
        .post(
          Uri.parse('$_baseUrl/send_otp.php'),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'user_mobile': normalized},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('OTP request failed (${response.statusCode})');
    }

    final map = _json(response.body);
    final ref =
        (map['referenceNo'] ?? map['reference_no'] ?? '').toString().trim();
    if (ref.isNotEmpty) {
      _referenceByPhone[normalized] = ref;
      return;
    }

    final code = (map['statusCode'] ?? 'UNKNOWN').toString();
    final detail =
        (map['statusDetail'] ?? 'Unable to request OTP').toString();
    throw Exception('$detail ($code)');
  }

  Future<bool> verifyOtp(String phone, String code) async {
    final normalized = _normalize(phone);
    final ref = _referenceByPhone[normalized];
    if (ref == null || ref.isEmpty) {
      throw Exception('No OTP request found. Please request OTP again.');
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/verify_otp.php'),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
          },
          body: {'Otp': code, 'referenceNo': ref},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('OTP verification failed (${response.statusCode})');
    }

    final map = _json(response.body);
    final status = _upperTrim(
        map['subscriptionStatus'] ?? map['subscription_status'] ?? '');
    final accepted = {
      'REGISTERED', 'SUBSCRIBED', 'ACTIVE', 'S1000',
      'INITIAL CHARGING PENDING', 'PENDING INITIAL CHARGING'
    };
    if (accepted.contains(status)) {
      _referenceByPhone.remove(normalized);
      return true;
    }
    if (_upperTrim(map['statusCode'] ?? '') == 'S1000') {
      _referenceByPhone.remove(normalized);
      return true;
    }
    return false;
  }

  // ── Unsubscribe ────────────────────────────────────────────────────────────

  Future<bool> unsubscribe(String phone) async {
    final normalized = _normalize(phone);
    final subscriberId = normalized.startsWith('0')
        ? '88$normalized'
        : (normalized.length == 10 && normalized.startsWith('1')
            ? '880$normalized'
            : normalized);

    final response = await http
        .post(
          Uri.parse('$_baseUrl/unsubscribe.php'),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'subscriberId': subscriberId}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Unsubscribe failed (${response.statusCode})');
    }

    final map = _json(response.body);
    final code =
        _upperTrim(map['statusCode'] ?? map['status_code'] ?? '');
    final subStatus = _upperTrim(
        map['subscriptionStatus'] ?? map['subscription_status'] ?? '');

    if (code == 'S1000' || subStatus == 'UNREGISTERED') {
      _referenceByPhone.remove(normalized);
      return true;
    }

    final detail =
        (map['statusDetail'] ?? map['status_detail'] ?? 'Unsubscribe failed')
            .toString()
            .trim();
    throw Exception(detail.isEmpty ? 'Unsubscribe failed' : detail);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _json(String raw) {
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) return data;
      throw const FormatException();
    } catch (_) {
      throw Exception('Invalid server response');
    }
  }

  String _normalize(String phone) {
    final d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('880') && d.length > 10) return d.substring(3);
    if (d.startsWith('88') && d.length > 11) return d.substring(2);
    return d;
  }

  String _upperTrim(dynamic v) =>
      v.toString().toUpperCase().replaceAll('_', ' ').trim();

  static String _sanitize(String raw) {
    final t = raw.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }
}
