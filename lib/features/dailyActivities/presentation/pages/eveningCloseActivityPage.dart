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
  State<EveningCloseActivityPage> createState() =>
      _EveningCloseActivityPageState();
}

class _EveningCloseActivityPageState extends State<EveningCloseActivityPage> {
  static const int _stepCount = 3;
  int _currentStep = 0;

  // Step 1 — three wins
  final TextEditingController _win1Controller = TextEditingController();
  final TextEditingController _win2Controller = TextEditingController();
  final TextEditingController _win3Controller = TextEditingController();

  // Step 2 — one challenge, one lesson
  final TextEditingController _challengeController = TextEditingController();
  final TextEditingController _lessonController = TextEditingController();

  // Step 3 — overall wellbeing
  int? _ratingValue;
  bool _received = false;

  bool get _win1Filled => _win1Controller.text.trim().isNotEmpty;
  bool get _win2Filled => _win2Controller.text.trim().isNotEmpty;
  bool get _win3Filled => _win3Controller.text.trim().isNotEmpty;
  bool get _step1Valid => _win1Filled && _win2Filled && _win3Filled;

  bool get _challengeFilled => _challengeController.text.trim().isNotEmpty;
  bool get _lessonFilled => _lessonController.text.trim().isNotEmpty;
  bool get _step2Valid => _challengeFilled && _lessonFilled;

  bool get _step3Valid => _ratingValue != null && _received;

  @override
  void initState() {
    super.initState();
    _win1Controller.addListener(() => setState(() {}));
    _win2Controller.addListener(() => setState(() {}));
    _win3Controller.addListener(() => setState(() {}));
    _challengeController.addListener(() => setState(() {}));
    _lessonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _win1Controller.dispose();
    _win2Controller.dispose();
    _win3Controller.dispose();
    _challengeController.dispose();
    _lessonController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_currentStep == 0) {
      context.pop("");
    } else {
      HapticFeedback.selectionClick();
      setState(() => _currentStep--);
    }
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    setState(() => _currentStep++);
  }

  void _onCloseDay() {
    HapticFeedback.lightImpact();

    final value =
        'win1: ${_win1Controller.text.trim()} | '
        'win2: ${_win2Controller.text.trim()} | '
        'win3: ${_win3Controller.text.trim()} | '
        'challenge: ${_challengeController.text.trim()} | '
        'lesson: ${_lessonController.text.trim()} | '
        'rating: $_ratingValue | '
        'received: $_received';
    debugPrint(value);

    context.pop("activity completed");
  }

  void _toggleReceived() {
    HapticFeedback.selectionClick();
    setState(() => _received = !_received);
  }

  void _selectRating(int value) {
    HapticFeedback.selectionClick();
    setState(() => _ratingValue = value);
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepCount, (index) {
        final isActiveOrDone = index <= _currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _stepCount - 1 ? 0 : 6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 6,
              decoration: BoxDecoration(
                color: isActiveOrDone
                    ? AppColors.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDot(bool filled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: filled ? 12 : 9,
      height: filled ? 12 : 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTextInput({
    required Locale locale,
    required double scale,
    required TextEditingController controller,
    required String hint,
    int minLines = 2,
    int maxLines = 3,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        style: AppTextStyles.semiBold(locale).copyWith(
          fontSize: 14 * scale,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 14 * scale,
            fontWeight: FontWeight.normal,
            color: Colors.grey.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStep1(AppLocalizations loc, Locale locale, double scale, double height) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.eveningCloseStep1Title,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 19 * scale),
        ),
        const SizedBox(height: 6),
        Text(
          loc.eveningCloseStep1Subtitle,
          style: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 13 * scale,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: height * 0.025),
        _buildTextInput(
          locale: locale,
          scale: scale,
          controller: _win1Controller,
          hint: loc.eveningCloseWin1Hint,
          minLines: 1,
          maxLines: 2,
        ),
        SizedBox(height: height * 0.015),
        _buildTextInput(
          locale: locale,
          scale: scale,
          controller: _win2Controller,
          hint: loc.eveningCloseWin2Hint,
          minLines: 1,
          maxLines: 2,
        ),
        SizedBox(height: height * 0.015),
        _buildTextInput(
          locale: locale,
          scale: scale,
          controller: _win3Controller,
          hint: loc.eveningCloseWin3Hint,
          minLines: 1,
          maxLines: 2,
        ),
        SizedBox(height: height * 0.03),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(_win1Filled),
              const SizedBox(width: 8),
              _buildDot(_win2Filled),
              const SizedBox(width: 8),
              _buildDot(_win3Filled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(AppLocalizations loc, Locale locale, double scale, double height) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.eveningCloseStep2Title,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 19 * scale),
        ),
        const SizedBox(height: 6),
        Text(
          loc.eveningCloseStep2Subtitle,
          style: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 13 * scale,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: height * 0.025),
        _buildTextInput(
          locale: locale,
          scale: scale,
          controller: _challengeController,
          hint: loc.eveningCloseChallengeHint,
          minLines: 3,
          maxLines: 5,
        ),
        SizedBox(height: height * 0.02),
        _buildTextInput(
          locale: locale,
          scale: scale,
          controller: _lessonController,
          hint: loc.eveningCloseLessonHint,
          minLines: 3,
          maxLines: 5,
        ),
        SizedBox(height: height * 0.03),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDot(_challengeFilled),
              const SizedBox(width: 8),
              _buildDot(_lessonFilled),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(AppLocalizations loc, Locale locale, double scale, double width, double height) {
    final circleSize = (width * 0.095).clamp(34.0, 46.0);

    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.eveningCloseStep3Title,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 19 * scale),
        ),
        SizedBox(height: height * 0.025),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: List.generate(10, (i) {
              final value = i + 1;
              final isSelected = _ratingValue == value;
              return GestureDetector(
                onTap: () => _selectRating(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$value',
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: 14 * scale,
                      color: isSelected ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: height * 0.035),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.self_improvement,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loc.eveningCloseCompassionTitle,
                      style: AppTextStyles.semiBold(locale)
                          .copyWith(fontSize: 16 * scale),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                loc.eveningCloseCompassionMessage,
                style: AppTextStyles.semiBold(locale).copyWith(
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.normal,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: InkWell(
                  onTap: _toggleReceived,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _received
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _received
                              ? loc.eveningCloseReceivedBtn
                              : loc.eveningCloseReceiveBtn,
                          style: AppTextStyles.semiBold(locale).copyWith(
                            fontSize: 14 * scale,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final mq = MediaQuery.of(context);
    final scale = (mq.size.width / 390).clamp(0.85, 1.25);
    final horizontalPadding = mq.size.width * 0.05;
    final height = mq.size.height;
    final width = mq.size.width;

    final bool isStepValid = switch (_currentStep) {
      0 => _step1Valid,
      1 => _step2Valid,
      _ => _step3Valid,
    };

    final bool isLastStep = _currentStep == _stepCount - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: _goBack,
        ),
        title: Text(
          loc.eveningCloseActivity,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20 * scale),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                4,
              ),
              child: _buildStepIndicator(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  height * 0.02,
                  horizontalPadding,
                  16,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: switch (_currentStep) {
                    0 => _buildStep1(loc, locale, scale, height),
                    1 => _buildStep2(loc, locale, scale, height),
                    _ => _buildStep3(loc, locale, scale, width, height),
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: isLastStep ? loc.closeDay : loc.next,
                  onPressed: isStepValid
                      ? (isLastStep ? _onCloseDay : _onNext)
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}