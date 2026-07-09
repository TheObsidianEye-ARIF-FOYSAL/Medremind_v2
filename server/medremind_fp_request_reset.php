<?php

require __DIR__ . '/medremind_db.php';
medremind_cors();

// Step 1 of forgot-password: phone must already be registered, then we ask
// BDApps to send an OTP (same request shape as medremind_send_otp.php). The
// client holds onto the returned referenceNo and sends it back, along with
// the OTP and new password, to medremind_fp_reset_password.php.

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

$requestData = [
    'applicationId' => 'APP_138840',
    'password' => 'REDACTED_BDAPPS_API_KEY',
    'subscriberId' => 'tel:88' . $phone,
    'applicationHash' => 'MedRee',
    'applicationMetaData' => [
        'client' => 'MOBILEAPP',
        'device' => 'Android',
        'os' => 'android',
        'appCode' => 'MedRee',
    ],
];
$requestJson = json_encode($requestData);

$ch = curl_init('https://developer.bdapps.com/subscription/otp/request');
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
    medremind_send_json(['error' => 'OTP request failed: ' . $curlError], 502);
}

$response = json_decode($responseJson, true);
$referenceNo = is_array($response) ? ($response['referenceNo'] ?? null) : null;

// TEMP DEBUG: log the raw BDApps response so we can see exactly what comes
// back for an already-subscribed number. Remove this file_put_contents once
// the "already registered" issue is diagnosed.
file_put_contents(__DIR__ . '/fp_debug.log', date('Y-m-d H:i:s') . ' phone=' . $phone . ' raw=' . $responseJson . "\n", FILE_APPEND);

if (!$referenceNo) {
    $detail = is_array($response) ? ($response['statusDetail'] ?? 'Unable to request OTP') : 'Unable to request OTP';
    medremind_send_json(['error' => $detail], 502);
}

medremind_send_json(['referenceNo' => $referenceNo]);
