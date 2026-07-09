<?php

// MedRemind-specific OTP request, using MedRee's own BDApps credentials
// (APP_138840). This app is currently approved for TESTING ONLY — BDApps
// will only issue OTPs for their whitelisted test numbers on this app id
// until "Active Production" is requested. Kept separate from send_otp.php
// so the shared script (used by other apps, e.g. VenueLock/BMI Calculator
// under APP_128956) is untouched.

$user_mobile = $_POST['user_mobile'] ?? '';
$user_mobile = 'tel:88' . $user_mobile;

$requestData = array(
    "applicationId" => "APP_138840",
    "password" => "REDACTED_BDAPPS_API_KEY",
    "subscriberId" => "$user_mobile",
    "applicationHash" => "MedRee",
    "applicationMetaData" => array(
        "client" => "MOBILEAPP",
        "device" => "Android",
        "os" => "android",
        "appCode" => "MedRee"
    )
);

$requestJson = json_encode($requestData);

$url = "https://developer.bdapps.com/subscription/otp/request";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $requestJson);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    "Content-Type: application/json",
    "Content-Length: " . strlen($requestJson)
));

$responseJson = curl_exec($ch);

// TEMP DEBUG: log the raw BDApps response so we can see the real reason OTP
// requests are failing. Remove this file_put_contents once diagnosed.
file_put_contents(__DIR__ . '/send_otp_debug.log', date('Y-m-d H:i:s') . ' mobile=' . $user_mobile . ' raw=' . var_export($responseJson, true) . "\n", FILE_APPEND);

if ($responseJson === false) {
    header('Content-Type: application/json');
    echo json_encode(['statusCode' => 'E1001', 'statusDetail' => 'cURL error: ' . curl_error($ch)]);
} else {
    $response = json_decode($responseJson, true);
    header('Content-Type: application/json');
    if ($response === null) {
        echo json_encode(['statusCode' => 'E1002', 'statusDetail' => 'Invalid JSON in response: ' . $responseJson]);
    } else {
        echo json_encode([
            'referenceNo' => $response['referenceNo'] ?? null,
            'statusCode' => $response['statusCode'] ?? null,
            'statusDetail' => $response['statusDetail'] ?? null,
        ]);
    }
}

curl_close($ch);

?>
