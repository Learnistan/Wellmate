import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import '../../../../core/theme/textStyles.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/activityProvider.dart';

enum Valence { unpleasant, neutral, pleasant }

enum Arousal { deactivated, neutral, activated }

class MoodCalibration extends StatefulWidget {
  const MoodCalibration({super.key});

  @override
  State<MoodCalibration> createState() => _MoodCalibrationState();
}

class _MoodCalibrationState extends State<MoodCalibration> {
  Valence? _valence;
  Arousal? _arousal;
  final TextEditingController _noteController = TextEditingController();
  late final loc = AppLocalizations.of(context)!;

  bool get _canLog => _valence != null && _arousal != null;

  /// Maps the (valence, arousal) pair to a feeling label from the
  /// circumplex model of affect, plus a few related words.
  ({String primary, String related})? get _feeling {
    if (_valence == null || _arousal == null) return null;

    switch ((_valence!, _arousal!)) {
    // Unpleasant
      case (Valence.unpleasant, Arousal.activated):
        return (primary: loc.moodCalibrationTense, related: loc.moodCalibrationTenseRelated);
      case (Valence.unpleasant, Arousal.neutral):
        return (primary: loc.moodCalibrationSad, related: loc.moodCalibrationSadRelated);
      case (Valence.unpleasant, Arousal.deactivated):
        return (primary: loc.moodCalibrationTired, related: loc.moodCalibrationTiredRelated);

    // Neutral
      case (Valence.neutral, Arousal.activated):
        return (primary: loc.moodCalibrationAlert, related: loc.moodCalibrationAlertRelated);
      case (Valence.neutral, Arousal.neutral):
        return (primary: loc.moodCalibrationOkay, related: loc.moodCalibrationOkayRelated);
      case (Valence.neutral, Arousal.deactivated):
        return (primary: loc.moodCalibrationQuiet, related: loc.moodCalibrationQuietRelated);

    // Pleasant
      case (Valence.pleasant, Arousal.activated):
        return (primary: loc.moodCalibrationExcited, related: loc.moodCalibrationExcitedRelated);
      case (Valence.pleasant, Arousal.neutral):
        return (primary: loc.moodCalibrationHappy, related: loc.moodCalibrationHappyRelated);
      case (Valence.pleasant, Arousal.deactivated):
        return (primary: loc.moodCalibrationCalm, related: loc.moodCalibrationCalmRelated);
    }
  }

  Future<void> _logMood(AppLocalizations loc) async {
    final feeling = _feeling;
    if (feeling == null) return;

    final note = _noteController.text.trim();

    context.read<ActivityProvider>().saveActivityLog(
      activityId: 5,
      value:
      '{"valence":"${_valence!.name}","arousal":"${_arousal!.name}",'
          '"feeling":"${feeling.primary}","note":"${note.replaceAll('"', "'")}"}',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.moodCalibrationDialogTitle),
        content: Text(loc.moodCalibrationDialogMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop("activity completed");
            },
            child: Text(loc.dialogActionButtonTitle),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          loc.moodCalibrationTitle,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                loc.moodCalibrationSubTitle,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: AppColors.appGray.withOpacity(0.4), height: 1),
              const SizedBox(height: 28),

              // ---- Valence ----
              _QuestionLabel(loc.moodCalibrationQuestion1),
              const SizedBox(height: 16),
              _OptionRow<Valence>(
                options: [
                  (Valence.unpleasant, loc.moodCalibrationUnpleasant),
                  (Valence.neutral, loc.moodCalibrationNeutral),
                  (Valence.pleasant, loc.moodCalibrationPleasant),
                ],
                selected: _valence,
                onSelected: (v) => setState(() => _valence = v),
              ),

              const SizedBox(height: 28),

              // ---- Arousal ----
              _QuestionLabel(loc.moodCalibrationQuestion2),
              const SizedBox(height: 16),
              _OptionRow<Arousal>(
                options: [
                  (Arousal.deactivated, loc.moodCalibrationDeactivated),
                  (Arousal.neutral, loc.moodCalibrationNeutral),
                  (Arousal.activated, loc.moodCalibrationActivated),
                ],
                selected: _arousal,
                onSelected: (a) => setState(() => _arousal = a),
              ),

              const SizedBox(height: 28),

              // ---- Feeling card ----
              _FeelingCard(feeling: _feeling, locale: locale, loc: loc,),

              const SizedBox(height: 28),

              // ---- Note ----
              Text(
                loc.moodCalibrationAddNote,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: TextStyle(color: AppColors.appGray),
                decoration: InputDecoration(
                  hintText: loc.moodCalibrationNoteHint,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: AppColors.appGray.withOpacity(0.12),
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.appGray.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ---- Log button ----
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_canLog) {
                      _logMood(loc);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.3),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    loc.moodCalibrationLogMood,
                    style: AppTextStyles.semiBold(locale)
                        .copyWith(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionLabel extends StatelessWidget {
  final String text;
  const _QuestionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.title.copyWith(color: AppColors.darkLabel)
    );
  }
}

/// A row of 3 mutually-exclusive pill options bound to an enum value [T].
class _OptionRow<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T? selected;
  final ValueChanged<T> onSelected;

  const _OptionRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          Expanded(
            child: _OptionPill(
              label: options[i].$2,
              selected: selected == options[i].$1,
              onTap: () => onSelected(options[i].$1),
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _OptionPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.18)
                : AppColors.appGray.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.appGray.withOpacity(0.5),
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeelingCard extends StatelessWidget {
  final ({String primary, String related})? feeling;
  final Locale locale;
  final AppLocalizations loc;

  const _FeelingCard({required this.feeling, required this.locale, required this.loc});

  @override
  Widget build(BuildContext context) {
    final hasFeeling = feeling != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.appGray.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.moodCalibrationFeelingMessage,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasFeeling ? feeling!.primary : loc.moodCalibrationSelectLbl,
            style: AppTextStyles.semiBold(locale).copyWith(
              fontSize: 22,
              color: hasFeeling ? AppColors.primary : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFeeling
                ? feeling!.related
                : loc.moodCalibrationPickMoodLbl,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}