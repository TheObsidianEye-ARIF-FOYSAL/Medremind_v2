# MedRemind App Icon — Design Prompt

Use this prompt when generating or commissioning the app icon for **MedRemind**, a medicine reminder app that helps people take the right medicine at the right time.

## Prompt

> Design a modern, minimal mobile app icon for "MedRemind", a medicine reminder app. The icon should feature a white medicine capsule/pill tilted at a 45° diagonal angle as the central subject, paired with a small clock or bell accent (e.g., a clock face badge in the upper-right of the pill, or clock hands subtly integrated into the pill's shading) to communicate "time to take your medicine." Background: a smooth diagonal gradient from calm blue (#2563EB) to teal (#14B8A6), evoking trust, health, and care — avoid red/orange (associated with alarm/danger) and avoid clutter. Use a rounded-square (squircle) container matching standard iOS/Android adaptive icon safe zones, flat/semi-flat vector style with soft drop shadow under the pill for depth, no text or lettering, high contrast so it stays legible at 48x48 px, and a friendly, approachable, medically-trustworthy feel (not clinical/sterile, not cartoonish).

## Design rationale

- **Capsule/pill shape** — instantly recognizable as "medicine," works at any size.
- **Clock/bell accent** — differentiates from a generic pharmacy icon by emphasizing the *reminder* aspect, which is the app's core value.
- **Blue → teal gradient** — conveys calm, health, and reliability; avoids the anxious connotation of red alarm colors while still standing out on a home screen.
- **Rounded square / squircle** — matches platform adaptive-icon conventions (Android adaptive icon safe zone, iOS auto-corner-radius) so the icon isn't re-cropped awkwardly.
- **No text** — icons with text don't scale down legibly; the brand name lives in the app name below the icon, not inside it.
- **Flat/semi-flat with soft shadow** — keeps it modern (2024+ icon trends lean flat-with-subtle-depth rather than skeuomorphic or fully flat).

## Deliverable specs

- Master size: 1024×1024 px PNG (or SVG source), square, no transparency required for iOS (opaque background), transparent-safe padding for Android adaptive icon foreground layer.
- Safe zone: keep primary artwork within the center ~66% for Android adaptive icons (outer edges get masked/cropped by the OS shape).
- Export via `flutter_launcher_icons` into `app/assets/icon/` and regenerate platform icons with:
  ```
  flutter pub run flutter_launcher_icons
  ```

## Current asset

Generated icon: `app/assets/icon/MedRemind.png` (1024×1024).
