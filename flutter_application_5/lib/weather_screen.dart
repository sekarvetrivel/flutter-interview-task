import 'package:flutter/material.dart';
import 'feels_like_calculator.dart';
import 'weather_repository.dart';

/// The three states this screen can be in — makes `build()` a simple
/// switch instead of a tangle of nullable-field checks.
sealed class WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherError extends WeatherState {
  WeatherError(this.message);
  final String message;
}

class WeatherLoaded extends WeatherState {
  WeatherLoaded({required this.reading, required this.feelsLike});
  final WeatherReading reading;
  final double feelsLike;
}

/// REFACTORED WIDGET.
///
/// Compare to `original_messy_weather_widget.dart`: this widget no longer
/// knows HOW to fetch weather (that's `WeatherRepository`'s job) or HOW to
/// compute "feels like" (that's `calculateFeelsLike`'s job, a pure
/// function). It only holds a `WeatherState` and renders it — loading,
/// error, or loaded. That's the entire responsibility of `build()` now.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    super.key,
    required this.city,
    WeatherRepository? repository,
  }) : _repository = repository;

  final String city;
  // Allows injecting a fake repository in widget tests; defaults to a real
  // one otherwise.
  final WeatherRepository? _repository;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final WeatherRepository _repository =
      widget._repository ?? WeatherRepository();

  WeatherState _state = WeatherLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = WeatherLoading());
    try {
      final reading = await _repository.fetchCurrentWeather(widget.city);
      final feelsLike = calculateFeelsLike(
        temperatureC: reading.temperatureC,
        windSpeedKph: reading.windSpeedKph,
        humidityPercent: reading.humidityPercent,
      );
      if (!mounted) return;
      setState(() {
        _state = WeatherLoaded(reading: reading, feelsLike: feelsLike);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = WeatherError('Failed to load weather: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;

    return switch (state) {
      WeatherLoading() => const Center(child: CircularProgressIndicator()),
      WeatherError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      WeatherLoaded(:final reading, :final feelsLike) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(widget.city, style: const TextStyle(fontSize: 24)),
              Text('${reading.temperatureC.toStringAsFixed(1)}°C'),
              Text('Feels like ${feelsLike.toStringAsFixed(1)}°C'),
              Text('Wind: ${reading.windSpeedKph.toStringAsFixed(1)} kph'),
              Text(
                'Humidity: ${reading.humidityPercent.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ),
    };
  }
}
