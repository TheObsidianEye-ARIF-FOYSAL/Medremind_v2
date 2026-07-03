class AppUser {
  final String phone;
  final String name;
  final bool subscriptionStatus;
  final DateTime? subscriptionExpiry;

  const AppUser({
    required this.phone,
    required this.name,
    required this.subscriptionStatus,
    this.subscriptionExpiry,
  });

  bool get isSubscribed =>
      subscriptionStatus &&
      (subscriptionExpiry == null ||
          subscriptionExpiry!.isAfter(DateTime.now()));
}
