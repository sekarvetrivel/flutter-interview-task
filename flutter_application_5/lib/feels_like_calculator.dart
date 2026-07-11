import 'dart:math' as math;

/// Pure function: given temperature (Celsius), wind speed (kph), and
/// humidity (%), returns the "feels like" temperature in Celsius.
///
/// This has ZERO Flutter dependencies (no BuildContext, no widgets, no
/// imports from package:flutter) which is exactly what makes it unit
/// testable with plain `dart test` / `flutter_test` with no widget pumping
/// required — see test/feels_like_test.dart.
///
/// Uses wind chill when it's cold and windy, heat index when it's hot and
/// humid, and falls back to the raw air temperature otherwise (matching
/// the thresholds used by the original implementation).
double calculateFeelsLike({
  required double temperatureC,
  required double windSpeedKph,
  required double humidityPercent,
}) {
  final bool isWindChillRange = temperatureC <= 10 && windSpeedKph > 4.8;
  final bool isHeatIndexRange = temperatureC >= 27 && humidityPercent >= 40;

  if (isWindChillRange) {
    return _windChill(temperatureC, windSpeedKph);
  }
  if (isHeatIndexRange) {
    return _heatIndex(temperatureC, humidityPercent);
  }
  return temperatureC;
}

double _windChill(double t, double v) {
  final vExp = math.pow(v, 0.16);
  return 13.12 + 0.6215 * t - 11.37 * vExp + 0.3965 * t * vExp;
}

double _heatIndex(double t, double h) {
  return -8.78469475556 +
      1.61139411 * t +
      2.33854883889 * h -
      0.14611605 * t * h -
      0.012308094 * t * t -
      0.0164248277778 * h * h +
      0.002211732 * t * t * h +
      0.00072546 * t * h * h -
      0.000003582 * t * t * h * h;
}
