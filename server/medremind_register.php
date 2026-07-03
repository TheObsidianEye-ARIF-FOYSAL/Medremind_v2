<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Called only after the client has already verified the BDApps OTP
// (see verify_otp.php) for this phone number.
$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$name = trim((string) ($input['name'] ?? ''));
$password = (string) ($input['password'] ?? '');

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}
if ($name === '') {
    medremind_send_json(['error' => 'Name is required'], 400);
}
if (strlen($password) < 6) {
    medremind_send_json(['error' => 'Password must be at least 6 characters'], 400);
}

$db = medremind_db();

$stmt = $db->prepare('SELECT 1 FROM users WHERE phone = ?');
$stmt->execute([$phone]);
if ($stmt->fetchColumn()) {
    medremind_send_json(['error' => 'This phone number is already registered'], 409);
}

$passwordHash = password_hash($password, PASSWORD_BCRYPT);
$now = new DateTime('now', new DateTimeZone('UTC'));
$createdAt = $now->format(DateTime::ATOM);
// BDApps charges this subscription daily (2 taka/day) with no renewal
// webhook currently wired up, so expiry tracks one day of confirmed
// charging rather than a fixed-term plan.
$expiry = (clone $now)->modify('+1 day')->format(DateTime::ATOM);
$token = bin2hex(random_bytes(32));

$insert = $db->prepare(
    'INSERT INTO users (phone, name, password_hash, subscription_status, subscription_expiry, created_at, session_token, session_created_at)
     VALUES (?, ?, ?, 1, ?, ?, ?, ?)'
);
$insert->execute([$phone, $name, $passwordHash, $expiry, $createdAt, $token, $createdAt]);

medremind_send_json([
    'phone' => $phone,
    'name' => $name,
    'subscriptionStatus' => true,
    'subscriptionExpiry' => $expiry,
    'token' => $token,
]);
