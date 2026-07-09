<?php

require __DIR__ . '/bdapps_config.php';

// MedRemind-specific OTP verify, using MedRee's own BDApps credentials
// (APP_138840). See medremind_send_otp.php's comment — testing-only app id.

$user_otp = $_POST['Otp'] ?? '';
$referenceNo = $_POST['referenceNo'] ?? '';

$requestData = array(
    "applicationId" => BDAPPS_APP_ID,
    "password" => BDAPPS_APP_PASSWORD,
    "referenceNo" => "$referenceNo",
    "otp" => "$user_otp"
);

$requestJson = json_encode($requestData);

$url = "https://developer.bdapps.com/subscription/otp/verify";
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

// TEMP DEBUG: same as medremind_send_otp.php — remove once diagnosed.
file_put_contents(__DIR__ . '/verify_otp_debug.log', date('Y-m-d H:i:s') . ' ref=' . $referenceNo . ' raw=' . var_export($responseJson, true) . "\n", FILE_APPEND);

header('Content-Type: application/json');
if ($responseJson === false) {
    echo json_encode(['statusCode' => 'E1001', 'statusDetail' => 'cURL error: ' . curl_error($ch)]);
} else {
    $response = json_decode($responseJson, true);
    if ($response === null) {
        echo json_encode(['statusCode' => 'E1002', 'statusDetail' => 'Invalid JSON in response: ' . $responseJson]);
    } else {
        echo json_encode([
            'subscriptionStatus' => $response['subscriptionStatus'] ?? null,
            'statusCode' => $response['statusCode'] ?? null,
            'statusDetail' => $response['statusDetail'] ?? null,
        ]);
    }
}

curl_close($ch);

?>
