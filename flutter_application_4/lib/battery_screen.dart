import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ARCHITECTURAL DECISION: The channel is wrapped in its own tiny
/// `BatteryChannel` class rather than calling `MethodChannel` directly
/// inside the widget. This keeps the platform-boundary code in one place,
/// makes it mockable in widget tests (you can inject a fake via
/// `TestDefaultBinaryMessengerBinding` against this exact channel name), and
/// keeps `BatteryScreen` itself only responsible for displaying state.
class BatteryChannel {
  BatteryChannel._();

  // Channel + method names must match exactly on the native side.
  // See android/MainActivity.kt / ios/AppDelegate.swift.
  static const _channel = MethodChannel('com.example/battery');

  /// Returns the battery level 0-100. Throws a [PlatformException] if the
  /// native side can't determine it (e.g. unsupported device/emulator, or a
  /// missing permission), and a generic [Exception] for anything else
  /// (channel not implemented on this platform, etc).
  static Future<int> getBatteryLevel() async {
    final level = await _channel.invokeMethod<int>('getBatteryLevel');
    if (level == null) {
      throw Exception('Native side returned null battery level');
    }
    return level;
  }
}

class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  int? _batteryLevel;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBatteryLevel();
  }

  Future<void> _fetchBatteryLevel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final level = await BatteryChannel.getBatteryLevel();
      if (!mounted) return;
      setState(() {
        _batteryLevel = level;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      // Handled explicitly per the task requirement: never let a
      // PlatformException crash the app — show a fallback UI instead.
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Couldn\'t read battery level (${e.code}).';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Level')),
      body: Center(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_errorMessage != null) {
      // Fallback UI instead of a crash/blank screen.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.battery_unknown, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchBatteryLevel,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _batteryIcon(_batteryLevel!),
          size: 48,
          color: _batteryLevel! < 20 ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 12),
        Text('$_batteryLevel%', style: const TextStyle(fontSize: 24)),
        TextButton(onPressed: _fetchBatteryLevel, child: const Text('Refresh')),
      ],
    );
  }

  IconData _batteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 50) return Icons.battery_5_bar;
    if (level >= 20) return Icons.battery_3_bar;
    return Icons.battery_alert;
  }
}
