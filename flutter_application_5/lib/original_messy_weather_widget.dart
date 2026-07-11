// ORIGINAL "GIVEN" CODE — this is the messy starting point handed to the
// candidate for Task 5. It is intentionally NOT good code: fetching,
// business logic (feels-like calculation), and UI are all tangled together
// inside one StatefulWidget's build()/State. Kept here, unmodified, for
// reference/diffing against the refactor.

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key, required this.city});
  final String city;

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  double? temperature;
  double? windSpeed;
  double? humidity;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAndCalculate();
  }

  Future<void> fetchAndCalculate() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await http.get(Uri.parse(
          'https://api.example-weather.com/current?city=${widget.city}'));
      final data = jsonDecode(res.body);
      temperature = (data['temp_c'] as num).toDouble();
      windSpeed = (data['wind_kph'] as num).toDouble();
      humidity = (data['humidity'] as num).toDouble();
      loading = false;
    } catch (e) {
      error = 'Failed to load weather';
      loading = false;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text(error!));
    }

    // "Feels like" business logic jammed directly into build().
    double feelsLike = temperature!;
    if (temperature! <= 10 && windSpeed! > 4.8) {
      feelsLike = 13.12 +
          0.6215 * temperature! -
          11.37 * math.pow(windSpeed!, 0.16) +
          0.3965 * temperature! * math.pow(windSpeed!, 0.16);
    } else if (temperature! >= 27 && humidity! >= 40) {
      feelsLike = -8.78469475556 +
          1.61139411 * temperature! +
          2.33854883889 * humidity! -
          0.14611605 * temperature! * humidity! -
          0.012308094 * temperature! * temperature! -
          0.0164248277778 * humidity! * humidity! +
          0.002211732 * temperature! * temperature! * humidity! +
          0.00072546 * temperature! * humidity! * humidity! -
          0.000003582 *
              temperature! *
              temperature! *
              humidity! *
              humidity!;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(widget.city, style: const TextStyle(fontSize: 24)),
          Text('${temperature!.toStringAsFixed(1)}°C'),
          Text('Feels like ${feelsLike.toStringAsFixed(1)}°C'),
          Text('Wind: ${windSpeed!.toStringAsFixed(1)} kph'),
          Text('Humidity: ${humidity!.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}

