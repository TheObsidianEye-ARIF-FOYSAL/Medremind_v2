<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Step 2 of forgot-password: verify the OTP we texted ourselves in
// medremind_fp_request_reset.php (matching reset_reference + reset_code_hash
// + not-yet-expired) and, only if valid, overwrite password_hash. Also
// clears the existing session_token so any device signed in with the old
// password is forced to log in again.

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
$stmt = $db->prepare('SELECT * FROM users WHERE phone = ?');
$stmt->execute([$phone]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
    medremind_send_json(['error' => 'No account found for this phone number'], 404);
}

$storedReference = (string) ($user['reset_reference'] ?? '');
$storedHash = (string) ($user['reset_code_hash'] ?? '');
$expiresAt = (string) ($user['reset_expires_at'] ?? '');

$expired = $expiresAt === '' || new DateTime($expiresAt) < new DateTime('now', new DateTimeZone('UTC'));

if ($storedReference === '' || !hash_equals($storedReference, $referenceNo) || $expired || $storedHash === '' || !password_verify($otp, $storedHash)) {
    medremind_send_json(['error' => 'Invalid or expired OTP'], 401);
}

$passwordHash = password_hash($newPassword, PASSWORD_BCRYPT);
$update = $db->prepare(
    'UPDATE users SET password_hash = ?, session_token = NULL, session_created_at = NULL, reset_reference = NULL, reset_code_hash = NULL, reset_expires_at = NULL WHERE phone = ?'
);
$update->execute([$passwordHash, $phone]);

medremind_send_json(['success' => true]);
