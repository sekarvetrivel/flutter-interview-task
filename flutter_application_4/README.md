# Task 4 — Battery Level Platform Channel

## Channel contract
- Channel name: `com.example/battery`
- Method: `getBatteryLevel` (no arguments)
- Success: returns an `Int` 0-100
- Failure: native side calls `result.error(...)` / `FlutterError`, which
  Flutter surfaces as a `PlatformException`. Error code used: `UNAVAILABLE`.

## Files
- `battery_screen.dart` — Dart side. `BatteryChannel` wraps the
  `MethodChannel` call; `BatteryScreen` is a `StatefulWidget` that shows a
  loading indicator, the battery %, or a fallback "couldn't read battery"
  UI with a retry button if a `PlatformException` (or any other error) is
  thrown.
- `android/MainActivity.kt` — Kotlin implementation. Reads the real value
  via `BatteryManager.BATTERY_PROPERTY_CAPACITY`, with a fallback to the
  sticky `ACTION_BATTERY_CHANGED` broadcast for devices where that
  property isn't populated.
- `ios/AppDelegate.swift` — Swift implementation for the same contract,
  included for completeness/reference (task allowed choosing one
  platform; Android was the primary target here).

## What would change to support both platforms from one codebase
The Dart code needs **zero** changes — it already just calls a
platform-agnostic channel/method name and handles success/error uniformly.
What's needed is purely native, and both native implementations are
already included above so this is effectively done, but to spell it out:

1. Register the exact same channel name (`com.example/battery`) and method
   name (`getBatteryLevel`) in both `MainActivity.kt` (Android) and
   `AppDelegate.swift` (iOS).
2. Return the value in the same shape on both platforms — an `Int` 0-100.
   iOS's `UIDevice.current.batteryLevel` is a `Float` 0.0-1.0, so it must
   be converted (`Int(batteryLevel * 100)`) to match Android's already-int
   percentage.
3. Map each platform's "can't read battery" case to the same error code
   (`UNAVAILABLE`) so `battery_screen.dart`'s single `on PlatformException`
   handler works unmodified on both platforms — no `Platform.isIOS`
   branching needed in the Dart layer at all.
4. iOS specifically requires `isBatteryMonitoringEnabled = true` before
   `batteryLevel` returns a real value; without it (or on most simulators)
   `batteryState` is `.unknown` and `batteryLevel` returns `-1`, which is
   exactly the case mapped to the `UNAVAILABLE` error above.
