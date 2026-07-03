import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/app_user.dart';

/// Phone+password identity backed by Cloud Firestore, with password
/// hashing/verification done server-side in Cloud Functions (functions/index.js).
/// Firebase Auth is used only to hold the resulting session (custom token
/// signed in with uid == phone) — the password itself never touches
/// FirebaseAuth's own email/password provider.
class UserAuthService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<bool> checkPhoneExists(String phone) async {
    final result =
        await _functions.httpsCallable('checkPhoneExists').call({'phone': phone});
    return result.data['exists'] == true;
  }

  Future<void> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    final result = await _functions.httpsCallable('registerUser').call({
      'phone': phone,
      'name': name,
      'password': password,
    });
    await _auth.signInWithCustomToken(result.data['token'] as String);
  }

  Future<void> login({required String phone, required String password}) async {
    final result = await _functions.httpsCallable('loginUser').call({
      'phone': phone,
      'password': password,
    });
    await _auth.signInWithCustomToken(result.data['token'] as String);
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> fetchProfile(String phone) async {
    final doc = await _firestore.collection('users').doc(phone).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(phone, doc.data()!);
  }

  String mapError(Object e) {
    if (e is FirebaseFunctionsException) return e.message ?? e.code;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
