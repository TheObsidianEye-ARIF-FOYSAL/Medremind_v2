<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}

$db = medremind_db();
$stmt = $db->prepare('SELECT 1 FROM users WHERE phone = ?');
$stmt->execute([$phone]);

medremind_send_json(['exists' => (bool) $stmt->fetchColumn()]);
