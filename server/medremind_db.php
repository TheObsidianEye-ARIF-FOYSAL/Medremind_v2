<?php

date_default_timezone_set('Asia/Dhaka');

// Shared SQLite storage + helpers for the MedRemind app's phone+password
// auth (medremind_check_phone.php, medremind_register.php, medremind_login.php,
// medremind_profile.php, medremind_unsubscribe.php). Kept separate from the
// other *.php files in this folder so other apps using send_otp.php /
// verify_otp.php / unsubscribe.php are unaffected.

function medremind_db(): PDO {
    $dbPath = __DIR__ . '/medremind_users.db';
    $pdo = new PDO('sqlite:' . $dbPath);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->exec("CREATE TABLE IF NOT EXISTS users (
        phone TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        subscription_status INTEGER NOT NULL DEFAULT 1,
        subscription_expiry TEXT,
        created_at TEXT NOT NULL,
        session_token TEXT,
        session_created_at TEXT
    )");
    return $pdo;
}

// Mirrors AuthService._normalize in lib/features/auth/services/auth_service.dart
// so the phone primary key is consistent between the BDApps OTP step and this DB.
function medremind_normalize_phone(string $phone): string {
    $digits = preg_replace('/\D/', '', $phone) ?? '';
    if (strpos($digits, '880') === 0 && strlen($digits) > 10) {
        return substr($digits, 3);
    }
    if (strpos($digits, '88') === 0 && strlen($digits) > 11) {
        return substr($digits, 2);
    }
    return $digits;
}

function medremind_json_input(): array {
    $body = file_get_contents('php://input');
    $data = json_decode($body, true);
    if (is_array($data)) return $data;
    return $_POST;
}

function medremind_send_json($data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json');
    echo json_encode($data);
    exit;
}

function medremind_cors(): void {
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type');
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

function medremind_require_session(PDO $db, string $phone, string $token): array {
    if ($phone === '' || $token === '') {
        medremind_send_json(['error' => 'Invalid session'], 401);
    }
    $stmt = $db->prepare('SELECT * FROM users WHERE phone = ?');
    $stmt->execute([$phone]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$user || !is_string($user['session_token']) || !hash_equals($user['session_token'], $token)) {
        medremind_send_json(['error' => 'Invalid session'], 401);
    }
    return $user;
}

function medremind_user_payload(array $user): array {
    return [
        'phone' => $user['phone'],
        'name' => $user['name'],
        'subscriptionStatus' => (bool) $user['subscription_status'],
        'subscriptionExpiry' => $user['subscription_expiry'],
    ];
}
