import 'package:celestial_chronometer/models/planet_data.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:flutter/scheduler.dart';

import 'celestial_painter.dart';

enum TimerStatus { idle, running, paused, broken }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with SingleTickerProviderStateMixin {
  late final AppLifecycleListener _lifecycleListener;
  late Ticker _ticker;

  TimerStatus _status = TimerStatus.idle;
  int _secondsElapsed = 0;
  double _pausedOffset = 0;
  double _elapsedMilliseconds = 0;
  Timer? _timer;


  final List<PlanetData> planets = const [
    PlanetData(
      orbitRadius: 50,
      planetRadius: 4,
      color: Colors.cyan,
      speedMultiplier: 1.7,
    ),
    PlanetData(
      orbitRadius: 90,
      planetRadius: 4,
      color: Colors.cyan,
      speedMultiplier: 1.3,
    ),
    PlanetData(
      orbitRadius: 130,
      planetRadius: 4,
      color: Colors.cyan,
      speedMultiplier: 0.9,
    ),
    PlanetData(
      orbitRadius: 170,
      planetRadius: 4,
      color: Colors.cyan,
      speedMultiplier: 0.5,
    ),
  ];


  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedMilliseconds = _pausedOffset + elapsed.inMilliseconds.toDouble();
      });
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppBackgrounded,
      onInactive: _onAppBackgrounded,
      onHide: _onAppBackgrounded,
    );
  }

  void _onAppBackgrounded() {
    if (_status == TimerStatus.running) {
      _breakSystem();
    }
  }

  void _startTimer() {
    setState(() {
      _status = TimerStatus.running;
      _secondsElapsed = 0;
      _pausedOffset = 0.0;
      _elapsedMilliseconds = 0.0;
    });

    WakelockPlus.enable();
    _ticker.start();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _breakSystem() {
    _timer?.cancel();
    _ticker.stop();
    WakelockPlus.disable();

    setState(() {
      _status = TimerStatus.broken;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _ticker.stop();
    WakelockPlus.disable();

    setState(() {
      _status = TimerStatus.idle;
      _secondsElapsed = 0;
      _pausedOffset = 0.0;
      _elapsedMilliseconds = 0.0;
    });
  }

  void _toggleTimer() {
    if (_status == TimerStatus.paused) {
      // Resume
      setState(() {
        _status = TimerStatus.running;
      });
      _ticker.start();
      WakelockPlus.enable();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });
    } else if (_status == TimerStatus.running) {
      // Pause
      _timer?.cancel();
      _ticker.stop();
      _pausedOffset = _elapsedMilliseconds; // Save exact position
      WakelockPlus.disable();

      setState(() {
        _status = TimerStatus.paused;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycleListener.dispose();
    WakelockPlus.disable();
    super.dispose();
    _ticker.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: CelestialPainter(
                  elapsedMilliseconds: _elapsedMilliseconds,
                  planets: planets
                )
              )
            )
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Center(
              child: Column(
                children: [
                  // Text(
                  //   "STATUS: ${_status == TimerStatus.broken ? "BROKEN" : _status == TimerStatus.idle ? "IDLE" : _status == TimerStatus.paused ? "PAUSED" : "RUNNING"}"
                  // ),
                  Text(
                    // "Seconds: ${_secondsElapsed}",
                    "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 80,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.cyan,
                          offset: Offset(0, 0), // (0,0) keeps the glow perfectly centered
                        ),
                      ]
                    )
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
                      ElevatedButton(
                        onPressed: _status == TimerStatus.idle || _status == TimerStatus.broken ? _startTimer : _toggleTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          shadowColor: Colors.cyan.withValues(alpha: 0.5),
                          elevation: 2,
                        ),
                        child: Text(
                          _status == TimerStatus.running ? "PAUSE" : _status == TimerStatus.idle || _status == TimerStatus.broken ? "START" : "RESUME",
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _resetTimer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          shadowColor: Colors.cyan.withValues(alpha: 0.5),
                          elevation: 2,
                        ),
                        child: Text(
                          "RESET"
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}