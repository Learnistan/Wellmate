import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';
import '../../../../l10n/app_localizations.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _focusController = TextEditingController();
  final TextEditingController _mindfulController = TextEditingController();
  final TextEditingController _careController = TextEditingController();

  bool get _focusFilled => _focusController.text.trim().isNotEmpty;
  bool get _mindfulFilled => _mindfulController.text.trim().isNotEmpty;
  bool get _careFilled => _careController.text.trim().isNotEmpty;

  bool get _allFilled => _focusFilled && _mindfulFilled && _careFilled;

  @override
  void initState() {
    super.initState();
    _focusController.addListener(() => setState(() {}));
    _mindfulController.addListener(() => setState(() {}));
    _careController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusController.dispose();
    _mindfulController.dispose();
    _careController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_allFilled) return;

    HapticFeedback.lightImpact();

    final value =
        'focus: ${_focusController.text.trim()} | '
        'mindful: ${_mindfulController.text.trim()} | '
        'care: ${_careController.text.trim()}';

    debugPrint(value);

    context.pop("activity completed");
  }

  Widget _buildQuestionBlock({
    required Locale locale,
    required double scale,
    required String title,
    required String hint,
    required TextEditingController controller,
    required String inputHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 17 * scale),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: AppTextStyles.semiBold(locale).copyWith(
            fontSize: 13 * scale,
            fontWeight: FontWeight.normal,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            style: AppTextStyles.semiBold(locale).copyWith(
              fontSize: 14 * scale,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: inputHint,
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
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final mq = MediaQuery.of(context);
    final scale = (mq.size.width / 390).clamp(0.85, 1.25);
    final horizontalPadding = mq.size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(""),
        ),
        title: Text(
          loc.morningIntentionsActivity,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20 * scale),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  mq.size.height * 0.015,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.morningIntentionsInstruction,
                      textAlign: TextAlign.start,
                      style: AppTextStyles.semiBold(locale).copyWith(
                        fontSize: 15 * scale,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: mq.size.height * 0.03),

                    _buildQuestionBlock(
                      locale: locale,
                      scale: scale,
                      title: loc.morningIntentionsFocusTitle,
                      hint: loc.morningIntentionsFocusHint,
                      controller: _focusController,
                      inputHint: loc.morningIntentionsFocusInputHint,
                    ),

                    SizedBox(height: mq.size.height * 0.03),

                    _buildQuestionBlock(
                      locale: locale,
                      scale: scale,
                      title: loc.morningIntentionsMindfulTitle,
                      hint: loc.morningIntentionsMindfulHint,
                      controller: _mindfulController,
                      inputHint: loc.morningIntentionsMindfulInputHint,
                    ),

                    SizedBox(height: mq.size.height * 0.03),

                    _buildQuestionBlock(
                      locale: locale,
                      scale: scale,
                      title: loc.morningIntentionsCareTitle,
                      hint: loc.morningIntentionsCareHint,
                      controller: _careController,
                      inputHint: loc.morningIntentionsCareInputHint,
                    ),

                    SizedBox(height: mq.size.height * 0.03),

                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildDot(_focusFilled),
                          const SizedBox(width: 8),
                          _buildDot(_mindfulFilled),
                          const SizedBox(width: 8),
                          _buildDot(_careFilled),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: loc.submit,
                  onPressed: _allFilled ? _onSubmit : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}