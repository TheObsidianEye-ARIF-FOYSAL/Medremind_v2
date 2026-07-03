import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/forgot_password_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class ForgotPasswordState {
  final String? phone;
  final String? referenceNo;
  final bool isLoading;
  final String? error;

  const ForgotPasswordState({
    this.phone,
    this.referenceNo,
    this.isLoading = false,
    this.error,
  });

  ForgotPasswordState copyWith({
    String? phone,
    String? referenceNo,
    bool? isLoading,
    String? error,
  }) =>
      ForgotPasswordState(
        phone: phone ?? this.phone,
        referenceNo: referenceNo ?? this.referenceNo,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ForgotPasswordNotifier extends StateNotifier<ForgotPasswordState> {
  final ForgotPasswordService _service;

  ForgotPasswordNotifier(this._service) : super(const ForgotPasswordState());

  Future<bool> requestReset(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final referenceNo = await _service.requestReset(phone);
      state = state.copyWith(
          isLoading: false, phone: phone, referenceNo: referenceNo);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String otp,
    required String newPassword,
  }) async {
    final phone = state.phone;
    final referenceNo = state.referenceNo;
    if (phone == null || referenceNo == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.resetPassword(
        phone: phone,
        referenceNo: referenceNo,
        otp: otp,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _forgotPasswordServiceProvider = Provider((_) => ForgotPasswordService());

final forgotPasswordProvider =
    StateNotifierProvider<ForgotPasswordNotifier, ForgotPasswordState>(
  (ref) => ForgotPasswordNotifier(ref.watch(_forgotPasswordServiceProvider)),
);
