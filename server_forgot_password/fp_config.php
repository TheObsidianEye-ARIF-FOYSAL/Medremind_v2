<?php

date_default_timezone_set('Asia/Dhaka');

// ── IMPORTANT ────────────────────────────────────────────────────────────────
// This folder is deployed separately from server/, but it MUST read/write the
// exact same medremind_users.db that server/medremind_db.php uses — otherwise
// a password reset here won't affect the account the app actually logs into.
//
// Default assumes this folder and server/ are deployed as sibling folders on
// the host, mirroring this repo's local layout:
//   /ARIF(MRe)/                <- server/ contents (medremind_db.php etc.)
//   /ARIF(MRe)-forgot-password/ <- this folder's contents
// If your host layout differs, change MEDREMIND_DB_PATH below to the absolute
// path of the real medremind_users.db file.
const MEDREMIND_DB_PATH = __DIR__ . '/../ARIF(MRe)/medremind_users.db';

// Same BDApps credentials used across server/*.php.
const BDAPPS_APP_ID = 'APP_128956';
const BDAPPS_APP_PASSWORD = 'REDACTED_BDAPPS_PASSWORD';

function fp_db(): PDO {
    if (!file_exists(MEDREMIND_DB_PATH)) {
        fp_send_json([
            'error' => 'User database not found at ' . MEDREMIND_DB_PATH .
                '. Fix MEDREMIND_DB_PATH in fp_config.php to point at the real medremind_users.db.',
        ], 500);
    }
    $pdo = new PDO('sqlite:' . MEDREMIND_DB_PATH);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    return $pdo;
}

// Mirrors medremind_normalize_phone in server/medremind_db.php so lookups
// against the shared users table use the same phone format.
function fp_normalize_phone(string $phone): string {
    $digits = preg_replace('/\D/', '', $phone) ?? '';
    if (strpos($digits, '880') === 0 && strlen($digits) > 10) {
        return substr($digits, 3);
    }
    if (strpos($digits, '88') === 0 && strlen($digits) > 11) {
        return substr($digits, 2);
    }
    return $digits;
}

function fp_json_input(): array {
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);
    if (is_array($data)) return $data;
    return $_POST;
}

function fp_send_json($data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function fp_cors(): void {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}
