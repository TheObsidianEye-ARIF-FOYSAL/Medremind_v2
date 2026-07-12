# Progress Log

Running log of work done on this repo, so work can be picked back up without
re-deriving context. Newest entries on top.

## 2026-07-10

- **BDApps server backend rebuilt** in `server/` (had been deleted from disk,
  restored from git history):
  - Generic shared scripts (`send_otp.php`, `verify_otp.php`,
    `unsubscribe.php`, `subscriptionNotification.php`, SDK/SMS/USSD files) —
    used by other apps (e.g. VenueLock) too.
  - MedRemind-specific backend (`medremind_*.php`): phone+password auth
    (register/login/profile/change-password), SQLite user storage
    (`medremind_db.php`), MedRee-branded OTP/unsubscribe flow.
  - Admin/testing helpers: `medremind_admin_status.php`,
    `medremind_admin_unsubscribe.php`.
  - Credentials live in `server/bdapps_config.php` (gitignored, not
    committed) — copy `bdapps_config.example.php` to make one. **Currently
    set to MedRee's own credentials: `APP_138840` /
    `ccd1dfd5656f07f95f8e63d1f9d40280`.** (Briefly swapped to VenueLock's
    `APP_128956` credentials to test past the testing-only restriction, then
    reverted back per request — see history below.)

- **Root cause found for "Unsubscribe just looks like logout" and
  "register doesn't actually subscribe"**: `APP_138840` is currently
  approved for **TESTING ONLY** on BDApps. In that mode, BDApps only runs
  real OTP/subscribe/unsubscribe actions for BDApps' own whitelisted test
  numbers — everyday phone numbers are never actually registered or
  unregistered, regardless of what the app sends. Confirmed via
  `medremind_admin_status.php?phone=...` before/after both register and
  unsubscribe — BDApps kept reporting `UNREGISTERED` either way.
  - **Action needed**: request "Active Production" status for `APP_138840`
    from BDApps support. Draft email saved at
    `bdapps_production_request_email.txt` (fill in name/phone/org before
    sending).

- **Fixed a real bug**: `medremind_send_otp.php` and
  `medremind_verify_otp.php` were missing CORS headers, unlike the
  DB-backed endpoints (which get them via `medremind_cors()` in
  `medremind_db.php`). This silently broke the **GitHub Pages web demo**
  (different origin from the PHP host) right after entering a phone
  number — the browser blocked the response before the app ever saw it.
  Added `Access-Control-Allow-Origin` etc. + OPTIONS preflight handling to
  both files. **User has already uploaded the fix to the live host**
  (`ruetandroiddevelopers.com/ARIF(MR)`) — needs to be retested on the
  GitHub Pages demo.

- Added `LICENSE` (custom, not a standard OSS license): free to use/modify/
  distribute with clear attribution to Arif Foysal Bin Haider; written
  permission required if not crediting.

- GitHub Actions (`deploy-web.yml`, GitHub Pages Flutter web deploy) only
  triggers on pushes touching `app/**`, the guide PDF, or the workflow file
  itself — **not** `server/**`. So server-side fixes never need a Pages
  rebuild; only Flutter/`app/` changes do.
  - Open item: user reported no "Run workflow" manual-dispatch button
    visible on the workflow's Actions page despite `workflow_dispatch`
    being present on `origin/main` (confirmed via `git show`) and having
    owner access with existing runs. Suggested checks: browser zoom/width
    (button can get squeezed off), hard refresh/incognito, repo
    Settings → Actions → General permissions. Not yet resolved/confirmed
    fixed.

## Known open items / next steps

- [ ] BDApps "Active Production" request for `APP_138840` — email drafted,
      not yet confirmed sent.
- [ ] Confirm GitHub Pages demo now gets past the phone-entry step after the
      CORS fix.
- [ ] Resolve missing "Run workflow" button on the Actions page (cosmetic/
      access issue, not a code bug).
- [ ] `medremind_verify_otp.php` still writes a `verify_otp_debug.log` file
      on every call (marked "TEMP DEBUG... remove once diagnosed" in the
      code) — not yet cleaned up.
