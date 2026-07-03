<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$password = (string) ($input['password'] ?? '');

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}

$db = medremind_db();
$stmt = $db->prepare('SELECT * FROM users WHERE phone = ?');
$stmt->execute([$phone]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    medremind_send_json(['error' => 'No account found for this phone number'], 404);
}
if (!password_verify($password, $user['password_hash'])) {
    medremind_send_json(['error' => 'Incorrect password'], 401);
}

$token = bin2hex(random_bytes(32));
$now = (new DateTime('now', new DateTimeZone('UTC')))->format(DateTime::ATOM);
$update = $db->prepare('UPDATE users SET session_token = ?, session_created_at = ? WHERE phone = ?');
$update->execute([$token, $now, $phone]);

$user['session_token'] = $token;
medremind_send_json(medremind_user_payload($user) + ['token' => $token]);
