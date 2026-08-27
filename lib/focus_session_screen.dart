import 'package:flutter/material.dart';

class FocusSessionScreen extends StatefulWidget {
  final Duration sessionDuration;

  const FocusSessionScreen({super.key, required this.sessionDuration});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> with SingleTickerProviderStateMixin {

  late Duration sessionDuration;
  late int _sessionSecondsLeft;

  int _secondsElapsed = 0;


  @override
  void initState() {
    super.initState();

    sessionDuration = widget.sessionDuration;
    _sessionSecondsLeft = sessionDuration.inSeconds;
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Text("Duration: ${sessionDuration.inMinutes}"),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Column(
              children: [
                Text(
                  "${(_sessionSecondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_sessionSecondsLeft % 60).toString().padLeft(2, '0')}",
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
                        onPressed: () {},
                      )
                    ),
                    SizedBox(
                      height: 45,
                      child: StyledButton(
                        content: "ABANDON SESSION",
                        onPressed: () {},
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