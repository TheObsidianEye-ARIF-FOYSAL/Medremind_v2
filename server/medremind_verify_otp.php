<?php

// MedRemind-specific OTP verify, using MedRee's own BDApps credentials
// (APP_138840). Mirrors verify_otp.php's shape but kept separate so the
// shared script (used by other apps) is untouched.

$user_otp = $_POST['Otp'] ?? '';
$referenceNo = $_POST['referenceNo'] ?? '';

$requestData = array(
    "applicationId" => "APP_138840",
    "password" => "REDACTED_BDAPPS_API_KEY",
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
if ($responseJson === false) {
    echo "cURL error: " . curl_error($ch);
} else {
    $response = json_decode($responseJson, true);
    if ($response === null) {
        echo "Invalid JSON in response: " . $responseJson;
    } else {
        $subscriptionStatus = array('subscriptionStatus' => $response["subscriptionStatus"] ?? null);
        echo json_encode($subscriptionStatus);
    }
}

curl_close($ch);

?>
