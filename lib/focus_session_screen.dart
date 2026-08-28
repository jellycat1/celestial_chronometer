import 'package:celestial_chronometer/focus_session_painter.dart';
import 'package:celestial_chronometer/models/focus_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

class FocusSessionScreen extends StatefulWidget {
  final Duration sessionDuration;

  const FocusSessionScreen({super.key, required this.sessionDuration});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

enum TimerStatus { idle, running, paused, broken }

class _FocusSessionScreenState extends State<FocusSessionScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  late final AppLifecycleListener _lifecycleListener;
  late Duration sessionDuration;
  late FocusSession _session;

  double _elapsedMilliseconds = 0;
  Timer? _timer;
  TimerStatus _status = TimerStatus.idle;

  double _rotationX = 0.5;
  double _rotationY = 0.5;

  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _offset = Offset.zero;

  @override
  void initState() {
    super.initState();

    sessionDuration = widget.sessionDuration;

    _session = FocusSession(
      id: DateTime.now().toIso8601String(),
      targetDuration: sessionDuration,
      baseColor: const Color(0xFFFFAA50),
      ringColor: const Color(0xFF70FFE0),
      orbitRadius: 90,
    );

    _ticker = createTicker((elapsed) {
      setState(() {
        _elapsedMilliseconds = elapsed.inMilliseconds.toDouble();
        _session.updateProgress(Duration(milliseconds: elapsed.inMilliseconds));
      });
    });

    _lifecycleListener = AppLifecycleListener(
      onPause: _onAppBackgrounded,
      onInactive: _onAppBackgrounded,
      onHide: _onAppBackgrounded
    );
  }

  void _onAppBackgrounded() {
    if (_status == TimerStatus.running) {
      _breakSystem();
    }
  }

  void _breakSystem() {
    _timer?.cancel();
    _ticker.stop();
    WakelockPlus.disable();
    
    setState(() {
      _status = TimerStatus.broken;
    });
  }

  void _startTimer() {
    if (_status == TimerStatus.running) return;
    setState(() {
      _status = TimerStatus.running;
      _elapsedMilliseconds = 0.0;
    });

    WakelockPlus.enable();
    _ticker.start();

    _timer?.cancel();
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      if (details.pointerCount >= 2) {
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
    final remaining = _session.targetDuration - _session.elapsed;
    final secondsLeft = remaining.inSeconds.clamp(0, sessionDuration.inSeconds);

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
                      painter: FocusSessionPainter(
                        session: _session,
                        rotationX: _rotationX,
                        rotationY: _rotationY,
                        elapsedMilliseconds: _elapsedMilliseconds,
                      )
                    )
                  )
                )
              )
            )
          ),
          // Text("Duration: ${sessionDuration.inMinutes}"),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Column(
              children: [
                Text(
                  "${(secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(secondsLeft % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 80,
                    shadows: [
                      Shadow(
                        blurRadius: 13.0,
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
                    SizedBox(
                      height: 45,
                      child: StyledButton(
                        content: "START SESSION",
                        onPressed: _status == TimerStatus.idle ? _startTimer : null,
                      )
                    ),
                    SizedBox(
                      height: 45,
                      child: StyledButton(
                        content: "ABANDON SESSION",
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}

class StyledButton extends StatelessWidget {
  final String content;
  final VoidCallback? onPressed;

  const StyledButton({
    super.key,
    required this.content,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)
        ),
        shadowColor: Colors.cyan.withValues(alpha: 0.5),
        elevation: 2,
      ),
      child: Text(
        content,
        style: TextStyle(
          color: Colors.white,
    
        )
      )
    );
  }
}