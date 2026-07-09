<?php

require __DIR__ . '/bdapps_config.php';

// MedRemind-specific OTP request, using MedRee's own BDApps credentials
// (APP_138840). This app is currently approved for TESTING ONLY — BDApps
// will only issue OTPs for their whitelisted test numbers on this app id
// until "Active Production" is requested. Kept separate from send_otp.php
// so the shared script (used by other apps, e.g. VenueLock/BMI Calculator
// under APP_128956) is untouched.

$user_mobile = $_POST['user_mobile'] ?? '';
$user_mobile = 'tel:88' . $user_mobile;

$requestData = array(
    "applicationId" => BDAPPS_APP_ID,
    "password" => BDAPPS_APP_PASSWORD,
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

if ($responseJson === false) {
    header('Content-Type: application/json');
    echo json_encode(['statusCode' => 'E1001', 'statusDetail' => 'cURL error: ' . curl_error($ch)]);
} else {
    $response = json_decode($responseJson, true);
    header('Content-Type: application/json');
    if ($response === null) {
        echo json_encode(['statusCode' => 'E1002', 'statusDetail' => 'Invalid JSON in response: ' . $responseJson]);
    } else {
        $statusCode = $response['statusCode'] ?? null;
        // E1351 = subscriberId already subscribed to this application.
        // BDApps' whitelisted test numbers for APP_138840 are pre-subscribed,
        // so no OTP is ever issued for them — treat this as "already
        // verified" so registration can proceed without an OTP step.
        $alreadyRegistered = $statusCode === 'E1351';
        echo json_encode([
            'referenceNo' => $response['referenceNo'] ?? null,
            'statusCode' => $statusCode,
            'statusDetail' => $response['statusDetail'] ?? null,
            'alreadyRegistered' => $alreadyRegistered,
        ]);
    }
}

curl_close($ch);

?>
