import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────
//
// This notifier only wraps the BDApps OTP send/verify HTTP calls used as the
// phone-verification step during registration (see RegisterDetailsScreen and
// OtpScreen). It intentionally holds no persisted session — identity and
// login state live in [userAuthProvider] (Firestore-backed phone+password).

class AuthState {
  final String? phone;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.phone,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? phone,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState());

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.sendOtp(phone);
      state = state.copyWith(isLoading: false, phone: phone);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _service.verifyOtp(state.phone!, code);
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bdapps_phone', state.phone!);
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        return true;
      }
      state = state.copyWith(isLoading: false, error: 'Invalid OTP');
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> unsubscribe() async {
    state = state.copyWith(isLoading: true, error: null);
    final phone = state.phone;
    if (phone == null || phone.isEmpty) {
      state = state.copyWith(
          isLoading: false, error: 'No phone found. Please login again.');
      return false;
    }
    try {
      final ok = await _service.unsubscribe(phone);
      if (ok) {
        await _clearSession();
        return true;
      }
      state = state.copyWith(
          isLoading: false, error: 'Unsubscribe failed. Please try again.');
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async => _clearSession();

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bdapps_phone');
    state = const AuthState();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _authServiceProvider = Provider((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(_authServiceProvider)),
);
