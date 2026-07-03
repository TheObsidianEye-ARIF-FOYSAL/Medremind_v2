import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── User name provider ─────────────────────────────────────────────────────────

const _kUserName = 'user_name_v2';

final userNameProvider =
    StateNotifierProvider<_UserNameNotifier, String>(_UserNameNotifier.new);

class _UserNameNotifier extends StateNotifier<String> {
  _UserNameNotifier(Ref _) : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_kUserName) ?? '';
  }

  Future<void> set(String name) async {
    state = name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, state);
  }
}
