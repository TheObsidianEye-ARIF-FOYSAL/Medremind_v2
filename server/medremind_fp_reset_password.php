<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Step 2 of forgot-password: verify the OTP (via BDApps, same acceptance
// rules as medremind_verify_otp.php) and, only if it's valid, overwrite the
// account's password_hash. Also clears the existing session_token so any
// device signed in with the old password is forced to log in again.

$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$referenceNo = trim((string) ($input['referenceNo'] ?? ''));
$otp = trim((string) ($input['otp'] ?? ''));
$newPassword = (string) ($input['newPassword'] ?? '');

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}
if ($referenceNo === '' || $otp === '') {
    medremind_send_json(['error' => 'OTP reference is missing, request a new OTP'], 400);
}
if (strlen($newPassword) < 6) {
    medremind_send_json(['error' => 'Password must be at least 6 characters'], 400);
}

$db = medremind_db();
$stmt = $db->prepare('SELECT 1 FROM users WHERE phone = ?');
$stmt->execute([$phone]);
if (!$stmt->fetchColumn()) {
    medremind_send_json(['error' => 'No account found for this phone number'], 404);
}

$requestData = [
    'applicationId' => 'APP_138840',
    'password' => 'REDACTED_BDAPPS_API_KEY',
    'referenceNo' => $referenceNo,
    'otp' => $otp,
];
$requestJson = json_encode($requestData);

$ch = curl_init('https://developer.bdapps.com/subscription/otp/verify');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Content-Length: ' . strlen($requestJson),
]);
$responseJson = curl_exec($ch);
$curlError = curl_error($ch);
curl_close($ch);

if ($responseJson === false) {
    medremind_send_json(['error' => 'OTP verification failed: ' . $curlError], 502);
}

$response = json_decode($responseJson, true);
$status = strtoupper(str_replace('_', ' ', trim((string) (
    is_array($response) ? ($response['subscriptionStatus'] ?? '') : ''
))));
$statusCode = is_array($response) ? ($response['statusCode'] ?? null) : null;

$accepted = [
    'REGISTERED', 'SUBSCRIBED', 'ACTIVE', 'S1000',
    'INITIAL CHARGING PENDING', 'PENDING INITIAL CHARGING',
];
$otpVerified = in_array($status, $accepted, true) || $statusCode === 'S1000';

if (!$otpVerified) {
    medremind_send_json(['error' => 'Invalid or expired OTP'], 401);
}

$passwordHash = password_hash($newPassword, PASSWORD_BCRYPT);
$update = $db->prepare('UPDATE users SET password_hash = ?, session_token = NULL, session_created_at = NULL WHERE phone = ?');
$update->execute([$passwordHash, $phone]);

medremind_send_json(['success' => true]);
