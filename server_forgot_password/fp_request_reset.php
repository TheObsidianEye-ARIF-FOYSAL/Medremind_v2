<?php

require __DIR__ . '/fp_config.php';
fp_cors();

// Step 1 of forgot-password: phone must already be registered, then we ask
// BDApps to send an OTP (same request shape as server/send_otp.php). The
// client holds onto the returned referenceNo and sends it back, along with
// the OTP and new password, to fp_reset_password.php.

$input = fp_json_input();
$phone = fp_normalize_phone((string) ($input['phone'] ?? ''));

if (strlen($phone) !== 11) {
    fp_send_json(['error' => 'Enter a valid 11-digit phone number'], 400);
}

$db = fp_db();
$stmt = $db->prepare('SELECT 1 FROM users WHERE phone = ?');
$stmt->execute([$phone]);
if (!$stmt->fetchColumn()) {
    fp_send_json(['error' => 'No account found for this phone number'], 404);
}

$requestData = [
    'applicationId' => BDAPPS_APP_ID,
    'password' => BDAPPS_APP_PASSWORD,
    'subscriberId' => 'tel:88' . $phone,
    'applicationHash' => 'BMI Calculator',
    'applicationMetaData' => [
        'client' => 'MOBILEAPP',
        'device' => 'Samsung S10',
        'os' => 'android 8',
        'appCode' => 'https://play.google.com/store/apps/details?id=lk.dialog.megarunlor',
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
    fp_send_json(['error' => 'OTP request failed: ' . $curlError], 502);
}

$response = json_decode($responseJson, true);
$referenceNo = is_array($response) ? ($response['referenceNo'] ?? null) : null;

if (!$referenceNo) {
    $detail = is_array($response) ? ($response['statusDetail'] ?? 'Unable to request OTP') : 'Unable to request OTP';
    fp_send_json(['error' => $detail], 502);
}

fp_send_json(['referenceNo' => $referenceNo]);
