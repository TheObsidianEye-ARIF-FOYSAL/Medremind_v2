import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../services/user_auth_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class UserAuthState {
  final AppUser? user;
  final bool isLoading;
  final String? error;

  const UserAuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  UserAuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) =>
      UserAuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class UserAuthNotifier extends StateNotifier<UserAuthState> {
  final UserAuthService _service;

  /// main.dart awaits this before deciding whether to show the login screen,
  /// so a persisted session token isn't mistaken for "logged out".
  late final Future<void> ready;

  UserAuthNotifier(this._service) : super(const UserAuthState()) {
    ready = _restoreSession();
  }

  Future<void> _restoreSession() async {
    final phone = await _service.restoreSession();
    if (phone == null) return;
    final profile = await _service.fetchProfile(phone);
    if (profile != null) {
      state = state.copyWith(user: profile);
    } else {
      await _service.signOut(); // stale/invalid token
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final exists = await _service.checkPhoneExists(phone);
      state = state.copyWith(isLoading: false);
      return exists;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      rethrow;
    }
  }

  Future<bool> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user =
          await _service.register(phone: phone, name: name, password: password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      return false;
    }
  }

  Future<bool> login({required String phone, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.login(phone: phone, password: password);
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      return false;
    }
  }

  Future<void> refreshProfile() async {
    final phone = state.user?.phone;
    if (phone == null) return;
    final profile = await _service.fetchProfile(phone);
    if (profile != null) state = state.copyWith(user: profile);
  }

  Future<void> logout() async {
    await _service.signOut();
    state = state.copyWith(clearUser: true);
  }

  Future<bool> unsubscribe() async {
    final phone = state.user?.phone;
    if (phone == null) return false;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.unsubscribe(phone);
      state = const UserAuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _service.mapError(e));
      return false;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final _userAuthServiceProvider = Provider((_) => UserAuthService());

final userAuthProvider = StateNotifierProvider<UserAuthNotifier, UserAuthState>(
  (ref) => UserAuthNotifier(ref.watch(_userAuthServiceProvider)),
);
