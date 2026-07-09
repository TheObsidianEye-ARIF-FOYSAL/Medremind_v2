<?php

require __DIR__ . '/bdapps_config.php';

require __DIR__ . '/medremind_db.php';

// Manual/admin testing helper — mirrors the commented-out test snippet in
// unsubscribe.php ("$test_number = ...; $request = ['subscriberId' => ...]").
// Set $test_number below and hit this file directly in a browser or via
// curl to force an unsubscribe (BDApps opt-out + delete the DB row) for
// that phone number, bypassing the session-token check that
// medremind_unsubscribe.php normally requires.
//
// Not linked from the app. Do not leave a real number set here on a public
// host — remove/comment it out again once you're done testing.

$test_number = ''; // e.g. '01897776680' or '8801897776680'

$phone = medremind_normalize_phone(
    $test_number !== '' ? $test_number : (string) ($_GET['phone'] ?? $_POST['phone'] ?? '')
);

if (strlen($phone) !== 11) {
    medremind_send_json(['error' => 'Set $test_number above or pass ?phone=01XXXXXXXXX'], 400);
}

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
// Same "already unregistered" quirk handled in medremind_unsubscribe.php.
$alreadyUnregistered = stripos($statusDetail, 'Already UnRegistered') !== false;

$db = medremind_db();

if ($statusCode === 'S1000' || $subStatus === 'UNREGISTERED' || $alreadyUnregistered) {
    $delete = $db->prepare('DELETE FROM users WHERE phone = ?');
    $delete->execute([$phone]);
    medremind_send_json([
        'success' => true,
        'phone' => $phone,
        'bdappsResponse' => $response,
    ]);
}

medremind_send_json([
    'success' => false,
    'phone' => $phone,
    'bdappsResponse' => $response,
], 502);
