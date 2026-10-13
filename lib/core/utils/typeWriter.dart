import 'dart:async';
import 'package:flutter/material.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration wordDelay;
  final VoidCallback? onTick;
  final VoidCallback? onFinished;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.wordDelay = const Duration(milliseconds: 60),
    this.onTick,
    this.onFinished,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  late final List<String> _words;
  Timer? _timer;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(' ');

    _timer = Timer.periodic(widget.wordDelay, (timer) {
      if (_count >= _words.length) {
        timer.cancel();
        widget.onFinished?.call();
        return;
      }
      setState(() => _count++);
      widget.onTick?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _words.take(_count).join(' '),
      style: widget.style,
    );
  }
}