# API Usage Map

Every place the app or server makes a network API call, with exact file + line
number, so you can jump straight to it later. Two hops:

```
Flutter app (app/)  --HTTP-->  PHP server (server/)  --HTTP-->  BDApps API
```

Line numbers are as of this commit — if you edit these files, re-check them.

---

## 1. Flutter app → PHP server

### `app/lib/features/auth/services/auth_service.dart`
BDApps OTP calls, proxied through the server's `send_otp.php` / `verify_otp.php` / `unsubscribe.php`.

| Line | Call | Hits |
|---|---|---|
| 26 | `Uri.parse('$_baseUrl/send_otp.php')` | `server/send_otp.php` |
| 62 | `Uri.parse('$_baseUrl/verify_otp.php')` | `server/verify_otp.php` |
| 105 | `Uri.parse('$_baseUrl/unsubscribe.php')` | `server/unsubscribe.php` (generic opt-out; not the one used by the app's P4 flow — see below) |

### `app/lib/features/auth/services/user_auth_service.dart`
Phone+password auth, backed by the new `medremind_*.php` endpoints. All requests go through the single `_post()` helper at **line 132**; call sites:

| Line | Call | Hits |
|---|---|---|
| 54 | `_post('medremind_check_phone.php', ...)` | `server/medremind_check_phone.php` |
| 63 | `_post('medremind_register.php', ...)` | `server/medremind_register.php` |
| 73 | `_post('medremind_login.php', ...)` | `server/medremind_login.php` |
| 89 | `_post('medremind_unsubscribe.php', ...)` | `server/medremind_unsubscribe.php` |
| 103 | `_post('medremind_change_password.php', ...)` | `server/medremind_change_password.php` |
| 117 | `_post('medremind_profile.php', ...)` | `server/medremind_profile.php` |
| 132 | `http.post(Uri.parse('$_baseUrl/$endpoint'), ...)` | shared request builder used by all of the above |

Base URL for both files: `SERVER_BASE_URL` dart-define, defaulting to
`https://ruetandroiddevelopers.com/ARIF(MRe)` (`auth_service.dart:8-11`,
`user_auth_service.dart:9-12`).

---

## 2. PHP server → BDApps API

| File : Line | BDApps endpoint | Purpose |
|---|---|---|
| `server/send_otp.php:25-27` | `POST /subscription/otp/request` | Send OTP for registration (P1) |
| `server/verify_otp.php:30-32` | `POST /subscription/otp/verify` | Verify OTP entered by user (P1) |
| `server/unsubscribe.php:68-70` | `POST /subscription/send` (`action:"0"`) | Generic opt-out — shared script, not called by med_remind_v2's app anymore |
| `server/medremind_unsubscribe.php:30` | `POST /subscription/send` (`action:"0"`) | **Actual P4 unsubscribe path**: opt out via BDApps, then delete the user's row on success |
| `server/medremind_admin_unsubscribe.php:38` | `POST /subscription/send` (`action:"0"`) | Manual/admin test script (not linked from the app) |
| `server/subscriptionNotification.php:32` | `POST /sms/send` | Sends a welcome SMS when BDApps calls back with `status == REGISTERED` |
| `server/bdapps_cass_sdk.php:588` | `GET/POST /subscription/getstatus` | SDK helper class — subscription status check (not currently called by any med_remind_v2 endpoint) |
| `server/bdapps_cass_sdk.php:604` | `POST /subscription/send` | SDK helper class — subscribe |
| `server/bdapps_cass_sdk.php:619` | `POST /subscription/send` | SDK helper class — unsubscribe |
| `server/bdapps_cass_sdk.php:634` | (generic `curl_init($this->server)`) | Shared cURL execution inside the SDK helper classes above |

BDApps credentials (`applicationId` / `password`) are hardcoded per-file, e.g.
`server/send_otp.php:9-10`, `server/verify_otp.php:20`,
`server/medremind_unsubscribe.php:20-21`.

---

## 3. PHP server endpoints exposed to the app

These are the URLs the app actually calls (entry points, not the BDApps calls
inside them):

| File | Endpoint path | Auth required |
|---|---|---|
| `server/medremind_check_phone.php` | `/medremind_check_phone.php` | none |
| `server/medremind_register.php` | `/medremind_register.php` | none (called right after OTP verify) |
| `server/medremind_login.php` | `/medremind_login.php` | none (password is the credential) |
| `server/medremind_profile.php` | `/medremind_profile.php` | phone + session token (see `medremind_db.php:69` `medremind_require_session`) |
| `server/medremind_unsubscribe.php` | `/medremind_unsubscribe.php` | phone + session token |
| `server/medremind_change_password.php` | `/medremind_change_password.php` | phone + session token, plus current password |
| `server/medremind_fp_request_reset.php` | `/medremind_fp_request_reset.php` | none (phone must already exist) |
| `server/medremind_fp_reset_password.php` | `/medremind_fp_reset_password.php` | OTP (`referenceNo` + `otp`), not a session token |
| `server/medremind_admin_unsubscribe.php` | `/medremind_admin_unsubscribe.php` | none — manual test tool, see warning comment at top of file |
| `server/send_otp.php` | `/send_otp.php` | none |
| `server/verify_otp.php` | `/verify_otp.php` | none |

### Forgot password (`server/medremind_fp_*.php`) — same folder as everything else

Consolidated into `server/` so all medremind endpoints (auth, change
password, forgot password) deploy as one single folder; uses
`server/medremind_db.php` directly, same as the other `medremind_*.php`
files.

| File | Endpoint path | BDApps call | Auth required |
|---|---|---|---|
| `server/medremind_fp_request_reset.php` | `/medremind_fp_request_reset.php` | `POST /subscription/otp/request` | none (phone must already exist) |
| `server/medremind_fp_reset_password.php` | `/medremind_fp_reset_password.php` | `POST /subscription/otp/verify` | OTP (`referenceNo` + `otp` from step 1), not a session token |

**App call sites** — `app/lib/features/auth/services/forgot_password_service.dart`:

| Line | Call | Hits |
|---|---|---|
| 22 | `_post('medremind_fp_request_reset.php', ...)` | `server/medremind_fp_request_reset.php` |
| 25-30 | `_post('medremind_fp_reset_password.php', ...)` | `server/medremind_fp_reset_password.php` |
| 43 | `http.post(Uri.parse('$_baseUrl/$endpoint'), ...)` | shared request builder |

Base URL: `SERVER_BASE_URL` dart-define, same as the rest of
`user_auth_service.dart` — no longer a separate deployment folder.

UI entry point: "Forgot password?" link on
`app/lib/features/auth/screens/login_password_screen.dart`, which requests
the OTP then pushes `app/lib/features/auth/screens/reset_password_screen.dart`
(single screen: OTP + new password, submitted together).

---

## Notes

- Firebase (Firestore/Cloud Functions/Auth) was fully removed — there are no
  Firebase API calls left in the app. `app/functions/` is now dead code kept
  around only in case you want to reference the old Cloud Functions logic;
  it's not deployed or called by anything.
- `server/unsubscribe.php`, `server/send_otp.php`, `server/verify_otp.php` are
  shared with other apps (e.g. drink_water) — don't repurpose them for
  med_remind_v2-only logic; add a new `medremind_*.php` file instead, same
  pattern as the existing ones.
