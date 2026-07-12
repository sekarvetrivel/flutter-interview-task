# Flutter Interview Tasks — Solutions

One self-contained Flutter app per task, as requested. Each has its own
`pubspec.yaml` so it can be run independently.

- `flutter_application_1/` (Task 1 — Expandable Card) — `lib/expandable_card.dart`
  + `lib/main.dart` (demo usage)
- `flutter_application_2/` (Task 2 — Shopping Cart) — `lib/models/`,
  `lib/cart_logic/`, `lib/screens/`, `test/`, `lib/main.dart`.
  **State management: Provider** (`ChangeNotifier` + `context.select`) —
  justification is in the doc comment at the top of
  `lib/cart_logic/cart_model.dart`.
- `flutter_application_3/` (Task 3 — Paginated Search) —
  `lib/paginated_search_screen.dart`, `lib/debouncer.dart` (standalone,
  unit-testable), `test/debouncer_test.dart`
- `flutter_application_4/` (Task 4 — Platform Channel: Battery) —
  `lib/battery_screen.dart`,
  `android/app/src/main/kotlin/.../MainActivity.kt`,
  `ios/Runner/AppDelegate.swift`, `README.md`
- `flutter_application_5/` (Task 5 — Refactor Weather) —
  `lib/original_messy_weather_widget.dart` (the "given" messy code), plus
  the refactor: `lib/feels_like_calculator.dart` (pure function),
  `lib/weather_repository.dart` (data layer), `lib/weather_screen.dart`
  (dumb display widget), `test/feels_like_test.dart`
- `bonus_answers.md` — written answers + code snippets for the 3 hard
  bonus questions

## Running any task's tests

Each task folder is a full Flutter app and runs on its own, e.g.:

```bash
cd flutter_application_2
flutter pub get
flutter test
```

## Notes / things I'd flag in a real review

- Task 3 and Task 5 assume the given API base URLs are illustrative;
  `weather_repository.dart` and `paginated_search_screen.dart` inject an
  `http.Client` where sensible so tests can substitute a fake client
  instead of hitting the network.
- Task 3's `debouncer_test.dart` uses `package:fake_async` so the 300ms
  window is tested deterministically rather than with real `Duration`
  delays.
- Task 4 includes both Android and iOS native implementations for
  completeness, even though the task only required one; `README.md`
  inside that folder explains exactly what's needed to support both from
  a single Dart codebase.