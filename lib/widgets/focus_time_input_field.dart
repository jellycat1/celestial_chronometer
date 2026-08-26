import 'package:celestial_chronometer/services/time_shift_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FocusTimeInputField extends StatefulWidget {
  final ValueChanged<Duration> onDurationChanged;

  const FocusTimeInputField({super.key, required this.onDurationChanged});

  @override
  State<FocusTimeInputField> createState() => _FocusTimeInputFieldState();
}

class _FocusTimeInputFieldState extends State<FocusTimeInputField> {
  final TextEditingController _controller = TextEditingController(text: '00:25:00');

  void _onChanged(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '').padLeft(6, '0');
    final hours = int.parse(digits.substring(0, 2));
    final minutes = int.parse(digits.substring(2, 4));
    final seconds = int.parse(digits.substring(4, 6));

    final duration = Duration(hours: hours, minutes: minutes, seconds: seconds);
    widget.onDurationChanged(duration);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal:  16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withValues(alpha: 0.4), width: 1.5),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.cyanAccent,
          letterSpacing: 2,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          TimeShiftInputFormatter(),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '00:00:00',
          hintStyle: TextStyle(color: Colors.white24),
        ),
        onChanged: _onChanged,
      )
    );
  }
}