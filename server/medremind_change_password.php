<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Change password for an already-logged-in user (knows their current
// password) — different from the medremind_unsubscribe.php family and from
// medremind_fp_request_reset.php / medremind_fp_reset_password.php's
// OTP-based reset (P5), which is for a user who forgot their password and
// isn't logged in.
$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$token = (string) ($input['token'] ?? '');
$currentPassword = (string) ($input['currentPassword'] ?? '');
$newPassword = (string) ($input['newPassword'] ?? '');

$db = medremind_db();
$user = medremind_require_session($db, $phone, $token);

if (!password_verify($currentPassword, $user['password_hash'])) {
    medremind_send_json(['error' => 'Current password is incorrect'], 401);
}
if (strlen($newPassword) < 6) {
    medremind_send_json(['error' => 'New password must be at least 6 characters'], 400);
}

$passwordHash = password_hash($newPassword, PASSWORD_BCRYPT);
// Rotate the session token so the change also invalidates any other
// signed-in device/session, and return the new token to keep this one alive.
$newToken = bin2hex(random_bytes(32));
$now = (new DateTime('now', new DateTimeZone('UTC')))->format(DateTime::ATOM);

$update = $db->prepare(
    'UPDATE users SET password_hash = ?, session_token = ?, session_created_at = ? WHERE phone = ?'
);
$update->execute([$passwordHash, $newToken, $now, $phone]);

medremind_send_json(['success' => true, 'token' => $newToken]);
