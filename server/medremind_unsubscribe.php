<?php

require __DIR__ . '/bdapps_config.php';

require __DIR__ . '/medremind_db.php';
medremind_cors();

// P4 Unsubscribe: opt the phone out via BDApps, and only on BDApps success
// delete the local user row + its session. Uses the same BDApps opt-out
// request shape as unsubscribe.php, kept separate so that generic script
// (shared by other apps) is untouched.
$input = medremind_json_input();
$phone = medremind_normalize_phone((string) ($input['phone'] ?? ''));
$token = (string) ($input['token'] ?? '');

$db = medremind_db();
medremind_require_session($db, $phone, $token);

$appid = BDAPPS_APP_ID;
$apppassword = BDAPPS_APP_PASSWORD;
$subscriberId = 'tel:88' . $phone;

$requestData = [
    'applicationId' => $appid,
    'password' => $apppassword,
    'version' => '1.0',
    'action' => '0', // 0 = Unsubscribe (opt-out)
    'subscriberId' => $subscriberId,
];
$requestJson = json_encode($requestData);

$ch = curl_init('https://developer.bdapps.com/subscription/send');
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
    medremind_send_json(['error' => 'BDApps request failed: ' . $curlError], 502);
}

$response = json_decode($responseJson, true);
$statusCode = is_array($response) ? ($response['statusCode'] ?? null) : null;
$subStatus = is_array($response) ? strtoupper((string) ($response['subscriptionStatus'] ?? '')) : '';
$statusDetail = is_array($response) ? (string) ($response['statusDetail'] ?? '') : '';
// BDApps returns this ambiguous combined message ("Format of the address is
// invalid or User Already UnRegistered") when the subscriberId is already
// unregistered — treat that as success too, since the end state we want
// (unregistered + local row gone) is already true.
$alreadyUnregistered = stripos($statusDetail, 'Already UnRegistered') !== false;

if ($statusCode === 'S1000' || $subStatus === 'UNREGISTERED' || $alreadyUnregistered) {
    $delete = $db->prepare('DELETE FROM users WHERE phone = ?');
    $delete->execute([$phone]);
    medremind_send_json(['success' => true]);
}

medremind_send_json([
    'error' => (is_array($response) ? ($response['statusDetail'] ?? null) : null) ?? 'Unsubscribe failed',
], 502);
