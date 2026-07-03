import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/app_user.dart';

const _kDefaultBaseUrl = String.fromEnvironment(
  'SERVER_BASE_URL',
  defaultValue: 'https://ruetandroiddevelopers.com/ARIF(MR)',
);

const _kPhoneKey = 'medremind_session_phone';
const _kTokenKey = 'medremind_session_token';

/// Phone+password identity backed by a small PHP+SQLite API on the same
/// BDApps server used for OTP (see auth_service.dart). No Firebase: the
/// server hashes/verifies passwords with PHP's password_hash/password_verify
/// and issues an opaque session token, cached locally via SharedPreferences.
class UserAuthService {
  final String _baseUrl;

  String? _token;

  UserAuthService({String? baseUrl})
      : _baseUrl = _sanitize(baseUrl ?? _kDefaultBaseUrl);

  /// Reads a previously persisted session (if any) so main.dart can restore
  /// it on app start. Returns the phone number to restore, or null.
  Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_kPhoneKey);
    final token = prefs.getString(_kTokenKey);
    if (phone == null || token == null) return null;
    _token = token;
    return phone;
  }

  Future<void> _persistSession(String phone, String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPhoneKey, phone);
    await prefs.setString(_kTokenKey, token);
  }

  Future<void> _clearSession() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPhoneKey);
    await prefs.remove(_kTokenKey);
  }

  Future<bool> checkPhoneExists(String phone) async {
    final map = await _post('medremind_check_phone.php', {'phone': phone});
    return map['exists'] == true;
  }

  Future<AppUser> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    final map = await _post('medremind_register.php', {
      'phone': phone,
      'name': name,
      'password': password,
    });
    await _persistSession(map['phone'] as String, map['token'] as String);
    return _userFromMap(map);
  }

  Future<AppUser> login({required String phone, required String password}) async {
    final map = await _post('medremind_login.php', {
      'phone': phone,
      'password': password,
    });
    await _persistSession(map['phone'] as String, map['token'] as String);
    return _userFromMap(map);
  }

  Future<void> signOut() => _clearSession();

  /// P4 Unsubscribe: medremind_unsubscribe.php opts the phone out via BDApps
  /// server-side and, only once that succeeds, deletes the user row. We just
  /// clear the local session afterward.
  Future<void> unsubscribe(String phone) async {
    final token = _token;
    if (token == null) throw Exception('Not signed in');
    await _post('medremind_unsubscribe.php', {'phone': phone, 'token': token});
    await _clearSession();
  }

  Future<AppUser?> fetchProfile(String phone) async {
    final token = _token;
    if (token == null) return null;
    try {
      final map =
          await _post('medremind_profile.php', {'phone': phone, 'token': token});
      return _userFromMap(map);
    } catch (_) {
      return null;
    }
  }

  AppUser _userFromMap(Map<String, dynamic> map) => AppUser(
        phone: map['phone'] as String,
        name: (map['name'] ?? '').toString(),
        subscriptionStatus: map['subscriptionStatus'] == true,
        subscriptionExpiry: DateTime.tryParse(
            (map['subscriptionExpiry'] ?? '').toString()),
      );

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
      throw Exception((map['error'] ?? 'Request failed (${response.statusCode})')
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
