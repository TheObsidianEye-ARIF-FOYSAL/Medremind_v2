<?php

// MedRemind-specific OTP request. Uses the same shared BDApps credentials as
// the other *.php scripts (and as VenueLock/BMI Calculator's server code) —
// APP_138840 (MedRee's own newly-approved app) is only cleared for testing
// with BDApps' whitelisted numbers, so it rejects everything else; the
// shared APP_128956 app is already in production and works for any number.
// Kept as a separate file (not send_otp.php) only so the shared script used
// by other apps is untouched.

$user_mobile = $_POST['user_mobile'] ?? '';
$user_mobile = 'tel:88' . $user_mobile;

$requestData = array(
    "applicationId" => "APP_128956",
    "password" => "REDACTED_BDAPPS_PASSWORD",
    "subscriberId" => "$user_mobile",
    "applicationHash" => "BMI Calculator",
    "applicationMetaData" => array(
        "client" => "MOBILEAPP",
        "device" => "Samsung S10",
        "os" => "android 8",
        "appCode" => "https://play.google.com/store/apps/details?id=lk.dialog.megarunlor"
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
