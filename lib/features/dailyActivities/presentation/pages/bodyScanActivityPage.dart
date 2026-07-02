import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellmate/core/theme/colors.dart';
import 'package:wellmate/core/theme/textStyles.dart';
import 'package:wellmate/core/widgets/ButtonCom.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/activityProvider.dart';

class BodyScanActivityPage extends StatefulWidget {
  const BodyScanActivityPage({super.key});

  @override
  State<BodyScanActivityPage> createState() => _BodyScanActivityPageState();
}

enum _BodyPartId { head, neck, shoulders, chest, arms, abdomen, hips, legs, feet }

class _BodyPart {
  final _BodyPartId id;
  final IconData icon;
  final double xFrac;
  final double yFrac;

  const _BodyPart({
    required this.id,
    required this.icon,
    required this.xFrac,
    required this.yFrac,
  });
}

class _BodyScanActivityPageState extends State<BodyScanActivityPage>
    with SingleTickerProviderStateMixin {
  static const double _assetWidth = 516;
  static const double _assetHeight = 1589;
  static const double _assetAspect = _assetWidth / _assetHeight;

  var firstPerformDone = false;

  _BodyPartId? _selectedId;
  bool _showAction = false;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  static const List<_BodyPart> _bodyParts = [
    _BodyPart(id: _BodyPartId.head, icon: Icons.face_outlined, xFrac: 0.497, yFrac: 0.063),
    _BodyPart(id: _BodyPartId.neck, icon: Icons.height, xFrac: 0.5, yFrac: 0.140),
    _BodyPart(id: _BodyPartId.shoulders, icon: Icons.accessibility_new, xFrac: 0.19, yFrac: 0.176),
    _BodyPart(id: _BodyPartId.chest, icon: Icons.favorite_border, xFrac: 0.5, yFrac: 0.26),
    _BodyPart(id: _BodyPartId.arms, icon: Icons.fitness_center, xFrac: 0.93, yFrac: 0.500),
    _BodyPart(id: _BodyPartId.abdomen, icon: Icons.circle_outlined, xFrac: 0.5, yFrac: 0.44),
    _BodyPart(id: _BodyPartId.hips, icon: Icons.expand, xFrac: 0.3, yFrac: 0.60),
    _BodyPart(id: _BodyPartId.legs, icon: Icons.directions_walk, xFrac: 0.5, yFrac: 0.755),
    _BodyPart(id: _BodyPartId.feet, icon: Icons.directions_walk, xFrac: 0.5, yFrac: 0.97),
  ];

  _BodyPart? get _selectedPart =>
      _selectedId == null ? null : _bodyParts.firstWhere((p) => p.id == _selectedId);

  String _labelFor(_BodyPartId id, AppLocalizations loc) {
    switch (id) {
      case _BodyPartId.head:
        return loc.bodyPartHead;
      case _BodyPartId.neck:
        return loc.bodyPartNeck;
      case _BodyPartId.shoulders:
        return loc.bodyPartShoulders;
      case _BodyPartId.chest:
        return loc.bodyPartChest;
      case _BodyPartId.arms:
        return loc.bodyPartArms;
      case _BodyPartId.abdomen:
        return loc.bodyPartAbdomen;
      case _BodyPartId.hips:
        return loc.bodyPartHips;
      case _BodyPartId.legs:
        return loc.bodyPartLegs;
      case _BodyPartId.feet:
        return loc.bodyPartFeet;
    }
  }

  String _feedbackFor(_BodyPartId id, AppLocalizations loc) {
    switch (id) {
      case _BodyPartId.head:
        return loc.bodyScanHeadFeedback;
      case _BodyPartId.neck:
        return loc.bodyScanNeckFeedback;
      case _BodyPartId.shoulders:
        return loc.bodyScanShouldersFeedback;
      case _BodyPartId.chest:
        return loc.bodyScanChestFeedback;
      case _BodyPartId.arms:
        return loc.bodyScanArmsFeedback;
      case _BodyPartId.abdomen:
        return loc.bodyScanAbdomenFeedback;
      case _BodyPartId.hips:
        return loc.bodyScanBackFeedback;
      case _BodyPartId.legs:
      case _BodyPartId.feet:
        return loc.bodyScanLegsFeedback;
    }
  }

  String _actionFor(_BodyPartId id, AppLocalizations loc) {
    switch (id) {
      case _BodyPartId.head:
        return loc.bodyScanHeadAction;
      case _BodyPartId.neck:
        return loc.bodyScanNeckAction;
      case _BodyPartId.shoulders:
        return loc.bodyScanShouldersAction;
      case _BodyPartId.chest:
        return loc.bodyScanChestAction;
      case _BodyPartId.arms:
        return loc.bodyScanArmsAction;
      case _BodyPartId.abdomen:
        return loc.bodyScanAbdomenAction;
      case _BodyPartId.hips:
        return loc.bodyScanBackAction;
      case _BodyPartId.legs:
      case _BodyPartId.feet:
        return loc.bodyScanLegsAction;
    }
  }

  void _select(_BodyPart part) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedId == part.id) {
        _selectedId = null;
        _showAction = false;
      } else {
        _selectedId = part.id;
        _showAction = false;
      }
    });
  }

  void _onDoThis() {
    HapticFeedback.lightImpact();
    setState(() => _showAction = true);
  }

  void _onGotIt() {
    setState(() {
      _selectedId = null;
      _showAction = false;
    });

    if(!firstPerformDone) {
      context.read<ActivityProvider>().saveActivityLog(
        activityId: 5,
        value: '',
      );

      firstPerformDone = true;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            firstPerformDone ? context.pop("activity completed") : context.pop("");
          },
        ),
        title: Text(
          loc.bodyScanActivity,
          style: AppTextStyles.semiBold(locale).copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Column(
                children: [
                  SizedBox(height: height * 0.015),
                  Text(
                    loc.bodyScanInstruction,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.semiBold(locale).copyWith(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        double targetH = bodyConstraints.maxHeight;
                        double targetW = targetH * _assetAspect;
                        if (targetW > bodyConstraints.maxWidth) {
                          targetW = bodyConstraints.maxWidth;
                          targetH = targetW / _assetAspect;
                        }

                        return Center(
                          child: SizedBox(
                            width: targetW,
                            height: targetH,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    "assets/images/body_front.png",
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) => Center(
                                      child: Text(
                                        "Add body_front.png to assets/images/",
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.semiBold(locale)
                                            .copyWith(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                for (final part in _bodyParts)
                                  Positioned(
                                    left: part.xFrac * targetW - 18,
                                    top: part.yFrac * targetH - 18,
                                    child: GestureDetector(
                                      onTap: () => _select(part),
                                      behavior: HitTestBehavior.opaque,
                                      child: SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, _) {
                                            final isSelected = _selectedId == part.id;
                                            final pulse = isSelected
                                                ? (0.85 + _pulseController.value * 0.3)
                                                : 1.0;

                                            return Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                if (isSelected)
                                                  Transform.scale(
                                                    scale: pulse,
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: AppColors.primary.withOpacity(0.25),
                                                      ),
                                                    ),
                                                  ),
                                                Container(
                                                  width: isSelected ? 20 : 14,
                                                  height: isSelected ? 20 : 14,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected ? AppColors.primary : Colors.white,
                                                    border: Border.all(color: AppColors.primary, width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withOpacity(0.15),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: height * 0.02),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _selectedPart == null
                        ? const SizedBox(key: ValueKey('empty'), height: 0)
                        : Container(
                      key: ValueKey('${_selectedPart!.id}_$_showAction'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: Icon(_selectedPart!.icon, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _labelFor(_selectedPart!.id, loc),
                                  style: AppTextStyles.semiBold(locale).copyWith(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _feedbackFor(_selectedPart!.id, loc),
                            style: AppTextStyles.semiBold(locale).copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!_showAction)
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(text: loc.doThis, onPressed: _onDoThis),
                            )
                          else ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.self_improvement, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _actionFor(_selectedPart!.id, loc),
                                      style: AppTextStyles.semiBold(locale).copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(text: loc.gotIt, onPressed: _onGotIt),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.02),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}