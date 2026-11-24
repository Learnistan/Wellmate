import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wellmate/features/majlis/data/majlis_catalog.dart';
import 'package:wellmate/features/majlis/l10n/majlis_strings.dart';

/// The veil names live in three places: the app catalog, firestore.rules and
/// functions/majlis.js. They must match, or people get refused or shown as
/// "Guest".
void main() {
  List<String> namesIn(String file, RegExp block) {
    final text = File(file).readAsStringSync();
    final m = block.firstMatch(text);
    expect(m, isNotNull, reason: 'veil list not found in $file');
    return RegExp(r'''['"]([a-z_]+)['"]''').allMatches(m!.group(1)!).map((x) => x.group(1)!).toList();
  }

  test('firestore.rules has the same veil names', () {
    final rules = namesIn('firestore.rules', RegExp(r'function veilNames\(\) \{\s*return \[(.*?)\];', dotAll: true));
    expect(rules.toSet(), MajlisCatalog.veils.toSet());
  });

  test('functions/majlis.js has the same veil names', () {
    final js = namesIn('functions/majlis.js', RegExp(r'const VEILS = new Set\(\[(.*?)\]\);', dotAll: true));
    expect(js.toSet(), MajlisCatalog.veils.toSet());
  });

  test('every veil has a name in all three languages', () {
    for (final lang in ['en', 'fa', 'ps']) {
      final l = MajlisStrings(lang);
      for (final v in MajlisCatalog.veils) {
        expect(l.veil(v), isNot(l.t('guest')), reason: '$v has no $lang name');
      }
    }
  });

  test('unknown veils show as Guest, not raw text', () {
    expect(MajlisStrings('en').veil('night_owl'), 'Guest');
    expect(MajlisStrings('fa').veil('you_are_bad'), 'مهمان');
  });

  test('counts use the singular for one', () {
    final en = MajlisStrings('en');
    expect(en.count(1, 'wantToSpeakOne', 'wantToSpeak'), '1 wants to speak');
    expect(en.count(3, 'wantToSpeakOne', 'wantToSpeak'), '3 want to speak');
    expect(MajlisStrings('fa').count(1, 'goingOne', 'goingN'), '۱ نفر می‌آید');
    expect(MajlisStrings('ps').count(2, 'spaceOne', 'spacesIn'), '۲ مجلسونو');
  });
}
