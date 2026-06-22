import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepCounterScreen extends StatefulWidget {
  const StepCounterScreen({super.key});

  @override
  State<StepCounterScreen> createState() => _StepCounterScreenState();
}

class _StepCounterScreenState extends State<StepCounterScreen> {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  int _sessionSteps = 0;
  int _baselineSteps = 0;
  bool _initialized = false;
  String _pedestrianStatus = 'unknown';
  String? _error;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _error = null;
      _listening = true;
      _initialized = false;
      _sessionSteps = 0;
      _baselineSteps = 0;
    });

    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Izin Activity Recognition diperlukan untuk menghitung langkah. '
              'Silakan aktifkan di pengaturan aplikasi.';
          _listening = false;
        });
        return;
      }
    }

    _stepSub?.cancel();
    _statusSub?.cancel();

    _stepSub = Pedometer.stepCountStream.listen(
      (event) {
        if (!_initialized) {
          _baselineSteps = event.steps;
          _initialized = true;
        }
        setState(() => _sessionSteps = event.steps - _baselineSteps);
      },
      onError: (e) => setState(() {
        _error = 'Sensor pedometer tidak tersedia di perangkat ini.';
        _listening = false;
      }),
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (event) => setState(() => _pedestrianStatus = event.status),
      onError: (_) {},
    );
  }

  void _resetCounter() {
    setState(() {
      _baselineSteps += _sessionSteps;
      _sessionSteps = 0;
    });
  }

  String _statusLabel() {
    switch (_pedestrianStatus) {
      case 'walking':
        return 'Sedang berjalan';
      case 'running':
        return 'Sedang berlari';
      case 'stopped':
        return 'Berhenti';
      default:
        return 'Menunggu sensor...';
    }
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Step Counter'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _pedestrianStatus == 'walking' ||
                                  _pedestrianStatus == 'running'
                              ? Icons.directions_walk
                              : Icons.accessibility_new,
                          size: 16,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E3A9F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_sessionSteps',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'STEPS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Goyangkan atau jalan dengan ponsel untuk menghitung langkah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _resetCounter,
                child: const Text(
                  'Reset Counter',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (!_listening || _error != null)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _startListening,
                  child: const Text(
                    'Mulai Sensor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
