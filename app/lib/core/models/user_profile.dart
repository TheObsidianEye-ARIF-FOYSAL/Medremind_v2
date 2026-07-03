enum AuthProvider { none, bdappsOtp, firebaseEmail, firebaseGoogle }

class UserProfile {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final AuthProvider authProvider;

  const UserProfile({
    required this.id,
    this.displayName = 'Guest',
    this.phoneNumber,
    this.email,
    this.authProvider = AuthProvider.none,
  });

  bool get isGuest => authProvider == AuthProvider.none;
}
