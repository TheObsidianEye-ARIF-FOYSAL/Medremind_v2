<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Used both to restore a session on app start and to refresh
// subscriptionStatus/subscriptionExpiry on demand.
$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$token = (string) ($input['token'] ?? '');

$db = medremind_db();
$user = medremind_require_session($db, $phone, $token);

medremind_send_json(medremind_user_payload($user));
