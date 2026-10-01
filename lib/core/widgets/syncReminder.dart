
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/syncProvider.dart';

class SyncReminder extends StatelessWidget {
  const SyncReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUnsynced = context.watch<SyncProvider>().hasUnsynced;
    if (!hasUnsynced) return const SizedBox.shrink();

    final loc = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 20, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your data is not backed up yet. Connect to the internet to sync it.",
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}