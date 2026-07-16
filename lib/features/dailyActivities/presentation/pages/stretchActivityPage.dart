import 'package:flutter/material.dart';

class StretchActivityPage extends StatefulWidget {
  const StretchActivityPage({super.key});

  @override
  State<StretchActivityPage> createState() => _StretchActivityPage();
}

class _StretchActivityPage extends State<StretchActivityPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Text("hi")
          ],
        ),
      ),
    );
  }
}