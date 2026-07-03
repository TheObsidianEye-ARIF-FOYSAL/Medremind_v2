# Medicine Reminder App — Build Specification

This document is the single source of truth for building this app. Read it fully before writing any code. The folder `./design` contains 4 reference screenshots — match the visual style (dark theme, purple accent, circular time picker, card-based lists, rounded pill-shaped buttons) as closely as possible. Treat these as the design system, not literal screens to copy 1:1 — extend the same visual language to every screen this spec describes.

**Platform: this is a Flutter app.** All structure, packages, and code below assume Flutter/Dart.

---

## 1. Product Summary

A medicine reminder app that:
- Reminds users to take medicine using **real alarm-style notifications** (full-volume sound + full-screen ringing alert, works even if the phone is locked or the app is closed) — not a silent push notification.
- Lets a user build a personal "medicine cabinet" of every medicine they take.
- Lets a user schedule **dose groups**: a time of day + a set of medicines + quantities + meal relation (before/after food).
- Has an **alternative-medicine finder**: type a brand name (e.g. "Napa") and see every other brand that shares the same active ingredient/generic (e.g. Paracetamol), so the user can substitute if they're out of stock.
- Has two login methods fully built in the UI/code but **not enforced** — the app must be fully usable without logging in (a "Skip / Continue as guest" path always exists). See §9.

---

## 2. Reference Design (`./design` folder)

| File | What it shows |
|---|---|
| Image 1 (orange) | Calendar grid screen — month view, circled dates, agenda cards below. Use the *layout idea* (calendar + agenda cards), but re-skin in the app's dark/purple theme, not orange. |
| Image 2 (dark, purple dial) | "Select time" — circular drag-dial time picker, big time readout, pill-shaped "Set Reminder" button. |
| Image 3 (two dark screens) | Left: "Reminder" review screen for one dose. Right: "Add medication" — name input, type selector (Tablet/Pill/Syringe/Syringe-pump icon), frequency editor with per-time-slot dose stepper and Before/After meal chips. |
| Image 4 (three dark screens) | Left: "Today's Pills" home screen — category tag, dose card with Taken button, mini calendar strip at bottom, bottom tab bar (Home / Pill / List / Profile). Middle & right: same Reminder + Add medication screens as Image 3. |

**Design tokens to extract and reuse everywhere:**
- Background: near-black (`#0E0E10`–`#141416` range), cards: slightly lighter dark gray with soft rounded corners (20–24px radius).
- Accent: vivid purple/indigo (`#6C5CE7`–`#7B5CFA` range) for primary actions, selected states, and the active dial arc.
- Secondary accent: green for "Morning" tags, orange/red for "Afternoon/Evening" tags (as seen in Image 4's "Cardiovascular" tag + "Morning ☀" / "Afternoon ☀" labels).
- Buttons: full-width, fully rounded ("pill") white or purple buttons for primary actions.
- Typography: bold large numerals for time, medium-weight sans-serif throughout (system font is fine — Inter/SF/Roboto).
- Bottom navigation: 4–5 icon tabs in a floating rounded bar.

---

## 3. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | **Flutter (Dart)** | Best cross-platform story for *exact, ringing, lock-screen alarms* — the core requirement. Also makes pixel-matching the custom circular dial and card UI straightforward. |
| State management | Riverpod | Simple, testable, scales fine for this app size. |
| Local database | Drift (SQLite) or Isar | Medicine cabinet, schedules, and dose logs must work fully offline — this is not optional, it's the backbone of reliability. |
| Alarms / notifications | `alarm` package (purpose-built for alarm-clock-style ringing on Android + iOS) plus `flutter_local_notifications` for non-ringing reminders/summaries | Standard push notifications are not reliable enough for "take your pill" — need real alarm scheduling that survives reboot and Doze mode. |
| Audio | `just_audio` (or whatever the `alarm` package already bundles) | Plays the ringtone-style alarm sound, supports custom sound picking later. |
| Auth (scaffolded, not enforced) | `firebase_auth` + `google_sign_in` for method 2; a custom `AuthService` interface + mock backend for method 1 (Phone OTP) | See §9. |
| Local generic/brand dataset | Bundled JSON, loaded into the local DB on first run | See §7. |

---

## 4. Project Folder Structure (Flutter)

Feature-first architecture: shared/core building blocks in `core/`, each screen-group lives in its own folder under `features/` with `domain` (use-cases) and `presentation` (providers/screens/widgets) split. Repositories, models, and the database live in `core/` since multiple features read/write the same entities (a `Medicine` is used by the cabinet, the alarm engine, and the alternative finder alike).

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration (auth scaffolding)
│
├── core/                              # Shared core functionality
│   ├── common/
│   │   └── widgets/                   # Reusable widgets used across features
│   │       ├── custom_text_field.dart
│   │       ├── pill_button.dart               # rounded full-width CTA button
│   │       ├── dose_card.dart                  # the card used on Home/Calendar
│   │       ├── circular_time_dial.dart         # Image 2/3 drag-dial widget
│   │       ├── mini_calendar_strip.dart        # Image 4 bottom strip
│   │       ├── themed_widgets.dart
│   │       └── themed_app_components.dart
│   │
│   ├── constants/
│   │   └── app_constants.dart
│   │
│   ├── database/                      # Local database layer
│   │   ├── database_service.dart      # Drift/Isar manager
│   │   └── database_tables.dart       # Table/collection schemas
│   │
│   ├── firebase/
│   │   └── firebase_service.dart      # Optional cloud sync, future use
│   │
│   ├── localization/
│   │   └── app_localizations.dart
│   │
│   ├── models/                        # Data models (see §5)
│   │   ├── medicine.dart
│   │   ├── generic_group.dart
│   │   ├── dose_group.dart
│   │   ├── dose_item.dart
│   │   ├── dose_log.dart
│   │   └── user_profile.dart
│   │
│   ├── providers/                     # Riverpod providers
│   │   ├── repository_providers.dart
│   │   └── theme_provider.dart
│   │
│   ├── repositories/                  # Data access layer
│   │   ├── medicine_repository.dart
│   │   ├── generic_group_repository.dart
│   │   ├── dose_group_repository.dart
│   │   └── dose_log_repository.dart
│   │
│   ├── services/                      # Business services — the alarm engine lives here
│   │   ├── alarm_service.dart          # schedule / cancel / reschedule-on-boot
│   │   ├── notification_service.dart   # non-ringing summary notifications
│   │   ├── permission_service.dart      # notification + exact-alarm + battery-opt prompts
│   │   └── audio_service.dart           # alarm sound playback, snooze logic
│   │
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── theme_constants.dart        # the dark/purple tokens from §2
│   │
│   └── utils/
│       ├── date_utils.dart
│       ├── time_utils.dart
│       ├── responsive_utils.dart
│       └── validation_utils.dart
│
├── features/                          # Feature modules
│   ├── medicine_cabinet/              # Add/edit medicine + dose-group scheduling
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── build_dose_groups_usecase.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── medicine_cabinet_provider.dart
│   │       ├── screens/
│   │       │   ├── add_medication_screen.dart      # Image 3/4 "Add medication"
│   │       │   └── medicine_list_screen.dart
│   │       └── widgets/
│   │           ├── medicine_type_selector.dart      # Tablet/Pill/Syringe/Syrup
│   │           ├── frequency_editor.dart            # Morning/Afternoon/Night slots
│   │           ├── dose_stepper.dart
│   │           └── meal_relation_chip.dart          # Before/After meal
│   │
│   ├── reminders/                     # Time picker, review, ringing screen
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       ├── schedule_alarm_usecase.dart
│   │   │       └── reschedule_on_boot_usecase.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── reminder_provider.dart
│   │       ├── screens/
│   │       │   ├── time_picker_screen.dart          # Image 2/3 "Select time"
│   │       │   ├── reminder_review_screen.dart       # Image 3/4 "Reminder"
│   │       │   └── active_alarm_screen.dart           # full-screen ringing alert
│   │       └── widgets/
│   │           └── circular_dial_widget.dart
│   │
│   ├── home/                          # "Today's Pills"
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── today_pills_provider.dart
│   │       ├── screens/
│   │       │   └── home_screen.dart                  # Image 4 left
│   │       └── widgets/
│   │           └── dose_group_card.dart
│   │
│   ├── calendar/                      # Calendar view feature
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── calendar_provider.dart
│   │       ├── screens/
│   │       │   └── calendar_screen.dart              # Image 1 layout, re-themed
│   │       └── widgets/
│   │           ├── month_grid_widget.dart
│   │           └── agenda_list_widget.dart
│   │
│   ├── alternative_finder/            # Generic/brand substitution (§7)
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── find_alternatives_usecase.dart
│   │   ├── data/
│   │   │   └── local_json_alternative_medicine_service.dart   # reads assets/generic_groups_seed.json
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── alternative_finder_provider.dart
│   │       ├── screens/
│   │       │   └── find_alternative_screen.dart
│   │       └── widgets/
│   │           └── brand_chip_list.dart
│   │
│   ├── history/                       # Adherence tracking
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── history_provider.dart
│   │       ├── screens/
│   │       │   └── history_screen.dart
│   │       └── widgets/
│   │           └── adherence_heatmap.dart
│   │
│   ├── settings/
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── settings_provider.dart
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── widgets/
│   │           ├── alarm_sound_picker_widget.dart
│   │           └── login_method_management_widget.dart      # incl. Unsubscribe control
│   │
│   ├── auth/                          # Both login methods — scaffolded, not enforced (§9)
│   │   ├── domain/
│   │   │   └── auth_service.dart      # abstract interface both methods implement
│   │   ├── data/
│   │   │   ├── bdapps_otp_service.dart       # mock/stub phone-OTP backend
│   │   │   └── firebase_auth_service.dart    # email/password + Google
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── screens/
│   │       │   ├── login_choice_screen.dart
│   │       │   ├── phone_input_screen.dart
│   │       │   ├── otp_verify_screen.dart
│   │       │   └── firebase_auth_screen.dart
│   │       └── widgets/
│   │           └── unsubscribe_button.dart
│   │
│   └── sync/                          # Future Firebase cloud sync — placeholder only
│       └── presentation/
│           └── providers/
│
├── assets/
│   └── generic_groups_seed.json       # bundled brand→generic dataset (§7)
│
├── l10n/
│   └── app_en.arb
│
└── test_helpers/
```

**Platform-config notes (outside `lib/`, don't forget these):**
- `android/app/src/main/AndroidManifest.xml` needs `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`, and `POST_NOTIFICATIONS` (Android 13+) entries, plus a boot-completed `BroadcastReceiver` that re-registers alarms.
- `ios/Runner/Info.plist` needs background modes + notification permissions for the alarm package to ring reliably.

---

## 5. Data Model

```
Medicine
- id
- brandName            // e.g. "Napa"
- genericGroupId        // FK -> GenericGroup
- form                  // tablet | pill | syrup | syringe | other
- strength              // e.g. "500mg", free text
- notes                 // optional

GenericGroup
- id
- name                   // e.g. "Paracetamol"
- description            // optional, short
// brand members are just every Medicine row pointing at this id,
// PLUS a master reference list bundled with the app (see §7) so
// suggestions work even for brands the user hasn't added yet.

DoseGroup (a "schedule")
- id
- label                  // e.g. "Morning", "Afternoon", "Night" (user-editable)
- timeOfDay              // HH:mm
- mealRelation           // before_meal | after_meal | none
- daysOfWeek             // bitmask or list, default = every day
- startDate / endDate    // endDate nullable = ongoing
- isActive               // bool, pause without deleting
- items: [DoseItem]

DoseItem  (one medicine inside a DoseGroup)
- id
- doseGroupId            // FK
- medicineId             // FK
- quantity               // e.g. 2 pills

DoseLog  (history / adherence)
- id
- doseGroupId
- scheduledFor            // datetime
- status                  // pending | taken | missed | skipped | snoozed
- actedAt                 // datetime, nullable

User (local profile, auth optional)
- id
- displayName
- phoneNumber             // nullable
- email                   // nullable
- authProvider            // none | bdapps_otp | firebase_email | firebase_google
```

Example mapped to the user's own scenario: 2 pills at 8:00 AM, 2 pills at 2:00 PM, 1 pill at 9:00 PM before food, 3 pills at 9:30 PM after food → **4 DoseGroups**, each with one or more `DoseItem`s.

---

## 6. Core Feature: Alarm-style Reminders

Non-negotiable behavior:
1. At the scheduled time, the phone **rings audibly** (default alarm-style tone, user can change it later) and shows a **full-screen alert** even if the phone is locked — same expectation as a stock Clock app alarm, not a quiet notification banner.
2. The full-screen alert shows: medicine name(s) + dose + before/after-meal note, and three actions: **Take**, **Snooze (10 min)**, **Skip**.
3. Every action writes a `DoseLog` row.
4. Reminders must survive app kill and device reboot (reschedule on boot — see `reschedule_on_boot_usecase.dart`).
5. Handle Android 13+ notification permission and Android 12+ exact-alarm permission with a clear one-time onboarding screen explaining why they're needed.
6. The time-picker screen (Image 2/3) is the UI for setting/editing the `timeOfDay` of a DoseGroup — implement the circular drag-dial exactly as shown: drag the handle around the ring, big "HH:MM AM/PM" readout above, "Set Reminder" pill button at the bottom.

---

## 7. Core Feature: Generic / Alternative-Medicine Finder

Goal: user types a brand name, e.g. "Napa," and the app shows every other brand in the same generic group (e.g. Paracetamol), so they can substitute when out of stock.

**Important reality check before building this:** there is no public, stable API for Bangladeshi drug brand→generic data. Do **not** attempt to live-scrape medex.com.bd or any site at runtime — that's unreliable and may violate the site's terms. Instead:

1. Ship a **bundled local dataset** (`assets/generic_groups_seed.json`) of common Bangladeshi brand names mapped to generic groups, e.g.:
```json
[
  { "generic": "Paracetamol", "brands": ["Napa", "Ace", "Fast", "Reset", "Paracin"] },
  { "generic": "Omeprazole", "brands": ["Seclo", "Losectil", "Opton"] },
  { "generic": "Amlodipine", "brands": ["Amdocal", "Amlovas", "Amloking"] }
]
```
Seed it with whatever real, well-known brand/generic pairs you can responsibly include; it's fine to start with a few dozen and leave the structure easy to extend.
2. Build this behind an interface (`alternative_finder/domain` + `alternative_finder/data/local_json_alternative_medicine_service.dart`), so a real backend/API can be swapped in later without touching the UI layer.
3. UI: a search field (typeahead) — typing "Napa" shows a result card: "Napa — Paracetamol group" with a chip list of the other brands in that group. This should be reachable both as its own "Find Alternative" screen and as a hint shown inline whenever a scheduled dose's medicine is marked unavailable.

---

## 8. Screens

1. **Splash** — logo, brief load.
2. **Onboarding (1–2 cards)** — what the app does, notification/alarm permission ask.
3. **Login choice screen** — two buttons: "Continue with phone (OTP)" and "Continue with email / Google," plus a prominent **"Skip for now"** link. (Both flows fully built per §9, neither is mandatory.)
4. **Phone OTP flow** — enter phone number → enter 6-digit OTP → success. Settings has an **"Unsubscribe"** action for this login method (stops further OTP-based sign-ins / deletes the local session).
5. **Email/Google flow** — Firebase email+password form, and a "Sign in with Google" button.
6. **Home / "Today's Pills"** (Image 4 left) — list of today's DoseGroups as cards (tag, time, dose count, Taken/pending state), mini horizontal calendar strip, floating "+" to add a medicine, bottom tab bar.
7. **Calendar view** (Image 1 layout, app's own theme) — month grid, tap a date to see that day's agenda of DoseGroups below it.
8. **Add Medication** (Image 3/4 right) — brand-name input (with generic-group autocomplete hint), type selector (Tablet/Pill/Syrup/Syringe), frequency editor: add one or more time slots ("Morning," "Afternoon," "Night," custom), per-slot dose-count stepper, Before/After-meal chip, "+" to add another slot, "Add to Pill list" button.
9. **Set Reminder / time picker** (Image 2/3) — circular dial as described in §6.
10. **Reminder review screen** (Image 3/4 middle) — single dose summary before confirming.
11. **Active Alarm / Ringing screen** — full-screen, Take / Snooze / Skip (§6).
12. **Find Alternative Medicine** — search + results (§7).
13. **History / Adherence** — list or simple calendar heat-map of taken/missed/skipped doses.
14. **Settings** — profile, alarm sound picker, theme, notification permissions status, login method management (incl. Unsubscribe for OTP login), about/version.

---

## 9. Authentication — Build Both, Enforce Neither

This is explicitly requested as **scaffolding for later**, not a live gate:

- **Method 1 — "BdApps-style" Phone OTP login**: user enters phone number → backend (stub this with a mock/local service for now, structured so a real SMS/OTP backend can be plugged in later) sends an OTP → user verifies → session stored locally. Include an **"Unsubscribe"** button in Settings for users who logged in this way (clears the session / opts out of future OTP contact).
- **Method 2 — Firebase**: email + password sign up/sign in, and Google sign-in, using `firebase_auth` + `google_sign_in`. (Will need a real Firebase project later — for now wire the code against Firebase but it's fine if it's not yet connected to a live project; stub/guard it so the app doesn't crash without Firebase configured.)
- **Critically:** the rest of the app (medicine cabinet, reminders, alarms, alternative finder) must work fully for a guest with no login at all. Login is optional account/sync scaffolding for the future, not a requirement to use the app today.

---

## 10. Non-Functional Requirements

- **Offline-first.** All core features work with no internet connection.
- **Dark theme as default and primary** (matches the reference design); a light theme is optional/nice-to-have, not required.
- Handle Android runtime permissions gracefully (notifications, exact alarms, battery-optimization exemption prompt so alarms aren't killed by the OS).
- Reasonable accessibility: large enough tap targets, sufficient contrast against the dark background.

---

## 11. Suggested Build Order (work phase by phase, show progress after each)

1. **Phase 0** — Project scaffold (folder structure per §4), theme/design tokens, navigation shell, bottom tab bar.
2. **Phase 1** — Local DB + data models/repositories (§5).
3. **Phase 2** — Add Medication screen + frequency/dose-group editor (§8.8).
4. **Phase 3** — Time-picker dial screen (§8.9) + alarm/notification engine (§6) — this is the riskiest/most important phase, get it solid before moving on.
5. **Phase 4** — Home "Today's Pills" screen + Calendar view + Taken/Skip/Snooze actions + DoseLog.
6. **Phase 5** — Alternative-medicine finder + seed dataset (§7).
7. **Phase 6** — History/Adherence screen + Settings.
8. **Phase 7** — Auth screens, both methods, scaffolded per §9 (skip-able).
9. **Phase 8** — Permission onboarding polish, edge cases (reboot rescheduling, timezone changes), final pass against the 4 reference screenshots.

## 12. Definition of Done

- [ ] A user with zero login can: add a medicine, build a multi-dose-group daily schedule, get a real ringing/locked-screen alarm at the right time, mark it Taken/Snoozed/Skipped, and see it reflected in history and the calendar.
- [ ] Typing a known brand name surfaces its generic group and sibling brands.
- [ ] Both login methods are reachable from the UI and functionally wired (OTP flow + Firebase email/Google), with a working "Skip" path and an "Unsubscribe" control for the OTP method.
- [ ] Visual style matches the dark/purple reference design across every screen, not just the ones with a direct screenshot reference.
- [ ] Alarms survive app restart and device reboot.
- [ ] Folder structure follows §4 (or an improvement on it the agent explicitly flags and explains).
