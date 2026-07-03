import '../../../core/models/user_profile.dart';

// TODO Phase 7: implemented by BdAppsOtpService and FirebaseAuthService
abstract class AuthService {
  Stream<UserProfile?> get authStateChanges;

  Future<UserProfile> signInWithPhone({
    required String phoneNumber,
    required String otp,
  });

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signInWithGoogle();

  Future<void> signOut();

  Future<void> unsubscribeOtp(); // clears OTP session / opts out
}
