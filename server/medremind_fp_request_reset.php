<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Step 1 of forgot-password.
//
// NOTE: this does NOT use BDApps' subscription/otp/request endpoint (that's
// what medremind_send_otp.php uses for new registrations). That endpoint
// refuses to issue an OTP for a subscriberId that's already subscribed
// (statusCode E1351) — and every user who can hit "forgot password" is, by
// definition, already registered/subscribed. So instead we mint our own
// 6-digit code, store its hash + an expiry against the account, and text it
// via BDApps' sms/send API.

$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}

$db = medremind_db();
$stmt = $db->prepare('SELECT 1 FROM users WHERE phone = ?');
$stmt->execute([$phone]);
if (!$stmt->fetchColumn()) {
    medremind_send_json(['error' => 'No account found for this phone number'], 404);
}

$referenceNo = bin2hex(random_bytes(8));
$code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
$codeHash = password_hash($code, PASSWORD_BCRYPT);
$expiresAt = (new DateTime('+10 minutes', new DateTimeZone('UTC')))->format(DateTime::ATOM);

$update = $db->prepare(
    'UPDATE users SET reset_reference = ?, reset_code_hash = ?, reset_expires_at = ? WHERE phone = ?'
);
$update->execute([$referenceNo, $codeHash, $expiresAt, $phone]);

$requestData = [
    'applicationId' => 'APP_138840',
    'password' => 'REDACTED_BDAPPS_API_KEY',
    'message' => "Your MedRee password reset code is $code. It expires in 10 minutes.",
    'destinationAddresses' => ['tel:88' . $phone],
];
$requestJson = json_encode($requestData);

$ch = curl_init('https://developer.bdapps.com/sms/send');
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

file_put_contents(__DIR__ . '/fp_debug.log', date('Y-m-d H:i:s') . ' phone=' . $phone . ' sms_raw=' . var_export($responseJson, true) . "\n", FILE_APPEND);

if ($responseJson === false) {
    medremind_send_json(['error' => 'SMS send failed: ' . $curlError], 502);
}

medremind_send_json(['referenceNo' => $referenceNo]);
