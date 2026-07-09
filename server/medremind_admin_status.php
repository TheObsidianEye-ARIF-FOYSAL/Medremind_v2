<?php

require __DIR__ . '/bdapps_config.php';

// Manual/admin testing helper — checks a subscriberId's actual BDApps
// subscription status via the (unambiguous) getstatus endpoint. Useful for
// resolving the ambiguous "Format of the address is invalid Or User Already
// UnRegistered" message that /subscription/send returns on unsubscribe,
// which can mean either outcome.
//
// Usage: hit this file with ?phone=01XXXXXXXXX
// Not linked from the app.

$phone = preg_replace('/\D/', '', (string) ($_GET['phone'] ?? $_POST['phone'] ?? ''));
if (strpos($phone, '880') === 0 && strlen($phone) > 10) {
    $phone = substr($phone, 3);
} elseif (strpos($phone, '88') === 0 && strlen($phone) > 11) {
    $phone = substr($phone, 2);
}

if (strlen($phone) !== 11) {
    header('Content-Type: application/json');
    echo json_encode(['error' => 'Pass ?phone=01XXXXXXXXX']);
    exit;
}

$subscriberId = 'tel:88' . $phone;

$requestData = [
    'applicationId' => BDAPPS_APP_ID,
    'password' => BDAPPS_APP_PASSWORD,
    'subscriberId' => $subscriberId,
];
$requestJson = json_encode($requestData);

$ch = curl_init('https://developer.bdapps.com/subscription/getstatus');
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

header('Content-Type: application/json');
if ($responseJson === false) {
    echo json_encode(['error' => 'BDApps request failed: ' . $curlError]);
    exit;
}

echo json_encode([
    'phone' => $phone,
    'subscriberId' => $subscriberId,
    'bdappsResponse' => json_decode($responseJson, true) ?? $responseJson,
]);
