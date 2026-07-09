<?php

// MedRemind-specific OTP request, using MedRee's own BDApps credentials
// (APP_138840). Mirrors send_otp.php's shape but kept separate so the
// shared script (used by other apps) is untouched.

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
if ($responseJson === false) {
    echo "cURL error: " . curl_error($ch);
} else {
    $response = json_decode($responseJson, true);
    if ($response === null) {
        echo "Invalid JSON in response: " . $responseJson;
    } else {
        $referenceNo = array('referenceNo' => $response["referenceNo"] ?? null);
        echo json_encode($referenceNo);
    }
}

curl_close($ch);

?>
