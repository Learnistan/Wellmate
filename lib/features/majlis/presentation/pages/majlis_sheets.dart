import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/majlis_catalog.dart';
import '../../domain/majlis_models.dart';
import '../../l10n/majlis_strings.dart';
import '../../majlis_config.dart';
import '../../majlis_theme.dart';
import '../controllers/majlis_hallway_controller.dart';
import '../controllers/majlis_room_controller.dart';
import '../widgets/majlis_avatar.dart';
import '../widgets/majlis_bits.dart';
import '../widgets/majlis_portraits.dart';

// ---- Shared sheet frame ---------------------------------------------------

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder, {bool scroll = true}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => _SheetFrame(scroll: scroll, child: builder(ctx)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child, this.scroll = true});
  final Widget child;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.92),
      decoration: const BoxDecoration(
        color: MajlisColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 18 + mq.viewInsets.bottom + mq.padding.bottom),
      child: scroll ? SingleChildScrollView(child: _body(child)) : _body(Flexible(child: child)),
    );
  }

  Widget _body(Widget content) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 42,
            height: 5,
            decoration: BoxDecoration(color: const Color(0xFFE3D6CC), borderRadius: BorderRadius.circular(9)),
          ),
        ),
        const SizedBox(height: 14),
        content,
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.color = MajlisColors.roseDeep, this.icon, this.busy = false});
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null ? MajlisColors.muted : Colors.white;
    return FilledButton(
      onPressed: busy ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: busy ? color.withValues(alpha: 0.7) : const Color(0xFFE9DED7),
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
      ),
      child: busy
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
                Flexible(child: Text(label, style: MajlisText.body(16, color: fg, weight: FontWeight.w700))),
              ],
            ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.icon, required this.onTap, this.color = MajlisColors.ink});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: MajlisColors.line),
        backgroundColor: MajlisColors.paper,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label, style: MajlisText.body(14, color: color, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, required this.onTap, this.jewel = MajlisJewels.rose});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final MajlisJewel jewel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: MajlisColors.paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: jewel.light, shape: BoxShape.circle),
                  child: Icon(icon, size: 21, color: jewel.deep),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: MajlisText.body(15.5, weight: FontWeight.w700)),
                      if (subtitle != null) Text(subtitle!, style: MajlisText.body(12.5, color: MajlisColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: MajlisColors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(MajlisText.caps(text), style: MajlisText.eyebrow()),
    );

Widget _pill(String label, bool on, VoidCallback tap, {IconData? icon, Color? iconColor}) => GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsetsDirectional.fromSTEB(icon != null ? 11 : 14, 9, 14, 9),
        decoration: BoxDecoration(
          color: on ? MajlisColors.ink : MajlisColors.paper,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: on ? MajlisColors.ink : MajlisColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: on ? MajlisColors.gold : (iconColor ?? MajlisColors.muted)),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: MajlisText.body(14, color: on ? MajlisColors.cream : MajlisColors.ink, weight: FontWeight.w600, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );

Widget _switchRow(IconData icon, String title, String? subtitle, bool value, ValueChanged<bool> onChanged) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 21, color: MajlisColors.roseDeep),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: MajlisText.body(15, weight: FontWeight.w600)),
                if (subtitle != null) Text(subtitle, style: MajlisText.body(12.5, color: MajlisColors.muted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: MajlisColors.roseDeep,
            onChanged: onChanged,
          ),
        ],
      ),
    );

Widget _title(String text) => Text(text, style: MajlisText.head(26, spacing: -0.5));

Widget _sub(String text) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: MajlisText.body(14.5, color: MajlisColors.muted)),
    );

Widget _field(TextEditingController c, String hint, {int lines = 1, int? maxLength, TextStyle? style}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: MajlisColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MajlisColors.line),
      ),
      child: TextField(
        controller: c,
        maxLines: lines,
        minLines: 1,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        style: style ?? MajlisText.body(16, height: 1.45),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: (style ?? MajlisText.body(16)).copyWith(color: MajlisColors.faint),
        ),
      ),
    );

Widget _error(String? text) => text == null
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: MajlisJewels.pomegranate.deep),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: MajlisText.body(13.5, color: MajlisJewels.pomegranate.deep, weight: FontWeight.w600)),
            ),
          ],
        ),
      );

/// A gentle yes/no question.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String yes,
  required String no,
  bool danger = true,
}) async {
  final r = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (d) => AlertDialog(
      backgroundColor: MajlisColors.cream,
      title: Text(title, style: MajlisText.head(22)),
      content: Text(body, style: MajlisText.body(15, color: MajlisColors.muted)),
      actions: [
        TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(no, style: MajlisText.body(15, weight: FontWeight.w600))),
        TextButton(
          onPressed: () => Navigator.of(d).pop(true),
          child: Text(yes,
              style: MajlisText.body(15,
                  color: danger ? MajlisJewels.pomegranate.deep : MajlisColors.roseDeep, weight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return r == true;
}

// ---- 1. Welcome: your Majlis name (first visit) ---------------------------

Future<bool?> showVeilSheet(BuildContext context, MajlisHallway hall) {
  var draft = MajlisCatalog.randomVeil();
  var busy = false;
  String? error;
  return _sheet<bool>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(builder: (ctx, setState) {
      final me = MajlisPerson(id: hall.uid ?? '', veil: draft.veil, jewelIndex: draft.jewel, motif: draft.motif);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(MajlisText.caps(l.t('welcome')), textAlign: TextAlign.center, style: MajlisText.eyebrow(color: MajlisColors.roseText)),
          const SizedBox(height: 6),
          Text(l.t('inHereYouAre'), textAlign: TextAlign.center, style: MajlisText.body(15, color: MajlisColors.muted)),
          const SizedBox(height: 16),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: c),
              child: MajlisAvatar(key: ValueKey(draft), person: me, size: 112),
            ),
          ),
          const SizedBox(height: 14),
          Text(l.name(me), textAlign: TextAlign.center, style: MajlisText.head(32, spacing: -0.6)),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => draft = (veil: MajlisCatalog.randomName(not: draft.veil), jewel: draft.jewel, motif: draft.motif)),
              style: TextButton.styleFrom(foregroundColor: MajlisColors.roseDeep),
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: Text(l.t('anotherName'), style: MajlisText.body(14.5, color: MajlisColors.roseDeep, weight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
          PortraitPicker(
            motif: draft.motif,
            jewel: draft.jewel,
            onChanged: (m, j) => setState(() => draft = (veil: draft.veil, jewel: j, motif: m)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 8, 10),
            decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(22)),
            child: Column(
              children: [
                _promise(Icons.visibility_off_outlined, l.t('promiseNames')),
                _promise(Icons.lock_outline_rounded, l.t('promiseRecorded')),
                _promise(Icons.favorite_border_rounded, l.t('promiseKind')),
              ],
            ),
          ),
          _error(error),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: l.t('takeSeat'),
            busy: busy,
            onTap: () async {
              setState(() {
                busy = true;
                error = null;
              });
              try {
                await hall.saveVeil(draft.veil, draft.jewel, draft.motif);
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              } catch (e) {
                setState(() {
                  busy = false;
                  error = l.error('network');
                });
              }
            },
          ),
        ],
      );
    });
  });
}

/// Pick one of the illustrated pictures and a colour. Used when taking a
/// seat for the first time and from your profile.
class PortraitPicker extends StatelessWidget {
  const PortraitPicker({super.key, required this.motif, required this.jewel, required this.onChanged});
  final int motif;
  final int jewel;
  final void Function(int motif, int jewel) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = MajlisStrings.of(context);
    final picked = motif % MajlisCatalog.portraits;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(l.t('picture')),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MajlisCatalog.portraits,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final on = i == picked;
              return Semantics(
                button: true,
                selected: on,
                label: l.t('pictureN', {'n': i + 1}),
                child: GestureDetector(
                  onTap: () => onChanged(i, jewel),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: on ? MajlisColors.roseDeep : Colors.transparent, width: 2.5),
                    ),
                    child: ClipOval(
                      child: VeilPattern(person: MajlisPerson(id: '', veil: '', jewelIndex: jewel, motif: i)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        _label(l.t('colour')),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            for (var j = 0; j < MajlisJewels.all.length; j++)
              Semantics(
                button: true,
                selected: j == jewel % MajlisJewels.all.length,
                label: l.t('colourN', {'n': j + 1}),
                child: GestureDetector(
                  onTap: () => onChanged(picked, j),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: j == jewel % MajlisJewels.all.length ? MajlisColors.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_hex(MajlisPortraitArt.tones[j].$2), _hex(MajlisPortraitArt.tones[j].$1)],
                          stops: const [0.5, 0.5],
                        ),
                        border: Border.all(color: MajlisColors.line),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  static Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));
}

Future<void> showPictureSheet(BuildContext context, MajlisHallway hall) {
  final me = hall.me;
  if (me == null) return Future.value();
  var motif = me.motif, jewel = me.jewelIndex;
  var busy = false;
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: MajlisAvatar(
              key: ValueKey((motif, jewel)),
              person: me.copyWith(motif: motif, jewelIndex: jewel),
              size: 104,
            ),
          ),
          const SizedBox(height: 12),
          Text(l.name(me), textAlign: TextAlign.center, style: MajlisText.head(26, spacing: -0.5)),
          const SizedBox(height: 10),
          PortraitPicker(motif: motif, jewel: jewel, onChanged: (m, j) => setState(() => (motif, jewel) = (m, j))),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: l.t('save'),
            busy: busy,
            onTap: () async {
              setState(() => busy = true);
              try {
                await hall.saveVeil(me.veil, jewel, motif);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (_) {
                setState(() => busy = false);
              }
            },
          ),
        ],
      ),
    );
  });
}

Widget _promise(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: MajlisColors.roseDeep),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: MajlisText.body(15, weight: FontWeight.w500))),
        ],
      ),
    );

// ---- 2. Your profile -------------------------------------------------------

Future<void> showProfileSheet(BuildContext context, MajlisHallway hall) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return ListenableBuilder(
      listenable: hall,
      builder: (ctx, _) {
        final p = hall.profile;
        final me = hall.me;
        if (p == null || me == null) return const SizedBox(height: 200);
        Widget stat(IconData icon, String value, String label, MajlisJewel j) => Expanded(
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 10, 14),
                decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: j.light, shape: BoxShape.circle),
                      child: Icon(icon, size: 18, color: j.deep),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(value, style: MajlisText.head(20, height: 1.1)),
                          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: MajlisText.body(11.5, color: MajlisColors.muted, height: 1.2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: MajlisAvatar(key: ValueKey(me), person: me, size: 92),
              ),
            ),
            const SizedBox(height: 10),
            Text(l.name(me), textAlign: TextAlign.center, style: MajlisText.head(28, spacing: -0.5)),
            const SizedBox(height: 2),
            Text(l.t('yourName'), textAlign: TextAlign.center, style: MajlisText.body(13, color: MajlisColors.muted)),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => hall.saveVeil(MajlisCatalog.randomName(not: me.veil), me.jewelIndex, me.motif),
                  style: TextButton.styleFrom(foregroundColor: MajlisColors.roseDeep),
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: Text(l.t('changeName'), style: MajlisText.body(14, color: MajlisColors.roseDeep, weight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => showPictureSheet(ctx, hall),
                  style: TextButton.styleFrom(foregroundColor: MajlisColors.roseDeep),
                  icon: const Icon(Icons.face_retouching_natural_rounded, size: 18),
                  label: Text(l.t('changePicture'), style: MajlisText.body(14, color: MajlisColors.roseDeep, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Both tiles in a row keep the same height when a label wraps.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stat(Icons.groups_2_rounded, l.n(p.joined), l.t('statJoined'), MajlisJewels.lapis),
                  const SizedBox(width: 8),
                  stat(Icons.headphones_rounded, l.duration(p.minutes), l.t('statListening'), MajlisJewels.turquoise),
                ],
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  stat(Icons.local_cafe_rounded, l.n(p.tea), l.t('statTea'), MajlisJewels.saffron),
                  const SizedBox(width: 8),
                  stat(Icons.star_rounded, l.n(p.hosted), l.t('statHosted'), MajlisJewels.rose),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
              decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: [
                  _switchRow(
                    Icons.female_rounded,
                    l.t('womenSpaces'),
                    p.womenSpaces ? l.t('womenSpacesOn') : l.t('womenSpacesOff'),
                    p.womenSpaces,
                    hall.setWomenSpaces,
                  ),
                  if (p.blocked.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.block_rounded, size: 21, color: MajlisColors.roseDeep),
                        const SizedBox(width: 12),
                        Expanded(child: Text(l.count(p.blocked.length, 'blockedOne', 'blockedN'), style: MajlisText.body(15, weight: FontWeight.w600))),
                        TextButton(onPressed: hall.unblockAll, child: Text(l.t('unblockAll'))),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 15, color: MajlisColors.muted),
                const SizedBox(width: 6),
                Text(l.t('onlyYou'), style: MajlisText.body(12.5, color: MajlisColors.muted)),
              ],
            ),
            const SizedBox(height: 14),
            _PrimaryButton(label: l.t('done'), onTap: () => Navigator.of(ctx).pop()),
          ],
        );
      },
    );
  });
}

// ---- 3. Start or schedule a space ------------------------------------------

/// Creates the space. Returns its id, and the start time when it was scheduled.
Future<({String spaceId, DateTime? startsAt})?> showStartSpaceSheet(BuildContext context, MajlisHallway hall) {
  final title = TextEditingController();
  final question = TextEditingController();
  var topic = MajlisCatalog.chai;
  var lang = MajlisStrings.of(context).lang == 'en' ? 'en' : MajlisStrings.of(context).lang;
  var who = MajlisAudience.open;
  var later = false;
  var dayOffset = 0;
  var time = const TimeOfDay(hour: 21, minute: 0);
  var turns = false;
  var busy = false;
  String? error;
  const presets = [TimeOfDay(hour: 19, minute: 0), TimeOfDay(hour: 20, minute: 30), TimeOfDay(hour: 21, minute: 0)];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (now.hour >= 20) dayOffset = 1;

  return _sheet<({String spaceId, DateTime? startsAt})>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(builder: (ctx, setState) {
      final day = today.add(Duration(days: dayOffset));
      final when = DateTime(day.year, day.month, day.day, time.hour, time.minute);
      final tooSoon = later && when.isBefore(DateTime.now().add(const Duration(minutes: 10)));
      final ready = title.text.trim().length >= 3 && !tooSoon;

      Widget whoTile(MajlisAudience a, IconData icon, String label, String sub) {
        final on = who == a;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => who = a),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              // Grows with the phone's text size; the hint may take two lines.
              height: 40 + 62 * MajlisText.grow(context),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: on ? const Color(0xFFFBF1EE) : MajlisColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? MajlisColors.roseDeep : MajlisColors.line, width: on ? 2 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 24, color: on ? MajlisColors.roseDeep : MajlisColors.muted),
                  const SizedBox(height: 6),
                  Text(label, style: MajlisText.body(13.5, weight: FontWeight.w700)),
                  Text(sub,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MajlisText.body(10.5, color: MajlisColors.muted, height: 1.2)),
                ],
              ),
            ),
          ),
        );
      }

      Widget whenTab(String label, IconData icon, bool on, VoidCallback tap) => Expanded(
            child: GestureDetector(
              onTap: tap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 46,
                decoration: BoxDecoration(
                  color: on ? MajlisColors.paper : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: on
                      ? [BoxShadow(color: MajlisColors.plum.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: on ? MajlisColors.roseDeep : MajlisColors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: MajlisText.body(14.5, color: on ? MajlisColors.ink : MajlisColors.muted, weight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          );

      String dayLabel(int i) {
        final d = today.add(Duration(days: i));
        if (i == 0) return l.t('today');
        if (i == 1) return l.t('tomorrow');
        return '${l.weekday(d.weekday)} ${l.n(d.day)}';
      }

      Future<void> submit() async {
        setState(() {
          busy = true;
          error = null;
        });
        try {
          final q = question.text.trim();
          final r = await hall.repo.createSpace(
            title: title.text.trim(),
            topic: topic.id,
            lang: lang,
            audience: who,
            question: q.isEmpty ? null : q,
            turns: turns,
            startsAt: later ? when : null,
          );
          if (later) {
            await hall.remind(
              MajlisSpace(
                id: r.spaceId,
                title: title.text.trim(),
                topicId: topic.id,
                lang: lang,
                audience: who,
                hostUid: hall.uid ?? '',
                host: hall.me!,
                status: MajlisStatus.scheduled,
                scheduledFor: when,
              ),
              true,
              l,
            ).catchError((_) {});
          }
          if (ctx.mounted) Navigator.of(ctx).pop((spaceId: r.spaceId, startsAt: later ? when : null));
        } on MajlisException catch (e) {
          if (e.code == 'already-hosting' && e.spaceId != null && ctx.mounted) {
            Navigator.of(ctx).pop((spaceId: e.spaceId!, startsAt: null));
            return;
          }
          setState(() {
            busy = false;
            error = l.error(e.code);
          });
        } catch (_) {
          setState(() {
            busy = false;
            error = l.error('generic');
          });
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(l.t('startSpace')),
                  _sub(l.t('startSub')),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: MajlisColors.sand, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        whenTab(l.t('goLiveNow'), Icons.podcasts_rounded, !later, () => setState(() => later = false)),
                        whenTab(l.t('schedule'), Icons.event_rounded, later, () => setState(() => later = true)),
                      ],
                    ),
                  ),
                  if (later) ...[
                    const SizedBox(height: 14),
                    _label(l.t('day')),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => _pill(dayLabel(i), dayOffset == i, () => setState(() => dayOffset = i)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _label(l.t('time')),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in presets)
                          _pill(l.time(DateTime(2000, 1, 1, t.hour, t.minute)), time == t, () => setState(() => time = t)),
                        _pill(
                          presets.contains(time) ? l.t('otherTime') : l.time(DateTime(2000, 1, 1, time.hour, time.minute)),
                          !presets.contains(time),
                          () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: time,
                              builder: (c, child) => Theme(
                                data: Theme.of(c).copyWith(
                                  colorScheme: Theme.of(c).colorScheme.copyWith(primary: MajlisColors.roseDeep, secondary: MajlisColors.rose),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) setState(() => time = picked);
                          },
                          icon: Icons.schedule_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: tooSoon ? const Color(0xFFFFF0F0) : MajlisColors.goldSoft.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Icon(tooSoon ? Icons.info_outline_rounded : Icons.event_available_rounded,
                              size: 20, color: tooSoon ? MajlisJewels.pomegranate.deep : const Color(0xFF7A5418)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tooSoon ? l.t('tooSoon') : l.t('scheduledFor', {'when': l.when(when)}),
                              style: MajlisText.body(13.5, weight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _label(l.t('title')),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                    decoration: BoxDecoration(
                      color: MajlisColors.paper,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MajlisColors.line),
                    ),
                    child: TextField(
                      controller: title,
                      maxLines: 2,
                      minLines: 1,
                      maxLength: 90,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      style: MajlisText.head(20, height: 1.25),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: l.t('titleHint'),
                        hintStyle: MajlisText.head(19, color: MajlisColors.faint),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (key, ideaTopic) in MajlisCatalog.titleIdeas)
                        _pill(
                          l.t(key),
                          false,
                          () => setState(() {
                            title.text = l.t(key);
                            title.selection = TextSelection.collapsed(offset: title.text.length);
                            topic = ideaTopic;
                          }),
                          icon: ideaTopic.icon,
                          iconColor: ideaTopic.jewel.deep,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label(l.t('topicLabel')),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in MajlisCatalog.createTopics)
                        _pill(l.topic(t.id), topic.id == t.id, () => setState(() => topic = t), icon: t.icon, iconColor: t.jewel.deep),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label(l.t('language')),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final code in const ['fa', 'ps', 'en']) _pill(l.langName(code), lang == code, () => setState(() => lang = code)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label(l.t('whoCanJoin')),
                  Row(
                    children: [
                      whoTile(MajlisAudience.open, Icons.public_rounded, l.t('open'), l.t('openSub')),
                      const SizedBox(width: 8),
                      whoTile(MajlisAudience.women, Icons.female_rounded, l.t('women'), l.t('womenOnly')),
                      const SizedBox(width: 8),
                      whoTile(MajlisAudience.invite, Icons.lock_outline_rounded, l.t('invite'), l.t('inviteSub')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label(l.t('questionLabel')),
                  _field(question, l.t('questionHint'), maxLength: 200, style: MajlisText.body(15)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
                    decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(18)),
                    child: _switchRow(Icons.timer_outlined, l.t('takeTurns'), l.t('takeTurnsSub'), turns, (v) => setState(() => turns = v)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          _error(error),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _PrimaryButton(
              label: later ? l.t('scheduleSpace') : l.t('goLiveNow'),
              icon: later ? Icons.event_available_rounded : Icons.podcasts_rounded,
              busy: busy,
              onTap: ready ? submit : null,
            ),
          ),
        ],
      );
    });
  }, scroll: false);
}

// ---- 4. A scheduled space ---------------------------------------------------

enum EventAction { start, cancelled, shared }

Future<EventAction?> showEventSheet(BuildContext context, MajlisHallway hall, MajlisSpace e) {
  final j = MajlisCatalog.topic(e.topicId).jewel;
  final mine = hall.isMine(e);
  return _sheet<EventAction>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return ListenableBuilder(
      listenable: hall,
      builder: (ctx, _) {
        final s = hall.scheduled.where((x) => x.id == e.id).firstOrNull ?? e;
        final going = hall.going.contains(s.id);
        final when = s.scheduledFor ?? DateTime.now();
        void share() {
          final text = s.inviteCode != null
              ? hall.config.inviteMessage(l.t('inviteText', {'title': s.title, 'code': s.inviteCode!}), s.inviteCode!)
              : l.t('shareText', {'title': s.title, 'when': l.when(when)});
          Clipboard.setData(ClipboardData(text: text));
          Navigator.of(ctx).pop(EventAction.shared);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                MajlisChip(text: l.topic(s.topicId), icon: MajlisCatalog.topic(s.topicId).icon, bg: j.deep, fg: Colors.white),
                MajlisChip(text: l.langName(s.lang), border: MajlisColors.line),
                if (s.audience == MajlisAudience.women) MajlisChip(text: l.t('womenOnly'), icon: Icons.female_rounded, border: MajlisColors.line),
                if (s.audience == MajlisAudience.invite) MajlisChip(text: l.t('inviteOnly'), icon: Icons.lock_outline_rounded, border: MajlisColors.line),
                if (s.turns) MajlisChip(text: l.t('takeTurns'), icon: Icons.timer_outlined, border: MajlisColors.line),
              ],
            ),
            const SizedBox(height: 16),
            Text(MajlisText.caps(l.day(when)), style: MajlisText.eyebrow(color: j.deep)),
            const SizedBox(height: 4),
            Text(l.time(when), style: MajlisText.head(36, color: j.deep, spacing: -0.8)),
            const SizedBox(height: 6),
            Text(s.title, style: MajlisText.head(25, spacing: -0.4)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    children: [
                      MajlisAvatar(person: s.host, size: 44, host: true),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mine ? l.t('you') : l.name(s.host), style: MajlisText.body(15, weight: FontWeight.w700)),
                            Text(s.host.isGuide ? l.t('guideHosting') : l.t('hosting'), style: MajlisText.body(12.5, color: MajlisColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 22, color: MajlisColors.line),
                  Row(
                    children: [
                      const Icon(Icons.groups_2_rounded, color: MajlisColors.roseDeep, size: 22),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l.count(s.goingCount, 'goingOne', 'goingN'), style: MajlisText.body(14, weight: FontWeight.w600))),
                      if (going && !mine)
                        MajlisChip(
                          text: l.t('reminderOn'),
                          icon: Icons.notifications_active_rounded,
                          bg: MajlisColors.goldSoft,
                          fg: const Color(0xFF7A5418),
                          size: 11.5,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (s.question != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: MajlisColors.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: MajlisColors.gold),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin_rounded, size: 18, color: Color(0xFF8A6420)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s.question!, style: MajlisText.body(14.5, weight: FontWeight.w600))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (mine) ...[
              _PrimaryButton(label: l.t('startNow'), icon: Icons.podcasts_rounded, onTap: () => Navigator.of(ctx).pop(EventAction.start)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _SecondaryButton(label: l.t('shareInvite'), icon: Icons.ios_share_rounded, onTap: share)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      label: l.t('cancelSpace'),
                      icon: Icons.event_busy_rounded,
                      color: MajlisJewels.pomegranate.deep,
                      onTap: () async {
                        final yes = await showConfirm(ctx,
                            title: l.t('cancelQ'), body: l.t('cancelBody'), yes: l.t('cancelSpace'), no: l.t('keepIt'));
                        if (!yes || !ctx.mounted) return;
                        try {
                          await hall.repo.host(s.id, 'cancel');
                          await hall.config.reminders?.cancel(s.id);
                          if (ctx.mounted) Navigator.of(ctx).pop(EventAction.cancelled);
                        } catch (_) {}
                      },
                    ),
                  ),
                ],
              ),
            ] else ...[
              _PrimaryButton(
                label: going ? l.t('reminderOn') : l.t('remindMe'),
                icon: going ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                color: going ? MajlisColors.plum : MajlisColors.roseDeep,
                onTap: () => hall.remind(s, !going, l).catchError((_) {}),
              ),
              const SizedBox(height: 8),
              _SecondaryButton(label: l.t('share'), icon: Icons.ios_share_rounded, onTap: share),
            ],
          ],
        );
      },
    );
  });
}

// ---- 5. After you leave ----------------------------------------------------

/// Returns the feeling picked (0 Calm … 4 Sad), or null.
Future<int?> showAfterSheet(BuildContext context, MajlisLeaveResult r, MajlisConfig config, {bool journeyDone = false}) async {
  int? picked;
  await _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              MajlisText.caps(l.t(switch (r.reason) {
                _ when r.hosted => 'thanksHosting',
                null => 'leftQuietly',
                'endedByHost' => 'spaceEndedCaps',
                _ => 'afterVisitCaps',
              })),
              textAlign: TextAlign.center, style: MajlisText.eyebrow(color: MajlisColors.roseText)),
          const SizedBox(height: 6),
          Text(l.t('youSatFor', {'time': l.minutes(r.sat.inMinutes)}), textAlign: TextAlign.center, style: MajlisText.head(27, spacing: -0.5)),
          const SizedBox(height: 4),
          Text(l.t('staysHere'), textAlign: TextAlign.center, style: MajlisText.body(14, color: MajlisColors.muted)),
          const SizedBox(height: 18),
          if (r.teaReceived > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: MajlisColors.saffronSoft, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(color: MajlisColors.saffron, shape: BoxShape.circle),
                    child: const Icon(Icons.local_cafe_rounded, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.count(r.teaReceived, 'teaOne', 'teaMany'),
                            style: MajlisText.body(15, color: const Color(0xFF5E3A0E), weight: FontWeight.w700)),
                        Text(l.t('teaSub'), style: MajlisText.body(13, color: const Color(0xFF7A5418))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
            decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(24)),
            child: Column(
              children: [
                Text(l.t('howFeel'), style: MajlisText.head(18)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < 5; i++)
                      GestureDetector(
                        onTap: () {
                          setState(() => picked = i);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: picked == i ? const Color(0xFFFBF1EE) : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: picked == i ? MajlisColors.roseDeep : Colors.transparent, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              MoodFace(mood: i, size: 38, active: picked == i),
                              const SizedBox(height: 5),
                              Text(l.t('mood$i'), style: MajlisText.body(11.5, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: picked == null
                      ? const SizedBox(height: 4, width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(l.t('moodReply$picked'),
                              textAlign: TextAlign.center, style: MajlisText.body(14, color: MajlisColors.plum, weight: FontWeight.w500)),
                        ),
                ),
              ],
            ),
          ),
          if (journeyDone) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: MajlisColors.blush, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: MajlisColors.roseDeep),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.t('journeyDone'), style: MajlisText.body(14.5, weight: FontWeight.w600))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _PrimaryButton(label: l.t('backToHallway'), onTap: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  });
  return picked;
}

// ---- 6. Someone in the room -------------------------------------------------

Future<void> showPersonSheet(BuildContext context, MajlisRoomController c, MajlisPerson p) {
  final isMe = p.id == c.me.id;
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return ListenableBuilder(
      listenable: c,
      builder: (ctx, _) {
        final peer = c.stage.followedBy(c.listeners).where((x) => x.id == p.id).firstOrNull;
        final onStage = peer?.canSpeak ?? false;
        final isHost = c.hostUid == p.id;
        final role = p.isGuide
            ? (isHost ? l.t('guideHosting') : l.t('guide'))
            : isHost
                ? l.t('hosting')
                : onStage
                    ? l.t('onStage')
                    : l.t('listeningRole');
        final teaCount = c.tea[p.id] ?? 0;
        void close() => Navigator.of(ctx).pop();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: MajlisAvatar(person: p, size: 92, host: isHost, tea: isMe ? c.teaForMe : teaCount)),
            const SizedBox(height: 12),
            Text(isMe ? l.t('youName', {'name': l.name(p)}) : l.name(p),
                textAlign: TextAlign.center, style: MajlisText.head(27, spacing: -0.5)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p.isGuide) ...[const Icon(Icons.verified_rounded, size: 16, color: MajlisColors.gold), const SizedBox(width: 4)],
                Text(role, style: MajlisText.body(14, color: MajlisColors.muted, weight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 18),
            if (isMe) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const Icon(Icons.visibility_off_outlined, color: MajlisColors.roseDeep),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.t('nobodySeesName'), style: MajlisText.body(14.5, weight: FontWeight.w500))),
                  ],
                ),
              ),
              if (onStage && !c.isHost) ...[
                const SizedBox(height: 10),
                _PrimaryButton(
                  label: l.t('backToListening'),
                  icon: Icons.headphones_rounded,
                  onTap: () {
                    c.leaveStage();
                    close();
                  },
                ),
              ],
            ] else ...[
              _PrimaryButton(
                label: teaCount > 0 ? l.t('pourAnother') : l.t('pourTea'),
                icon: Icons.local_cafe_rounded,
                color: MajlisColors.saffron,
                onTap: () {
                  c.pourTea(p);
                  close();
                },
              ),
              const SizedBox(height: 6),
              Text(l.t('teaExplain'), textAlign: TextAlign.center, style: MajlisText.body(12.5, color: MajlisColors.muted)),
              const SizedBox(height: 14),
              if (c.isHost && !onStage)
                _Row(
                  icon: Icons.mic_rounded,
                  title: l.t('inviteToStage'),
                  onTap: () {
                    c.inviteToStage(p);
                    close();
                  },
                ),
              if (c.canModerate && onStage) ...[
                _Row(
                  icon: Icons.mic_off_rounded,
                  title: l.t('muteTheirMic'),
                  jewel: MajlisJewels.plum,
                  onTap: () {
                    c.muteSpeaker(p);
                    close();
                  },
                ),
                // The host always keeps a seat on the stage (the server refuses).
                if (c.hostUid != p.id)
                  _Row(
                    icon: Icons.headphones_rounded,
                    title: l.t('moveToListeners'),
                    jewel: MajlisJewels.lapis,
                    onTap: () {
                      c.moveToListeners(p);
                      close();
                    },
                  ),
              ],
              if (c.canModerate && c.hostUid != p.id)
                _Row(
                  icon: Icons.logout_rounded,
                  title: l.t('removeFromSpace'),
                  jewel: MajlisJewels.pomegranate,
                  onTap: () async {
                    final yes = await showConfirm(ctx,
                        title: l.t('removeQ', {'name': l.name(p)}), body: l.t('removeBody'), yes: l.t('remove'), no: l.t('cancel'));
                    if (yes) {
                      c.removePerson(p);
                      if (ctx.mounted) close();
                    }
                  },
                ),
              Row(
                children: [
                  _smallAction(
                    c.mutedForMe.contains(p.id) ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    c.mutedForMe.contains(p.id) ? l.t('unmuteForMe') : l.t('muteForMe'),
                    () {
                      c.toggleMuteForMe(p);
                      close();
                    },
                  ),
                  const SizedBox(width: 8),
                  _smallAction(Icons.flag_outlined, l.t('report'), () async {
                    final reason = await showReportSheet(ctx);
                    if (reason != null) {
                      c.report(p, reason);
                      if (ctx.mounted) close();
                    }
                  }),
                  const SizedBox(width: 8),
                  _smallAction(Icons.block_rounded, l.t('block'), () async {
                    final yes = await showConfirm(ctx,
                        title: l.t('blockQ', {'name': l.name(p)}), body: l.t('blockBody'), yes: l.t('block'), no: l.t('cancel'));
                    if (yes) {
                      c.block(p);
                      if (ctx.mounted) close();
                    }
                  }, color: MajlisJewels.pomegranate.deep),
                ],
              ),
            ],
          ],
        );
      },
    );
  });
}

Widget _smallAction(IconData icon, String label, VoidCallback onTap, {Color color = MajlisColors.ink}) => Expanded(
      child: Material(
        color: MajlisColors.paper,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: SizedBox(
            height: 78,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 6),
                Text(label, textAlign: TextAlign.center, style: MajlisText.body(12.5, color: color, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

/// Returns a report reason.
Future<String?> showReportSheet(BuildContext context) {
  return _sheet<String>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.t('reportTitle')),
        _sub(l.t('reportSub')),
        const SizedBox(height: 14),
        for (final r in MajlisCatalog.reportReasons)
          _Row(
            icon: switch (r) {
              'unsafe' => Icons.health_and_safety_rounded,
              'harassment' => Icons.report_rounded,
              'identity' => Icons.badge_outlined,
              'spam' => Icons.campaign_outlined,
              _ => Icons.more_horiz_rounded,
            },
            title: l.t('reason.$r'),
            jewel: r == 'unsafe' ? MajlisJewels.pomegranate : MajlisJewels.rose,
            onTap: () => Navigator.of(ctx).pop(r),
          ),
      ],
    );
  });
}

// ---- 7. Help ---------------------------------------------------------------

Future<void> showHelpSheet(BuildContext context, MajlisRoomController c, MajlisConfig config) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.t('notAlone')),
        _sub(l.t('stepOut')),
        const SizedBox(height: 16),
        if (config.onOpenChat != null)
          _Row(
            icon: Icons.chat_bubble_outline_rounded,
            title: l.t('talkToWellMate'),
            subtitle: l.t('talkToWellMateSub'),
            onTap: () {
              Navigator.of(ctx).pop();
              config.onOpenChat!(context);
            },
          ),
        if (!c.isHost)
          _Row(
            icon: Icons.mail_lock_rounded,
            title: l.t('writeToHost', {'name': l.name(c.host)}),
            subtitle: l.t('writeToHostSub'),
            jewel: MajlisJewels.plum,
            onTap: () {
              Navigator.of(ctx).pop();
              showWhisperSheet(context, c);
            },
          ),
        if (config.helplines.isNotEmpty)
          _Row(
            icon: Icons.phone_in_talk_rounded,
            title: l.t('helplines'),
            subtitle: l.t('helplinesSub'),
            jewel: MajlisJewels.pomegranate,
            onTap: () {
              Navigator.of(ctx).pop();
              _showHelplines(context, config.helplines);
            },
          ),
        _Row(
          icon: Icons.air_rounded,
          title: l.t('breatheMinute'),
          subtitle: l.t('breatheMinuteSub'),
          jewel: MajlisJewels.sage,
          onTap: () {
            Navigator.of(ctx).pop();
            c.startBreathing();
          },
        ),
      ],
    );
  });
}

Future<void> _showHelplines(BuildContext context, List<MajlisHelpline> lines) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.t('helplines')),
        const SizedBox(height: 12),
        for (final h in lines)
          _Row(
            icon: Icons.phone_rounded,
            title: h.name,
            subtitle: [l.digits(h.phone), if (h.note != null) h.note!].join(' · '),
            jewel: MajlisJewels.pomegranate,
            onTap: () {
              Clipboard.setData(ClipboardData(text: h.phone));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l.t('numberCopied'))));
            },
          ),
      ],
    );
  });
}

// ---- 8. Whisper -------------------------------------------------------------

Future<void> showWhisperSheet(BuildContext context, MajlisRoomController c) {
  final text = TextEditingController();
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.t('cantSpeak'), style: MajlisText.head(25, spacing: -0.4)),
          _sub(l.t('whisperSub', {'name': l.name(c.host)})),
          const SizedBox(height: 14),
          TextField(
            controller: text,
            maxLines: 4,
            minLines: 3,
            maxLength: 280,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            style: MajlisText.body(16, height: 1.45),
            decoration: InputDecoration(
              filled: true,
              fillColor: MajlisColors.paper,
              hintText: l.t('whisperHint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.rose)),
            ),
          ),
          const SizedBox(height: 10),
          _PrimaryButton(
            label: l.t('sendPrivately'),
            icon: Icons.mail_lock_rounded,
            onTap: text.text.trim().isEmpty
                ? null
                : () {
                    final t = text.text.trim();
                    Navigator.of(ctx).pop();
                    c.sendWhisper(t);
                  },
          ),
        ],
      ),
    );
  });
}

// ---- 9. Host tools ----------------------------------------------------------

Future<void> showHostToolsSheet(BuildContext context, MajlisRoomController c) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    void go(VoidCallback fn) {
      Navigator.of(ctx).pop();
      fn();
    }

    Widget tile(IconData icon, String label, String sub, VoidCallback onTap, {bool on = false, MajlisJewel j = MajlisJewels.rose}) =>
        Expanded(
          child: Material(
            color: on ? j.light : MajlisColors.paper,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Container(
                height: 112,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: on ? j.deep : Colors.transparent, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: on ? j.deep : j.light, shape: BoxShape.circle),
                      child: Icon(icon, size: 20, color: on ? Colors.white : j.deep),
                    ),
                    const Spacer(),
                    Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: MajlisText.body(14.5, weight: FontWeight.w700)),
                    Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: MajlisText.body(11.5, color: MajlisColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        );

    return ListenableBuilder(
      listenable: c,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(child: _title(l.t('hostTools'))),
              const SizedBox(width: 8),
              const Icon(Icons.star_rounded, color: MajlisColors.gold),
            ],
          ),
          _sub(l.t('hostToolsSub')),
          const SizedBox(height: 14),
          Row(
            children: [
              tile(Icons.air_rounded, l.t('breatheTogether'), l.t('breatheTogetherSub'), () => go(c.breatheTogether), j: MajlisJewels.sage),
              const SizedBox(width: 8),
              tile(Icons.push_pin_rounded, l.t('pinQuestion'), l.t('pinQuestionSub'), () {
                Navigator.of(ctx).pop();
                showPinSheet(context, c);
              }, j: MajlisJewels.saffron),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile(Icons.timer_outlined, l.t('takeTurns'), c.turns ? l.t('turnsOnSub') : l.t('off'), () => go(c.toggleTurns),
                  on: c.turns, j: MajlisJewels.lapis),
              const SizedBox(width: 8),
              tile(Icons.front_hand_rounded, l.t('raisedHands'), l.t('waitingN', {'n': c.hands.length}), () {
                Navigator.of(ctx).pop();
                showHandsSheet(context, c);
              }, j: MajlisJewels.walnut),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile(Icons.mail_lock_rounded, l.t('whispers'), l.t('whispersN', {'n': c.whispers.length}), () {
                Navigator.of(ctx).pop();
                showWhispersSheet(context, c);
              }, j: MajlisJewels.plum),
              const SizedBox(width: 8),
              tile(Icons.volume_off_rounded, l.t('muteEveryone'), l.t('muteEveryoneSub'), () => go(c.muteEveryone), j: MajlisJewels.pomegranate),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              tile(Icons.ios_share_rounded, l.t('invitePeople'), l.t('invitePeopleSub'), () => go(() {
                    _copyInvite(c, l);
                    c.say((l) => l.t('inviteCopied'), Icons.link_rounded);
                  }), j: MajlisJewels.turquoise),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 14),
          _SecondaryButton(
            label: l.t('endGently'),
            icon: Icons.nightlight_round,
            color: MajlisJewels.pomegranate.deep,
            onTap: () async {
              final yes = await showConfirm(ctx, title: l.t('endQ'), body: l.t('endBody'), yes: l.t('endSpace'), no: l.t('stay'));
              if (yes && ctx.mounted) go(c.endSpace);
            },
          ),
        ],
      ),
    );
  });
}

void _copyInvite(MajlisRoomController c, MajlisStrings l) {
  final s = c.space;
  if (s == null) return;
  final text = s.inviteCode != null
      ? c.config.inviteMessage(l.t('inviteText', {'title': s.title, 'code': s.inviteCode!}), s.inviteCode!)
      : l.t('shareText', {'title': s.title, 'when': l.t('liveNow')});
  Clipboard.setData(ClipboardData(text: text));
}

Future<void> showPinSheet(BuildContext context, MajlisRoomController c) {
  final text = TextEditingController(text: c.pinnedIsWhisper ? '' : (c.pinned ?? ''));
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(
      builder: (ctx, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(l.t('pinTitle')),
          const SizedBox(height: 14),
          TextField(
            controller: text,
            maxLines: 3,
            minLines: 2,
            maxLength: 200,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            style: MajlisText.body(16, height: 1.45),
            decoration: InputDecoration(
              filled: true,
              fillColor: MajlisColors.paper,
              hintText: l.t('questionHint'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
            ),
          ),
          const SizedBox(height: 10),
          _PrimaryButton(
            label: l.t('pin'),
            icon: Icons.push_pin_rounded,
            onTap: text.text.trim().isEmpty
                ? null
                : () {
                    Navigator.of(ctx).pop();
                    c.pin(text.text.trim());
                  },
          ),
          if (c.pinned != null) ...[
            const SizedBox(height: 8),
            _SecondaryButton(
              label: l.t('unpin'),
              icon: Icons.push_pin_outlined,
              onTap: () {
                Navigator.of(ctx).pop();
                c.unpin();
              },
            ),
          ],
        ],
      ),
    );
  });
}

Future<void> showWhispersSheet(BuildContext context, MajlisRoomController c) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return ListenableBuilder(
      listenable: c,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(l.t('whispers')),
          _sub(l.t('whispersHostSub')),
          const SizedBox(height: 12),
          if (c.whispers.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(22)),
              child: Text(l.t('noWhispers'), textAlign: TextAlign.center, style: MajlisText.body(15, color: MajlisColors.muted)),
            ),
          for (final w in c.whispers)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              decoration: BoxDecoration(
                color: MajlisColors.paper,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: w.pinned ? MajlisColors.gold : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(w.text, style: MajlisText.body(15, height: 1.45)),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        c.pinWhisper(w);
                      },
                      icon: const Icon(Icons.push_pin_rounded, size: 17),
                      label: Text(l.t('pinWhisper')),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  });
}

Future<void> showHandsSheet(BuildContext context, MajlisRoomController c) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return ListenableBuilder(
      listenable: c,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(l.t('handsTitle')),
          _sub(l.t('handsSub')),
          const SizedBox(height: 12),
          if (c.hands.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(22)),
              child: Text(l.t('noHands'), textAlign: TextAlign.center, style: MajlisText.body(15, color: MajlisColors.muted)),
            ),
          for (final p in c.hands)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
              decoration: BoxDecoration(color: MajlisColors.paper, borderRadius: BorderRadius.circular(22)),
              child: Row(
                children: [
                  MajlisAvatar(person: p, size: 46, hand: true),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l.name(p), style: MajlisText.body(15.5, weight: FontWeight.w700))),
                  IconButton(
                    tooltip: l.t('notNow'),
                    onPressed: () => c.notNow(p),
                    icon: const Icon(Icons.close_rounded, color: MajlisColors.muted),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      // Close the sheet after the last raised hand is invited.
                      if (c.hands.length <= 1) Navigator.of(ctx).pop();
                      c.inviteToStage(p);
                    },
                    style: FilledButton.styleFrom(backgroundColor: MajlisColors.roseDeep, shape: const StadiumBorder()),
                    icon: const Icon(Icons.mic_rounded, size: 18),
                    label: Text(l.t('invite'), style: MajlisText.body(14, color: Colors.white, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  });
}

// ---- 10. Listener menu ------------------------------------------------------

Future<void> showRoomMenuSheet(BuildContext context, MajlisRoomController c, MajlisHallway hall) {
  return _sheet<void>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          icon: Icons.badge_outlined,
          title: l.t('myProfile'),
          subtitle: l.name(c.me),
          onTap: () {
            Navigator.of(ctx).pop();
            showProfileSheet(context, hall);
          },
        ),
        if (c.space?.audience != MajlisAudience.invite)
          _Row(
            icon: Icons.ios_share_rounded,
            title: l.t('shareSpace'),
            subtitle: l.t('invitePeopleSub'),
            jewel: MajlisJewels.turquoise,
            onTap: () {
              Navigator.of(ctx).pop();
              _copyInvite(c, l);
              c.say((l) => l.t('inviteCopied'), Icons.link_rounded);
            },
          ),
        if (c.isGuideModerator) ...[
          _Row(
            icon: Icons.volume_off_rounded,
            title: l.t('muteEveryone'),
            subtitle: l.t('guideToolsSub'),
            jewel: MajlisJewels.plum,
            onTap: () {
              Navigator.of(ctx).pop();
              c.muteEveryone();
            },
          ),
          _Row(
            icon: Icons.nightlight_round,
            title: l.t('endGently'),
            subtitle: l.t('guideToolsSub'),
            jewel: MajlisJewels.pomegranate,
            onTap: () async {
              final yes = await showConfirm(ctx, title: l.t('endQ'), body: l.t('endBody'), yes: l.t('endSpace'), no: l.t('stay'));
              if (!yes) return;
              if (ctx.mounted) Navigator.of(ctx).pop();
              await c.endSpace();
            },
          ),
        ],
        _Row(
          icon: Icons.flag_outlined,
          title: l.t('reportSpace'),
          subtitle: l.t('reportSpaceSub'),
          jewel: MajlisJewels.pomegranate,
          onTap: () async {
            final reason = await showReportSheet(ctx);
            if (reason != null) {
              c.report(null, reason);
              if (ctx.mounted) Navigator.of(ctx).pop();
            }
          },
        ),
      ],
    );
  });
}

// ---- 11. Women-only and invite codes -----------------------------------------

Future<bool?> showWomenSheet(BuildContext context) {
  return _sheet<bool>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: MajlisColors.blush, shape: BoxShape.circle),
            child: const Icon(Icons.female_rounded, size: 32, color: MajlisColors.roseDeep),
          ),
        ),
        const SizedBox(height: 12),
        Text(l.t('womenTitle'), textAlign: TextAlign.center, style: MajlisText.head(25, spacing: -0.4)),
        const SizedBox(height: 6),
        Text(l.t('womenBody'), textAlign: TextAlign.center, style: MajlisText.body(14.5, color: MajlisColors.muted)),
        const SizedBox(height: 18),
        _PrimaryButton(label: l.t('womenYes'), onTap: () => Navigator.of(ctx).pop(true)),
        const SizedBox(height: 8),
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l.t('cancel'))),
      ],
    );
  });
}

Future<String?> showCodeSheet(BuildContext context) {
  final code = TextEditingController();
  return _sheet<String>(context, (ctx) {
    final l = MajlisStrings.of(ctx);
    return StatefulBuilder(
      builder: (ctx, setState) {
        final clean = code.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(l.t('codeTitle')),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: code,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
                ],
                maxLength: 8,
                onChanged: (_) => setState(() {}),
                style: MajlisText.head(28).copyWith(letterSpacing: 6, fontFamily: 'Yaldevi'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: MajlisColors.paper,
                  counterText: '',
                  hintText: 'K7Q2MD',
                  hintStyle: MajlisText.head(28, color: MajlisColors.faint).copyWith(letterSpacing: 6, fontFamily: 'Yaldevi'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: MajlisColors.line)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(l.t('codeHint'), textAlign: TextAlign.center, style: MajlisText.body(13, color: MajlisColors.muted)),
            const SizedBox(height: 14),
            _PrimaryButton(
              label: l.t('join'),
              onTap: clean.length == 6 ? () => Navigator.of(ctx).pop(clean) : null,
            ),
          ],
        );
      },
    );
  });
}
