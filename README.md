# 💊 Pill Reminder

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-10095e.svg)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A local-first medication reminder app for Android. Schedule your pills, get reliable push notifications, and keep track of your intake history — all stored privately on your device.

## Features

- **Add medications** with name, dosage/description, scheduled time, and optional total dose target
- **Daily push notifications** with high priority at the scheduled time (exact alarm, works with Doze mode)
- **Overdue section** on the home screen highlighting pills past their time but not yet taken today
- **Intake history** — a complete log of every pill taken, with date and time
- **Dosage change tracking** — history reconstructs what dosage was active at each intake
- **Total intake counter** per pill with optional dose target (e.g., track progress toward 30 doses)
- **Disable toggle** — pause notifications without deleting a pill
- **Import/export backup** (JSON) via settings screen
- **Edit & delete** pills (deleting a pill also removes its scheduled notification and intake history)

## Tech Stack

| Component | Package | Purpose |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform UI |
| Database | `sqflite` | Local SQLite storage |
| Notifications | `flutter_local_notifications` | Scheduled push notifications |
| Timezone | `timezone` | Timezone-aware scheduling |
| Date formatting | `intl` | Display formatting |
| File I/O | `file_picker`, `share_plus`, `path_provider` | Import/export backups |

## Architecture

```
lib/
├── main.dart                              # Entry point: initializes timezones, notifications, MaterialApp
├── data/
│   └── app_database.dart                  # SQLite layer — tables, models, CRUD
├── services/
│   ├── notification_service.dart          # flutter_local_notifications wrapper
│   ├── pill_service.dart                  # Orchestrates DB + notifications + business logic
│   └── import_export_service.dart         # JSON import/export
└── screens/
    ├── home_screen/                       # Main screen, overdue section, pill list, intake dialog
    ├── add_pill_screen/                   # Add/edit form
    ├── history_screen/                    # Combined intake + dosage change history
    └── settings_screen/                   # Import/export settings
```

## Getting Started

```bash
# Clone the repository
git clone https://github.com/DanielusG/pills_reminder.git
cd pills_reminder

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Android Configuration

The following settings are required in `android/app/build.gradle.kts`:

- **Core library desugaring** — required by `flutter_local_notifications` for timezone APIs on older Android versions
- **MultiDex** — enabled for compatibility
- **Java 17** — compile and target compatibility

Key permissions in `AndroidManifest.xml`:

- `POST_NOTIFICATIONS` — Android 13+ notification permission
- `RECEIVE_BOOT_COMPLETED` — restore scheduled notifications after reboot
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` — exact alarm scheduling
- `VIBRATE` — notification vibration

Two receivers are registered for `flutter_local_notifications`:

- `ScheduledNotificationReceiver` — fires scheduled notifications
- `ScheduledNotificationBootReceiver` — restores them after device reboot

## Database Schema

### `pills`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `name` | TEXT NOT NULL | Medication name |
| `time` | TEXT NOT NULL | Scheduled time in "HH:MM" format |
| `quantity` | TEXT NOT NULL | Dosage description |
| `total_dose` | INTEGER | Optional total dose target (e.g., 30) |
| `is_disabled` | INTEGER NOT NULL | 0 = active, 1 = disabled (paused) |
| `created_at` | INTEGER NOT NULL | Unix timestamp |

### `pill_intakes`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `pill_id` | INTEGER NOT NULL | FK → pills.id (ON DELETE CASCADE) |
| `taken_at` | INTEGER NOT NULL | Unix timestamp of intake |
| `quantity_at_intake` | TEXT | Dosage description at the time of intake |

### `pill_dosage_changes`

| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `pill_id` | INTEGER NOT NULL | FK → pills.id (ON DELETE CASCADE) |
| `new_quantity` | TEXT NOT NULL | Updated dosage description |
| `changed_at` | INTEGER NOT NULL | Unix timestamp of change |

## License

This project is licensed under the [MIT License](LICENSE).
