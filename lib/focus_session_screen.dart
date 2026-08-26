import 'package:flutter/material.dart';

class FocusSessionScreen extends StatefulWidget {
  final Duration sessionDuration;

  const FocusSessionScreen({super.key, required this.sessionDuration});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> with SingleTickerProviderStateMixin {

  late Duration sessionDuration;

  @override
  void initState() {
    super.initState();

    sessionDuration = widget.sessionDuration;
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Text("Duration: ${sessionDuration.inMinutes}"),
        ],
      )
    );
  }
}