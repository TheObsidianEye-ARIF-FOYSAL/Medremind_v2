# MedRemind — Project Overview

**Your Smart Medicine Reminder** — a mobile app (with a browser demo) that
helps patients and caregivers in Bangladesh never miss a dose.

---

## Quick links

| What | Link |
|---|---|
| **Live web demo** | https://theobsidianeye-arif-foysal.github.io/Medremind_v2/ |
| **Source code (GitHub)** | https://github.com/TheObsidianEye-ARIF-FOYSAL/Medremind_v2 |
| **User guide (PDF, with screenshots)** | https://theobsidianeye-arif-foysal.github.io/Medremind_v2/medremind_user_guide.pdf |

The web demo rebuilds and redeploys automatically every time code is pushed
to the `main` branch — always reflects the latest version.

---

## What the app does

- **Medicine Cabinet** — a personal list of every medicine the user takes
  (brand name, generic name, strength, form), pulled from a built-in
  database of common Bangladeshi brand names.
- **Dose Groups (Schedules)** — bundle medicines into named times of day
  (Morning/Afternoon/Evening/Night) with an exact alarm time, optional
  meal relation (before/after meal), and repeat days.
- **Full-screen alarms** — ring at the scheduled time even if the screen is
  off or another app is open, with Dismiss (Taken) / Snooze / Skip actions
  directly on the alarm screen or its notification.
- **Home dashboard** — today's doses with a live progress ring, filterable
  by time of day.
- **Daily Planner** — full-month calendar with a colour-coded adherence dot
  per day (all taken / partial / missed / scheduled).
- **History** — weekly adherence percentage, a monthly heatmap, and a full
  chronological dose log.
- **Account** — phone number + password sign-in, verified once at
  registration via an SMS OTP; profile screen with logout, change password,
  and unsubscribe.

---

## How access works

The app is distributed through **BDApps** (Robi/Airtel direct-carrier
billing): subscribing costs a small amount per day, billed to the user's
mobile operator account, verified by an SMS OTP tied to their phone number.

- **Native mobile app** (Android): full functionality — real OTP/SMS via
  BDApps, local SQLite storage, real system alarms and notifications.
- **Web demo**: for viewing/reviewing the UI and flows only.
  - Uses [Device Preview](https://pub.dev/packages/device_preview) so it
    can be viewed inside a phone-shaped frame in any browser.
  - Local data (medicines, dose groups, dose history) is stored in the
    browser's IndexedDB instead of a native SQLite file — it works for
    demoing the full CRUD flow, but each browser/device has its own
    separate data, and OS-level permissions/alarms/notifications don't
    apply on web (those calls are safely no-op'd).
  - The subscription/OTP screens work against the real BDApps API, which
    during testing only accepts a small set of BDApps-whitelisted phone
    numbers (see "BDApps testing status" below).

---

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter (Dart), Riverpod for state, go_router for navigation |
| Local storage | SQLite via `sqflite` (native) / IndexedDB via `sqflite_common_ffi_web` (web) |
| Alarms/notifications | `alarm` + `flutter_local_notifications` packages (native only) |
| Auth/subscription | Custom PHP + SQLite server (`server/`), talking to the BDApps API |
| Hosting (web demo) | GitHub Pages, auto-deployed by GitHub Actions on every push to `main` |

Full technical breakdown of the BDApps integration (endpoints, request/response
shapes, status codes) is in `server/BDAPPS_INTEGRATION.md`.

---

## BDApps testing status

The app's BDApps application (`APP_138840`, branded "MedRee") is currently
approved for **testing only** — BDApps will only process OTP/subscribe/
unsubscribe requests for a short list of phone numbers they've whitelisted
for this testing phase. Any other number is rejected by BDApps itself
(independent of anything in the app or server code).

Once testing is complete, requesting **Active Production** from BDApps
(email `support@bdapps.com`) opens it up to any real number.

---

## Repository layout

```
med_remind_v2/
├── app/                    Flutter app source
├── server/                 PHP + SQLite backend (auth, OTP, subscription)
├── docs/
│   └── report_MR_app/      LaTeX user guide + screenshots (PDF included)
└── .github/workflows/      CI: builds the web demo and deploys to GitHub Pages
```

---

## Security note

BDApps credentials are kept in `server/bdapps_config.php`, which is
gitignored and never committed — see `server/bdapps_config.example.php`
for the template. If you're setting this server up fresh, copy the example
file, fill in the real `BDAPPS_APP_ID` / `BDAPPS_APP_PASSWORD`, and deploy
`bdapps_config.php` alongside the rest of `server/` on your host.
