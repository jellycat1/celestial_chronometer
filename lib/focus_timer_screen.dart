import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';

enum TimerStatus { idle, running, paused, broken }

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late final AppLifecycleListener _lifecycleListener;

  TimerStatus _status = TimerStatus.idle;
  int _secondsElapsed = 0;
  Timer? _timer;


  @override
  void initState() {
    super.initState();

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
    });

    WakelockPlus.enable();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _breakSystem() {
    _timer?.cancel();
    WakelockPlus.disable();

    setState(() {
      _status = TimerStatus.broken;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    WakelockPlus.disable();
    setState(() {
      _status = TimerStatus.idle;
      _secondsElapsed = 0;
    });
  }

  void _toggleTimer() {
    if (_status == TimerStatus.paused) {
      // Resume
      setState(() {
        _status = TimerStatus.running;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _secondsElapsed++;
        });
      });

    } else if (_status == TimerStatus.running) {
      // Pause
      _timer?.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Text(
                "STATUS: ${_status == TimerStatus.broken ? "BROKEN" : _status == TimerStatus.idle ? "IDLE" : _status == TimerStatus.paused ? "PAUSED" : "RUNNING"}"
              ),
              Text(
                "Seconds: ${_secondsElapsed}",
              ),
              ElevatedButton(
                onPressed: _status == TimerStatus.idle ? _startTimer : _toggleTimer,
                child: Text(
                  _status == TimerStatus.running ? "PAUSE" : _status == TimerStatus.idle ? "START" : "RESUME",
                ),
              ),
              ElevatedButton(
                onPressed: _resetTimer,
                child: Text(
                  "Reset Session"
                )
              )
            ]
          ),
        ),
      ),
    );
  }
}