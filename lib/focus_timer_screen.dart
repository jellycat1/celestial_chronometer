import 'package:celestial_chronometer/models/planet_data.dart';
import 'package:celestial_chronometer/focus_session_screen.dart';
import 'package:celestial_chronometer/widgets/focus_time_input_field.dart';
import 'package:celestial_chronometer/focus_session_screen.dart';

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
  double _rotationX = 0.5;
  double _rotationY = 0.5;

  Duration _selectedDuration = Duration.zero;

  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;


  final List<PlanetData> planets = const [
    // PlanetData(
    //   orbitRadius: 50,
    //   planetRadius: 4,
    //   color: Color(0xFFFFAA50),
    //   speedMultiplier: 1.7,
    // ),
    // PlanetData(
    //   orbitRadius: 90,
    //   planetRadius: 4,
    //   color: Color(0xFF70FFE0),
    //   speedMultiplier: 1.3,
    // ),
    // PlanetData(
    //   orbitRadius: 130,
    //   planetRadius: 4,
    //   color: Color(0xFFFF6878),
    //   speedMultiplier: 0.9,
    // ),
    // PlanetData(
    //   orbitRadius: 170,
    //   planetRadius: 4,
    //   color: Color(0xFF9898FF),
    //   speedMultiplier: 0.5,
    // ),
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

    _startTimer();
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
    _ticker.dispose();
    super.dispose();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
  }
  
  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount >= 2) {
        // Pan:
        _scale = (_baseScale * details.scale).clamp(0.5, 3.0);
        _offset += details.focalPointDelta;
      } else {
        _rotationY += details.focalPointDelta.dx * 0.01;
        _rotationX += details.focalPointDelta.dy * 0.01;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..translate(_offset.dx, _offset.dy)
                    ..scale(_scale),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: Size(400, 400),
                      painter: CelestialPainter(
                        elapsedMilliseconds: _elapsedMilliseconds,
                        planets: planets,
                        rotationX: _rotationX,
                        rotationY: _rotationY,
                      )
                    )
                  ),
                ),
              ),
            )
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Center(
              child: Column(
                children: [

                  Center(
                    child: FocusTimeInputField(
                      onDurationChanged: (duration) {
                        _selectedDuration = duration;
                      }
                    )
                  ),

                  // Text(
                  //   "STATUS: ${_status == TimerStatus.broken ? "BROKEN" : _status == TimerStatus.idle ? "IDLE" : _status == TimerStatus.paused ? "PAUSED" : "RUNNING"}"
                  // ),
                  // Text(
                  //   "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                  //   style: const TextStyle(
                  //     fontSize: 80,
                  //     shadows: [
                  //       Shadow(
                  //         blurRadius: 13.0,
                  //         color: Colors.cyan,
                  //         offset: Offset(0, 0), // (0,0) keeps the glow perfectly centered
                  //       ),
                  //     ]
                  //   )
                  // ),
                  // Text(
                  //   "${(_selectedDuration.inHours % 60).toString().padLeft(2, '0')}:${(_selectedDuration.inMinutes % 60).toString().padLeft(2, '0')}:00",
                  //   style: const TextStyle(
                  //     fontSize: 80,
                  //     shadows: [
                  //       Shadow(
                  //         blurRadius: 13.0,
                  //         color: Colors.cyan,
                  //         offset: Offset(0, 0),
                  //       ),
                  //     ]
                  //   )
                  // ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
                      SizedBox(
                        height: 45,
                        child: StyledButton(
                          content: "NEW FOCUS SESSION",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FocusSessionScreen(sessionDuration: _selectedDuration,),
                              ),
                            );
                          }
                        ),
                      ),
                  //     SizedBox(
                  //       height: 40,
                  //       child: ElevatedButton(
                  //         onPressed: _status == TimerStatus.idle || _status == TimerStatus.broken ? _startTimer : _toggleTimer,
                  //         style: ElevatedButton.styleFrom(
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(12.0)
                  //           ),
                  //           backgroundColor: Colors.black.withValues(alpha: 0.5),
                  //           shadowColor: Colors.cyan.withValues(alpha: 0.5),
                  //           elevation: 2,
                  //         ),
                  //         child: Text(
                  //           _status == TimerStatus.running ? "PAUSE" : _status == TimerStatus.idle || _status == TimerStatus.broken ? "START" : "RESUME",
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       height: 40,
                  //       child: ElevatedButton(
                  //         onPressed: _resetTimer,
                  //         style: ElevatedButton.styleFrom(
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(12.0),
                  //           ),
                  //           backgroundColor: Colors.black.withValues(alpha: 0.5),
                  //           shadowColor: Colors.cyan.withValues(alpha: 0.5),
                  //           elevation: 2,
                  //         ),
                  //         child: Text(
                  //           "RESET"
                  //         ),
                  //       ),
                  //     ),
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