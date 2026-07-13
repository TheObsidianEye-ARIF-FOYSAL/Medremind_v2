# Progress Log

Running log of work done on this repo, so work can be picked back up without
re-deriving context. Newest entries on top.

## 2026-07-13

- **BDApps compliance audit + partial fixes** for `landing/index.html`
  (checklist: name consistency, landing page, pricing display, platform
  info, subscribe/unsubscribe, logout, SMS link type, security, FAQ/user
  guide/subscription-response package). Findings: name/landing-page/
  subscribe-unsubscribe/logout all PASS; several FAIL/gaps found and
  partially fixed:
  - **Fixed**: landing page's "Download APK" button (3 occurrences) pointed
    at a GitHub Releases URL — BDApps explicitly rejects Google
    Drive/GitHub links, requires a working APK or Play Store URL. Changed
    to `https://ruetandroiddevelopers.com/ARIF(MR)/MedRemind.apk` (self-hosted
    on the same PHP host as the backend). **User still needs to actually
    upload `MedRemind.apk` to that path** — link will 404 until then.
  - **Fixed**: landing page had zero pricing or platform text (login screen
    already showed "৳2 +VAT+SD+SC per day" / "Supported: Android" but
    landing page didn't match). Added a line under the hero CTA:
    "Subscription: ৳2 + VAT + SD + SC per day. Platform: Android (web
    preview also available in-browser)." — matches the in-app wording.
  - **Not fixed, flagged for user**: `server/subscriptionNotification.php`
    sends a **leftover SMS template from a different app** ("BMIc"
    branding, Bengali text "BMIc-তে সাবস্ক্রাইব করার জন্য ধন্যবাদ!") with a
    `shorturl.at` link — doesn't mention MedRemind at all and isn't a
    direct APK/Play Store link. User asked to skip editing this for now
    but it must be fixed before submission (BDApps requires the
    subscription response SMS to include category + a working APK/Play
    Store link).
  - **Still missing** (not code-fixable, paperwork): no FAQ document found
    anywhere in the repo (BDApps requires one, filename matching App ID,
    sent to support@bdapps.com); no separate "Subscription Response
    Message" document/package. User guide PDF does exist
    (`docs/report_MR_app/medremind_user_guide.pdf`).
  - Also noted from earlier audit: release APK still signed with the debug
    key (`app/android/app/build.gradle.kts`), pre-existing TODO, not a
    user-facing risk but worth resolving before wide distribution.
  - Regenerated `MedReminder_upload.zip` (server test-copy package) with
    the fixed landing page; user needs to re-upload/re-extract it over
    `ruetandroiddevelopers.com/ARIF(MR)/MedReminder/`.

- **Added a `/MedReminder/` test-copy deployment**, separate from the main
  `/app/` build, per request ("build another web so I can test the web
  version, base href `/MedReminder/`, landing page then app").
  - First verified the web app itself is healthy: `flutter analyze` clean
    (only 2 pre-existing infos about `dart:html` in
    `mobile_web_detector_web.dart`), and `flutter build web --release
    --base-href /MedReminder/app/` compiles with no errors.
  - `.github/workflows/deploy-web.yml` now has a second build+assemble step
    pair that produces `site/MedReminder/` (landing page copied to
    `site/MedReminder/`, app built with `--base-href
    /Medremind_v2/MedReminder/app/` copied to `site/MedReminder/app/`) in
    the same Pages deploy as the main site — same landing→app ordering as
    the primary `/` → `/app/` structure, just under an extra path prefix so
    it's reachable at `.../Medremind_v2/MedReminder/` without disturbing the
    live main site.
  - Locally built and smoke-tested (served via `python -m http.server`,
    both `MedReminder/index.html` and `MedReminder/app/index.html` returned
    200) before removing the generated output from the working tree — it's
    a build artifact like `app/build/`, so added `/MedReminder/` to
    `.gitignore` rather than committing the ~30k generated files (the
    auto-commit hook had already picked them up once; reverted that via
    `git rm`).
  - **Not yet verified**: this test copy hasn't been exercised through an
    actual Pages deploy yet — next push to `main` (or manual
    `workflow_dispatch`) will build it; check
    `https://theobsidianeye-arif-foysal.github.io/Medremind_v2/MedReminder/`
    afterward.

- **Confirmed the released APK does NOT yet contain today's alarm fix.**
  This repo has an auto-commit hook, so the `main.dart`/`reminder_review_screen.dart`
  alarm fix and the `settings_screen.dart` user-manual-link change landed on
  `main` automatically (commit `8b7e8c2`, "landing page 23") without an
  explicit commit step. But `.github/workflows/release-apk.yml` only builds
  and publishes `MedRemind.apk` on a `v*` tag push or manual
  `workflow_dispatch` — plain pushes to `main` don't trigger it. The last
  tag is still `v2.9.13`, built before the alarm fix, so
  `.../releases/latest/download/MedRemind.apk` currently serves the old,
  buggy build. **Open item**: push a new version tag (e.g. `v2.9.14`,
  bumping `app/pubspec.yaml`) or manually run the workflow_dispatch to cut a
  new APK release with the fix.

- **Added a "Resources" section to `landing/index.html`** with two styled
  cards linking to `docs/PROJECT_OVERVIEW.md` on GitHub (project
  description) and the hosted `medremind_user_guide.pdf` (user manual),
  each opening in a new tab. Replaced the old bare "User Guide" nav link
  with a "Resources" nav link pointing at the new `#resources` section
  (footer link to the PDF left as-is).

- **Added an in-app "User Manual" link** (`app/lib/features/settings/presentation/screens/settings_screen.dart`,
  About section) — turned out the landing page and README already linked the
  hosted user-guide PDF fine, but the actual gap the user meant was that the
  *app itself* (the thing you land in from "Try in Browser" / the APK) had
  no way to reach the manual or a written description beyond a short About
  card. Added `url_launcher: ^6.3.1` to `pubspec.yaml` and a "User Manual"
  nav tile that opens
  `https://theobsidianeye-arif-foysal.github.io/Medremind_v2/medremind_user_guide.pdf`
  in the external browser/PDF viewer (`LaunchMode.externalApplication`) —
  verified the hosted PDF resolves (not a 404). `flutter analyze` clean.

- **Fixed alarm not stopping when a dose is marked Taken.** Root cause was in
  `app/lib/main.dart`: the full-screen `ActiveAlarmScreen` (which owns the
  Taken/Snooze/Skip buttons that call `alarmService.cancelAlarm`) was only
  ever navigated to once, during the app's very first cold-start flow
  resolution (`_resolveFlow()`'s one-time `_handlePendingAlarm()` call). If
  an alarm rang while the app was already open/resumed — the normal case —
  `Alarm.ringStream` fired and started the ring/auto-snooze cycle, but
  nothing navigated to the alarm screen, so there was no "Taken" button
  wired to that specific ringing alarm and it just kept looping.
  - Fix: added a top-level `_appReady` flag, set once `_flow == true` is
    first reached. The `Alarm.ringStream` listener (`main.dart:59-` now)
    checks it on every ring: if the app's flow is already resolved, it
    navigates to `ActiveAlarmScreen` immediately; otherwise it falls back to
    the old `_pendingAlarmId` + `_handlePendingAlarm()` path for the
    cold-start case.
  - **Related bug fixed in the same trace**:
    `reminder_review_screen.dart:182-187` called
    `alarmService.scheduleAlarm(...)` without passing `groupId`, so
    `_saveGroupMapping` never ran for that alarm id. `getGroupIdForAlarm`
    later returned `null`, `doseGroupId` arrived empty at
    `ActiveAlarmScreen`, and the dose-log update silently no-opped (dose
    never actually marked Taken in the DB) even on the rare occasions the
    screen did open and `cancelAlarm` fired correctly. Added the missing
    `groupId: group.id` argument.
  - Verified with `flutter analyze` on both changed files (no issues). Not
    yet manually verified on-device with a real ringing alarm — next step
    if this recurs.

- **Investigated "GitHub landing page has no link to app description/user
  manual"**: turned out to be a false alarm on the docs side —
  `README.md` and `landing/index.html` both already link to
  `docs/PROJECT_OVERVIEW.md` and the hosted user-guide PDF. The actual gap
  is the GitHub repo's **About sidebar** (top-right of the repo page),
  which currently shows "No description, website, or topics provided." —
  a repo *setting*, not something fixable via a file edit. **Open item**:
  user (or Claude, if given details) needs to set a description + the
  GitHub Pages URL as "website" via repo page → gear icon next to About.

## 2026-07-12

- **Added a marketing landing page**, separate from the Flutter web app, so
  GitHub Pages root is no longer the raw app:
  - New `landing/index.html` (self-contained, no build step) — hero with a
    real app screenshot in a phone-frame mockup (cropped from
    `docs/report_MR_app/screenshots/16_home_dose_card.png`, saved as
    `landing/assets/app-screenshot.png`), features grid, dose-group colour
    band, "how it works" steps, CTA banner, footer. Styled with the app's
    actual brand palette (`#6C5CE7` purple) and logo
    (`landing/assets/logo.png`, copied from `app/assets/icon/MedRemind.png`).
  - `.github/workflows/deploy-web.yml` reworked: Flutter now builds with
    `--base-href /Medremind_v2/app/` (was `/Medremind_v2/`), and a new
    "Assemble Pages site" step composes `site/` = `landing/` at the root +
    built app under `site/app/`. User guide PDF copied to both locations.
  - Result: `https://theobsidianeye-arif-foysal.github.io/Medremind_v2/` is
    now the landing page; the actual app lives at `.../Medremind_v2/app/`.

- **Device Preview now skipped on mobile web.** Previously `kIsWeb` alone
  gated `DevicePreview` (see `app/lib/main.dart`), so it showed even when the
  web app was opened/installed on a phone. Added
  `app/lib/core/utils/mobile_web_detector*.dart` (conditional `dart:html`
  import, checks user-agent + screen width) and a `_devicePreviewEnabled =
  kIsWeb && !isMobileWebBrowser()` flag in `main.dart` — phones now get a
  normal full-screen app; only desktop/laptop browsers get the device-frame
  picker.

- **Fixed missing app icon on PWA install.** `flutter_launcher_icons` in
  `app/pubspec.yaml` only had `android`/`ios` enabled, so `app/web/icons/*`
  and `app/web/favicon.png` were still Flutter's default template icons.
  Added a `web:` block pointing at `assets/icon/MedRemind.png` and reran
  `dart run flutter_launcher_icons`. Also fixed stale "med_remind_v2 / A new
  Flutter project" branding in `app/web/index.html` and
  `app/web/manifest.json` → now says "MedRemind" throughout, with
  `theme_color`/`background_color` set to the brand purple.

- **Fixed missing install button after the landing-page split.** Splitting
  root into landing + `/app/` meant the root had no manifest/service-worker,
  so browsers stopped offering "Install" there (previously the whole root
  *was* the installable PWA). Added `landing/manifest.json` (same MedRemind
  icons, `start_url: "./app/"` so installing from the root launches straight
  into the app, not the marketing page) and matching manifest/icon/
  theme-color tags in `landing/index.html`.

- **Added an explicit in-page Install flow** (`beforeinstallprompt` handling
  + iOS "Add to Home Screen" instructions modal) since relying on the
  browser's own install UI wasn't discoverable enough. Iterated on layout a
  couple of times per feedback — landed on exactly two buttons per section
  (primary action + "Try in Browser"), grouped in a `.nav-actions` wrapper in
  the header (they'd been direct flex children of a `space-between` nav,
  which visually broke).

- **Root cause of "notifications/alarms broken, can't create dose group"
  after installing the *web* app**: browsers heavily sandbox PWA
  notification/exact-alarm APIs — this is a fundamental web-vs-native gap,
  not a bug to patch. Decision: ship a real APK instead of pushing users to
  the PWA for the full experience.
  - Added `.github/workflows/release-apk.yml` — builds a universal
    `flutter build apk --release` and publishes it as a GitHub Release asset
    named `MedRemind.apk` (via `softprops/action-gh-release`), triggered by
    pushing a `v*` tag or manual `workflow_dispatch` (the latter rolls a
    floating `apk-latest` release).
  - Landing page's primary CTA is now **"⬇️ Download APK"**
    (`https://github.com/TheObsidianEye-ARIF-FOYSAL/Medremind_v2/releases/latest/download/MedRemind.apk`)
    on Android/desktop, with a small "allow installs from this browser"
    note. iOS (no APK equivalent) automatically falls back to the PWA
    "Install App" flow instead — handled via user-agent check in the same
    script that runs the install-prompt logic.
  - Note left as-is: `app/android/app/build.gradle.kts` still signs release
    builds with the **debug key** (pre-existing `TODO`). Fine for sideloaded
    APKs; if a proper release keystore is added later, users will need to
    uninstall the old APK first since Android blocks updates across
    different signing keys.
  - Bumped `app/pubspec.yaml` version `2.0.0+1` → `2.9.13+1` per request,
    tagged and pushed `v2.9.13` (after deleting an earlier `v2.0.0` tag/
    push). **Open item:** the orphaned `v2.0.0` GitHub Release (if the
    workflow had already run for it) needs manual deletion from the
    Releases page — deleting the git tag doesn't remove it.

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
- [ ] Confirm `release-apk.yml` finished successfully for tag `v2.9.13` and
      that `.../releases/latest/download/MedRemind.apk` actually resolves —
      check the Actions tab.
- [ ] Manually delete the orphaned `v2.0.0` GitHub Release (tag was deleted
      locally/remotely, but the Release entry itself isn't auto-removed).
- [ ] Decide whether to move release signing off the debug key
      (`app/android/app/build.gradle.kts:31`) before this APK gets wide
      distribution — later switching keys breaks in-place updates for
      anyone who already installed the debug-signed build.
- [ ] Manually verify the alarm-stop fix (2026-07-13) on a real device: let
      an alarm ring while the app is open, confirm it navigates to
      `ActiveAlarmScreen` and that tapping Taken actually silences it and
      marks the dose in history.
- [ ] Set the GitHub repo's About sidebar (description + website URL) —
      currently empty; not fixable via code, needs a repo-settings edit.
- [ ] Cut a new APK release (tag `v2.9.14`+ or manual workflow_dispatch) so
      `.../releases/latest/download/MedRemind.apk` actually contains the
      2026-07-13 alarm-stop fix — current live download is still the
      pre-fix `v2.9.13` build.
