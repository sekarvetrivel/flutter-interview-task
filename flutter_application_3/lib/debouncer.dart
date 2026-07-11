import 'dart:async';

/// A tiny, framework-free debouncer. Kept in its own class (rather than
/// inlined as a Timer in the widget) so it's independently unit-testable
/// and reusable across any other search/filter field in the app.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 300)});

  final Duration duration;
  Timer? _timer;

  /// Cancels any pending call and schedules [action] to run after
  /// [duration] of no further calls to [run].
  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}
