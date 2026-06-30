import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages

import '../services/firebase_auth_service.dart';

// ── State ──────────────────────────────────────────────────────────────────────

class FirebaseAuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const FirebaseAuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  FirebaseAuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) =>
      FirebaseAuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FirebaseAuthNotifier extends StateNotifier<FirebaseAuthState> {
  final FirebaseAuthService _service;

  FirebaseAuthNotifier(this._service) : super(const FirebaseAuthState()) {
    final current = _service.currentUser;
    if (current != null) state = FirebaseAuthState(user: current);
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signInWithEmailPassword(email, password);
      state = FirebaseAuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
      return false;
    }
  }

  Future<bool> registerWithEmailPassword(
      String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user =
          await _service.registerWithEmailPassword(name, email, password);
      state = FirebaseAuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.signInWithGoogle();
      state = FirebaseAuthState(user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.sendPasswordReset(email.trim());
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const FirebaseAuthState();
  }

  // Returns true if delete succeeded.
  // Pass password for email users; null for Google users (re-auth via Google).
  Future<bool> deleteAccount({String? password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      if (_service.isGoogleUser) {
        await _service.reauthenticateWithGoogle();
      } else {
        if (password == null || password.isEmpty) {
          state = state.copyWith(isLoading: false, error: 'Password required');
          return false;
        }
        await _service.reauthenticateWithPassword(password);
      }
      await _service.deleteAccount();
      state = const FirebaseAuthState();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendly(e));
      return false;
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect password. Please try again.';
    }
    if (msg.contains('user-not-found')) return 'No account found with this email.';
    if (msg.contains('email-already-in-use')) {
      return 'Email already registered. Please login instead.';
    }
    if (msg.contains('weak-password')) return 'Password must be at least 6 characters.';
    if (msg.contains('invalid-email')) return 'Invalid email address.';
    if (msg.contains('network-request-failed')) return 'Network error. Check your connection.';
    if (msg.contains('cancelled')) return 'Sign-in cancelled.';
    return msg.replaceFirst('Exception: ', '').replaceFirst('[firebase_auth]', '').trim();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _firebaseAuthServiceProvider = Provider((_) => FirebaseAuthService());

final firebaseAuthProvider =
    StateNotifierProvider<FirebaseAuthNotifier, FirebaseAuthState>(
  (ref) => FirebaseAuthNotifier(ref.watch(_firebaseAuthServiceProvider)),
);
