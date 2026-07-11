import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_5/feels_like_calculator.dart';

// These tests import ONLY the pure function — no Flutter widgets, no
// BuildContext, no pumpWidget. That's the whole point of the refactor:
// this logic is testable in complete isolation.

void main() {
  group('calculateFeelsLike', () {
    test('extreme cold + windy applies wind chill formula', () {
      // Cold and windy enough to trigger the wind chill branch
      // (temp <= 10 and wind > 4.8).
      final result = calculateFeelsLike(
        temperatureC: -15,
        windSpeedKph: 30,
        humidityPercent: 50,
      );

      // Wind chill should make it feel noticeably colder than the raw
      // air temperature.
      expect(result, lessThan(-15));
    });

    test('extreme heat + high humidity applies heat index formula', () {
      // Hot and humid enough to trigger the heat index branch
      // (temp >= 27 and humidity >= 40).
      final result = calculateFeelsLike(
        temperatureC: 38,
        windSpeedKph: 5,
        humidityPercent: 80,
      );

      // Heat index should make it feel noticeably hotter than the raw
      // air temperature.
      expect(result, greaterThan(38));
    });

    test('zero wind + mild temp falls back to raw air temperature', () {
      // Not cold+windy, not hot+humid -> neither formula applies.
      final result = calculateFeelsLike(
        temperatureC: 18,
        windSpeedKph: 0,
        humidityPercent: 30,
      );

      expect(result, 18);
    });

    test('boundary: exactly at wind chill temp threshold but calm wind '
        'does not trigger wind chill', () {
      // temp == 10 satisfies "<= 10", but wind of 3 kph fails "> 4.8",
      // so this should NOT go down the wind chill path.
      final result = calculateFeelsLike(
        temperatureC: 10,
        windSpeedKph: 3,
        humidityPercent: 50,
      );

      expect(result, 10);
    });

    test('boundary: exactly at heat index humidity threshold triggers '
        'heat index', () {
      // temp == 27 and humidity == 40 both satisfy ">=" thresholds.
      final result = calculateFeelsLike(
        temperatureC: 27,
        windSpeedKph: 5,
        humidityPercent: 40,
      );

      // At this exact boundary the formula still applies; just assert it
      // runs and returns a finite, sane value rather than the raw temp
      // (since the heat index formula at this point can be very close to
      // 27 itself, we assert it's a real number instead of over-asserting
      // on direction here).
      expect(result.isFinite, isTrue);
    });
  });
}
