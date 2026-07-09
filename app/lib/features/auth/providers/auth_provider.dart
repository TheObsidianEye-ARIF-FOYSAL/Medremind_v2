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

  /// Returns true if an OTP was sent and the caller should show the OTP
  /// screen; false if BDApps says the number is already subscribed and
  /// there's nothing to verify (see [AuthService.sendOtp]). Returns null on
  /// error (check [AuthState.error]).
  Future<bool?> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final otpRequired = await _service.sendOtp(phone);
      state = state.copyWith(isLoading: false, phone: phone);
      return otpRequired;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      return null;
    }
  }

  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ok = await _service.verifyOtp(state.phone!, code);
      if (ok) {
        state = state.copyWith(isLoading: false);
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
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _authServiceProvider = Provider((_) => AuthService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(_authServiceProvider)),
);
