# Pill Reminder — Flutter App

A simple, local-first medication reminder app for Android (and iOS). Schedule your pills, get push notifications at the right time, and keep track of what you've taken.

## What It Does

- **Add medications** with name, dosage, and time of day
- **Daily notifications** with high priority at the scheduled time
- **"Overdue" section** on the home screen highlighting pills that are past their time but not yet marked as taken
- **Intake history** accessible from the AppBar — a log of every pill you've taken with date and time
- **Edit & delete** pills (deleting a pill also removes its scheduled notification and intake history)

## Architecture

```
lib/
├── main.dart                              # Entry point: initializes timezones, notifications, MaterialApp
├── data/
│   └── app_database.dart                  # SQLite layer (sqflite) — tables, models, CRUD
├── services/
│   ├── notification_service.dart          # flutter_local_notifications wrapper
│   └── pill_service.dart                  # Orchestrates DB + notifications + business logic
└── screens/
    ├── home_screen/
    │   ├── home_screen.dart               # Main screen with FAB, overdue section, pill list
    │   ├── overdue_section.dart           # Pills past their time, not yet taken today
    │   ├── pills_list_section.dart        # All scheduled pills with edit/delete actions
    │   └── intake_dialog.dart             # Confirmation dialog "Have you taken X?"
    ├── add_pill_screen/
    │   ├── add_pill_screen.dart           # Form screen (add or edit mode)
    │   ├── name_field.dart                # Medication name input
    │   ├── time_picker_field.dart         # Time picker for dosage time
    │   └── quantity_field.dart            # Dosage/description input
    └── history_screen/
        ├── history_screen.dart            # Intake history with pull-to-refresh
        └── intake_card.dart               # Single intake record card
```

## Design Decisions

### SQLite over SharedPreferences
The app stores both scheduled pills and an intake history. A relational database (SQLite via `sqflite`) was chosen over key-value storage because:
- Intake records need to be linked to pills via foreign key
- History queries (filter by pill, order by date) are trivial with SQL
- No ORM overhead — raw `sqflite` with manual `toMap()`/`fromMap()` serialization keeps things simple

### Screen-local widgets
Each screen lives in its own subdirectory with its widgets co-located. A widget like `PillCard` lives inside `home_screen/` because it's only used there. This avoids a top-level `widgets/` folder where it's unclear which screen owns which widget.

### Notification scheduling
Uses `flutter_local_notifications` with `zonedSchedule()` and `DateTimeComponents.time` for daily recurring notifications. Android uses `exactAllowWhileIdle` mode so notifications fire reliably even with Doze mode. A notification channel with `Importance.max` ensures high visibility.

### Notification tap → auto-refresh
`NotificationService` extends `ChangeNotifier`. When the user taps a notification, `_onNotificationTap()` calls `notifyListeners()`. `HomeScreen` subscribes via `addListener()` in `initState` (and removes it in `dispose`), triggering `_loadData()` to refresh the overdue section and pill list without requiring a manual pull-to-refresh.

### Overdue detection
At home screen load, the app checks each pill: if its scheduled time has passed and `isTakenToday()` returns false, it appears in the "Overdue" section. Marking a pill as taken inserts a record into `pill_intakes` and removes it from the overdue list.

## Database Schema

### `pills`
| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `name` | TEXT NOT NULL | Medication name (max 100 chars) |
| `time` | TEXT NOT NULL | Time string in "HH:MM" format (max 5 chars) |
| `quantity` | TEXT NOT NULL | Dosage description (max 100 chars) |
| `created_at` | INTEGER NOT NULL | Unix timestamp (auto-set on insert) |

### `pill_intakes`
| Column | Type | Notes |
|---|---|---|
| `id` | INTEGER PRIMARY KEY AUTOINCREMENT | |
| `pill_id` | INTEGER NOT NULL | FK → pills.id (ON DELETE CASCADE) |
| `taken_at` | INTEGER NOT NULL | Unix timestamp of intake |

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `sqflite` | ^2.4.2+1 | Local SQLite database |
| `flutter_local_notifications` | ^21.0.0 | Scheduled push notifications |
| `timezone` | ^0.11.0 | Timezone support for scheduled notifications |
| `intl` | ^0.20.2 | Date/time formatting in history screen |
| `path` | ^1.9.0 | Database file path resolution |

## Android Configuration

Key settings in `android/app/build.gradle.kts`:
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

## Running the App

```bash
flutter pub get
flutter run
```

## Future Improvements

- Repeat patterns (e.g., Mon/Wed/Fri instead of daily)
- Multiple daily reminders per pill
- Missed pill alerts
- Export intake history (CSV/PDF)
- Widget for home screen quick-add
- Dark theme refinements
