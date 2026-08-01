# Plan: Overdue Reminder Spam + Snooze

## Goal
When a pill is overdue (past scheduled time, not taken today), spam the user with notifications every 5 minutes. Include a "Ricordami tra 30 min" button that pauses the spam for 30 minutes.

## Design

### Notification IDs
| Purpose | ID |
|---|---|
| Main daily reminder | `pill.id` |
| 5-min repeating spam | `pill.id + 100_000` (e.g. pill 1 → 100001) |

### Notification Channels
| Channel | Purpose | Importance |
|---|---|---|
| `pills_channel` | Main daily reminder (existing) | `Importance.max` |
| `overdue_channel` | 5-min spam + snoozed notification | `Importance.default` |

### Flow

```
Pill becomes overdue
    ↓
[App open / refresh] → schedule 5-min repeating notification (overdue_channel)
    ↓
User gets notified every 5 min (spam!)
    ↓
Two outcomes:
  A) User opens app → marks pill as taken → cancel spam ✓
  B) User taps "Ricordami tra 30 min" → cancel spam, schedule one-time notification in 30 min
       ↓ (30 min later)
       Notification fires with same snooze button
       ↓
       User either opens app (taken → stop) or snooses again (repeat cycle)
```

## Changes

### 1. `lib/services/notification_service.dart`

Add:
- **Constants**: `OVERDUE_ID_OFFSET = 100000`, `ACTION_SNOOZE_ID = 'snooze_30m'`
- **`_backgroundActionHandler`** (static top-level function) — handles notification action taps in background isolate:
  - On snooze action: cancel 5-min repeating notification, schedule one-time snoozed notification 30 min later with same snooze button
- **`scheduleOverdueReminder(pillId, name, quantity)`** — starts `periodicallyShowWithDuration(5 min)` with snooze action button on `overdue_channel`
- **`scheduleSnoozedNotification(pillId, name, quantity)`** — one-time notification 30 min later with snooze button
- **`cancelOverdueReminder(pillId)`** — cancels the reminder notification by computed ID
- Update **`initialize()`** — pass `onDidReceiveBackgroundNotificationResponse: _backgroundActionHandler`
- Update **`_onNotificationTap()`** — also cancel overdue reminders (user opened app from main notification)

### 2. `lib/services/pill_service.dart`

Add:
- **`startOverdueReminder(pill)`** — calls `NotificationService().scheduleOverdueReminder(...)`
- **`stopOverdueReminder(pillId)`** — calls `NotificationService().cancelOverdueReminder(...)`
- Update **`logIntake(pillId)`** — also call `stopOverdueReminder(pillId)` after logging intake
- Update **`deletePill(id)`** — also call `stopOverdueReminder(id)` before deleting

### 3. `lib/screens/home_screen/home_screen.dart`

Update **`_loadData()`**:
- After loading overdue pills, call `startOverdueReminder()` for each overdue pill
- After loading (pill taken), call `stopOverdueReminder()` for pills that are no longer overdue

### 4. `android/app/src/main/AndroidManifest.xml`

Add required permissions/receivers for periodic notifications (if not already present):
- Verify `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` permissions exist (already there per AGENTS.md)
- The existing `ScheduledNotificationReceiver` and `ScheduledNotificationBootReceiver` handle the platform-side delivery

## Files Modified

| File | Changes |
|---|---|
| `lib/services/notification_service.dart` | Add overdue reminder methods, background handler, snooze logic |
| `lib/services/pill_service.dart` | Wire start/stop reminders to intake/delete/overdue flow |
| `lib/screens/home_screen/home_screen.dart` | Start reminders on load, stop when no longer overdue |

## Edge Cases

- **App killed**: 5-min repeating notifications continue (OS-managed). When user opens app → `_loadData()` checks if still overdue → keeps or cancels reminder.
- **Multiple overdue pills**: Each gets its own reminder notification (different ID).
- **Snooze while app open**: The background handler still fires. Main app `_loadData()` will reconcile state on next refresh.
- **Device reboot**: Existing `ScheduledNotificationBootReceiver` restores main daily notifications. Repeating notifications may need re-scheduling on next app open (handled by `_loadData()`).
