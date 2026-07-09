# MedRemind

**Your Smart Medicine Reminder** — a Flutter app that helps patients and
caregivers in Bangladesh never miss a dose, with subscription/OTP handled
through BDApps (Robi/Airtel direct-carrier billing).

🔗 **Live web demo:** https://theobsidianeye-arif-foysal.github.io/Medremind_v2/

📄 **Full project overview:** [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md)

📘 **User guide (PDF):** https://theobsidianeye-arif-foysal.github.io/Medremind_v2/medremind_user_guide.pdf

---

## What it does

- **Medicine Cabinet** — track every medicine you take (brand, generic name, strength, form).
- **Dose Groups** — group medicines into Morning/Afternoon/Evening/Night schedules with exact alarm times, meal relation, and repeat days.
- **Full-screen alarms** — ring even when the screen is off or another app is open, with Taken/Snooze/Skip actions.
- **Home dashboard, Daily Planner, and History** — track today's doses and adherence over time with a colour-coded calendar heatmap.
- **Phone + password auth** — verified once via SMS OTP at registration.

See [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) for the full breakdown.

---

## Repository layout

```
med_remind_v2/
├── app/                    Flutter app source
├── server/                 PHP + SQLite backend (auth, OTP, subscription via BDApps)
├── docs/                   Project overview, user guide (PDF + LaTeX source)
└── .github/workflows/      CI: builds the web demo and deploys to GitHub Pages
```

## Running locally

```bash
cd app
flutter pub get
flutter run                      # native (Android/iOS/desktop)
flutter run -d chrome             # web, with Device Preview enabled
```

The server (`server/`) is plain PHP + SQLite — deploy it to any PHP host,
and copy `server/bdapps_config.example.php` to `server/bdapps_config.php`
(gitignored) with your own BDApps credentials before use. See
[`server/BDAPPS_INTEGRATION.md`](server/BDAPPS_INTEGRATION.md) for how the
BDApps API integration works.

## Web demo notes

The web build is for **viewing the UI only** — it stores data in the
browser's IndexedDB instead of native SQLite, and OS-level
permissions/alarms/notifications are no-ops (they don't apply in a
browser). It's wrapped in [Device Preview](https://pub.dev/packages/device_preview)
so it can be viewed inside a phone frame from any browser.
