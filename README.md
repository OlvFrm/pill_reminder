# Medication Tracker — architecture scaffold

This is a source-code scaffold, not a runnable build — I don't have Flutter/Dart
tooling or network access in this sandbox, so nothing here has been compiled
or `pub get`'d. To get it running on your machine:

```bash
# 1. Create a real Flutter project shell (gives you android/, ios/, etc.)
flutter create medication_tracker_app
cd medication_tracker_app

# 2. Replace the generated pubspec.yaml and lib/ with the ones from this scaffold

# 3. Fetch packages
flutter pub get

# 4. Generate Drift's app_database.g.dart (referenced by a `part` directive
#    in lib/core/database/app_database.dart but not included here)
dart run build_runner build --delete-conflicting-outputs

# 5. Run
flutter run
```

## What's implemented vs. stubbed

- **Fully wired**: domain models, Drift schema, both repositories, the
  missed-dose sweep + 14-day horizon top-up (`DoseSchedulingService`),
  notification scheduling + action-button handling, all Riverpod providers,
  and working (if visually plain) screens for both tabs.
- **Stubbed / TODO**: the "add manual dose" dialog in `schedule_screen.dart`
  is a placeholder — the comment shows exactly how to call
  `doseRepositoryProvider.addManualDose(...)` once you build the actual
  medication-picker + time-picker UI. The adherence percentage was
  explicitly left out per your call above; `medication_history_screen.dart`
  has a comment marking where it'd plug in.
- **Android notification permissions**: you'll need to request exact-alarm
  and notification permissions at runtime on newer Android versions — not
  included here since it's platform config, not architecture.

## Where things live, if you're re-orienting

- `lib/core/` — cross-feature infrastructure (database, notifications, a
  Flutter-free `ScheduledTime` value type).
- `lib/features/medications/` and `lib/features/doses/` — each split into
  `domain/` (plain models), `data/` (repository interface + Drift impl),
  `application/` (Riverpod providers + services), `presentation/` (widgets).
- Dependency direction is one-way: `doses` may import from `medications`,
  never the reverse.
