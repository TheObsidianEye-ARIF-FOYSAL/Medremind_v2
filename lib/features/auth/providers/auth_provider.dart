import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class AuthState {
  final bool isAuthenticated;
  final String? phone;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.phone,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? phone,
    bool? isLoading,
    String? error,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        phone: phone ?? this.phone,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AuthState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('bdapps_phone');
    if (phone != null) {
      state = state.copyWith(isAuthenticated: true, phone: phone);
    }
  }

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
