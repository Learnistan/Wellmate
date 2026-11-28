import 'package:flutter_test/flutter_test.dart';
import 'package:wellmate/features/majlis/data/majlis_catalog.dart';
import 'package:wellmate/features/majlis/l10n/majlis_strings.dart';

void main() {
  final placeholder = RegExp(r'\{(\w+)\}');

  test('every string exists in English, Dari and Pashto', () {
    for (final e in MajlisStrings.entries) {
      expect(e.value.length, 3, reason: e.key);
      for (final s in e.value) {
        expect(s.trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('placeholders match in all three languages', () {
    for (final e in MajlisStrings.entries) {
      final en = placeholder.allMatches(e.value[0]).map((m) => m[1]).toSet();
      for (final s in e.value.skip(1)) {
        expect(placeholder.allMatches(s).map((m) => m[1]).toSet(), en, reason: e.key);
      }
    }
  });

  test('every topic, veil, reaction and report reason has words', () {
    final keys = {for (final e in MajlisStrings.entries) e.key};
    for (final t in MajlisCatalog.topics) {
      expect(keys, contains('topic.${t.id}'));
    }
    for (final v in MajlisCatalog.veils) {
      expect(keys, contains('veil.$v'));
    }
    for (final r in MajlisCatalog.allReactions) {
      expect(keys, contains('react.${r.id}'));
    }
    for (final r in MajlisCatalog.reportReasons) {
      expect(keys, contains('reason.$r'));
    }
  });

  test('Dari and Pashto use Persian digits', () {
    expect(MajlisStrings('fa').n(2026), '۲۰۲۶');
    expect(MajlisStrings('ps').t('goingN', {'n': 12}), contains('۱۲'));
    expect(MajlisStrings('en').t('goingN', {'n': 12}), '12 going');
    expect(MajlisStrings('fa').time(DateTime(2026, 1, 1, 21, 5)), '۹:۰۵ ب.ظ');
    expect(MajlisStrings('ps').time(DateTime(2026, 1, 1, 9, 30)), '۹:۳۰ غ.م');
  });
}
