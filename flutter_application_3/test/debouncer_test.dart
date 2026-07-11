import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_3/debouncer.dart';

// Uses package:fake_async (dev dependency) to control time deterministically
// instead of relying on real Timer delays in a test, which would make the
// test slow and flaky.
void main() {
  test('only the last call within the debounce window fires', () {
    fakeAsync((async) {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 300));
      var callCount = 0;
      var lastValue = '';

      void trigger(String value) {
        debouncer.run(() {
          callCount++;
          lastValue = value;
        });
      }

      trigger('a');
      async.elapse(const Duration(milliseconds: 100));
      trigger('ab');
      async.elapse(const Duration(milliseconds: 100));
      trigger('abc'); // resets the timer again
      async.elapse(const Duration(milliseconds: 300));

      expect(callCount, 1);
      expect(lastValue, 'abc');

      debouncer.dispose();
    });
  });

  test('two calls spaced further apart than duration both fire', () {
    fakeAsync((async) {
      final debouncer = Debouncer(duration: const Duration(milliseconds: 300));
      var callCount = 0;

      debouncer.run(() => callCount++);
      async.elapse(const Duration(milliseconds: 400));
      debouncer.run(() => callCount++);
      async.elapse(const Duration(milliseconds: 400));

      expect(callCount, 2);
      debouncer.dispose();
    });
  });
}
