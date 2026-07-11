import 'dart:convert';
import 'package:http/http.dart' as http;

/// Plain data holder for the raw values the API gives us. No Flutter
/// imports — safe to use from the repository, the screen, and tests alike.
class WeatherReading {
  const WeatherReading({
    required this.temperatureC,
    required this.windSpeedKph,
    required this.humidityPercent,
  });

  final double temperatureC;
  final double windSpeedKph;
  final double humidityPercent;

  factory WeatherReading.fromJson(Map<String, dynamic> json) {
    return WeatherReading(
      temperatureC: (json['temp_c'] as num).toDouble(),
      windSpeedKph: (json['wind_kph'] as num).toDouble(),
      humidityPercent: (json['humidity'] as num).toDouble(),
    );
  }
}

/// ARCHITECTURAL DECISION: All network/data-fetching concerns live here,
/// completely separate from the widget. This means:
/// - The widget doesn't know or care whether the data came from HTTP, a
///   cache, or a fake in a test — it just awaits `fetchCurrentWeather()`.
/// - We can swap in a fake/mock repository in widget tests without ever
///   touching a real network call.
class WeatherRepository {
  WeatherRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.example-weather.com/current';

  Future<WeatherReading> fetchCurrentWeather(String city) async {
    final response =
        await _client.get(Uri.parse('$_baseUrl?city=${Uri.encodeComponent(city)}'));

    if (response.statusCode != 200) {
      throw WeatherFetchException(
        'Weather service returned ${response.statusCode}',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return WeatherReading.fromJson(data);
    } catch (e) {
      throw WeatherFetchException('Malformed weather response: $e');
    }
  }
}

class WeatherFetchException implements Exception {
  WeatherFetchException(this.message);
  final String message;

  @override
  String toString() => message;
}
