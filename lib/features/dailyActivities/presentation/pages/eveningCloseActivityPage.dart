import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';
import '../../../../l10n/app_localizations.dart';

class EveningCloseActivityPage extends StatefulWidget {
  const EveningCloseActivityPage({super.key});

  @override
  State<EveningCloseActivityPage> createState() => _EveningCloseActivityPageState();
}

class _EveningCloseActivityPageState extends State<EveningCloseActivityPage> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("evening close activity")
          ],
        ),
      ),
    );
  }
}