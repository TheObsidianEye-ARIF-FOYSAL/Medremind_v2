import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String phone;
  final String name;
  final String subscriptionStatus;
  final DateTime? subscriptionExpiry;

  const AppUser({
    required this.phone,
    required this.name,
    required this.subscriptionStatus,
    this.subscriptionExpiry,
  });

  bool get isSubscribed =>
      subscriptionStatus.toLowerCase() == 'active' &&
      (subscriptionExpiry == null ||
          subscriptionExpiry!.isAfter(DateTime.now()));

  factory AppUser.fromFirestore(String phone, Map<String, dynamic> data) {
    final expiry = data['subscriptionExpiry'];
    return AppUser(
      phone: phone,
      name: (data['name'] ?? '').toString(),
      subscriptionStatus: (data['subscriptionStatus'] ?? 'inactive').toString(),
      subscriptionExpiry: expiry is Timestamp ? expiry.toDate() : null,
    );
  }
}
