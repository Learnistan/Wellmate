import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/majlis_models.dart';
import '../majlis_theme.dart';

class MajlisReactionKind {
  final String id;
  final IconData icon;
  final Color color;
  const MajlisReactionKind(this.id, this.icon, this.color);
}

/// Fixed lists Majlis is built on: topics, veil names, reactions.
/// Labels live in MajlisStrings so they show in Dari, Pashto and English.
class MajlisCatalog {
  // ---- Topics (must match TOPICS in functions/majlis.js) --------------------
  static const all = MajlisTopic('all', Icons.grid_view_rounded, MajlisJewels.rose);
  static const chai = MajlisTopic('chai', Icons.local_cafe_rounded, MajlisJewels.saffron);
  static const sleep = MajlisTopic('sleep', Icons.bedtime_rounded, MajlisJewels.lapis);
  static const study = MajlisTopic('study', Icons.menu_book_rounded, MajlisJewels.turquoise);
  static const moms = MajlisTopic('moms', Icons.family_restroom_rounded, MajlisJewels.rose);
  static const poetry = MajlisTopic('poetry', Icons.history_edu_rounded, MajlisJewels.walnut);
  static const faith = MajlisTopic('faith', Icons.mosque_rounded, MajlisJewels.sage);
  static const hope = MajlisTopic('hope', Icons.wb_twilight_rounded, MajlisJewels.pomegranate);
  static const home = MajlisTopic('home', Icons.landscape_rounded, MajlisJewels.plum);

  static const topics = [all, chai, sleep, study, moms, poetry, faith, hope, home];
  static const createTopics = [chai, sleep, study, moms, poetry, faith, hope, home];

  static MajlisTopic topic(String id) => topics.firstWhere((t) => t.id == id, orElse: () => chai);

  /// Title ideas in the start sheet: (string key, topic).
  static const titleIdeas = [
    ('idea.sleep', sleep),
    ('idea.chai', chai),
    ('idea.study', study),
    ('idea.poetry', poetry),
    ('idea.hope', hope),
    ('idea.home', home),
  ];

  // ---- Veil names (translated in MajlisStrings, key "veil.<id>") ------------
  static const veils = [
    'red_tulip', 'almond_blossom', 'morning_sun', 'night_star', 'little_lamp',
    'kabul_rain', 'mulberry', 'pomegranate', 'apricot', 'walnut', 'saffron_moon',
    'blue_butterfly', 'wild_rose', 'cypress', 'hindu_kush', 'soft_cloud',
    'little_sparrow', 'green_apple', 'honey', 'autumn_leaf', 'sunflower',
    'prayer_beads', 'little_teapot', 'warm_naan', 'peacock', 'cherry',
    'shomali_grape', 'lemon_tree', 'clay_jug', 'little_lamb', 'morning_breeze',
    'silver_moon', 'mountain_spring', 'salang_snow', 'panjshir_river',
    'bamyan_sky', 'golden_wheat', 'fig_tree', 'jasmine', 'raindrop', 'little_fox',
  ];

  static final _rand = Random();

  /// How many avatar pictures there are (MajlisPortraitArt.count).
  static const portraits = 10;

  /// A fresh name, keeping the picture.
  static String randomName({String? not}) {
    String v;
    do {
      v = veils[_rand.nextInt(veils.length)];
    } while (v == not);
    return v;
  }

  /// A fresh veil, different from [not].
  static ({String veil, int jewel, int motif}) randomVeil({String? not}) {
    String v;
    do {
      v = veils[_rand.nextInt(veils.length)];
    } while (v == not);
    return (veil: v, jewel: _rand.nextInt(MajlisJewels.all.length), motif: _rand.nextInt(portraits));
  }

  // ---- Reactions ------------------------------------------------------------
  static const love = MajlisReactionKind('love', Icons.favorite_rounded, Color(0xFFD45D6E));
  static const withYou = MajlisReactionKind('withyou', Icons.volunteer_activism_rounded, Color(0xFFC07A2C));
  static const calm = MajlisReactionKind('calm', Icons.spa_rounded, Color(0xFF5E8A5A));
  static const beautiful = MajlisReactionKind('beautiful', Icons.auto_awesome_rounded, Color(0xFFB08A2A));
  static const haha = MajlisReactionKind('haha', Icons.sentiment_very_satisfied_rounded, Color(0xFF3F6BA5));
  static const tea = MajlisReactionKind('tea', Icons.local_cafe_rounded, Color(0xFFA0631D));

  static const reactions = [love, withYou, calm, beautiful, haha];
  static const allReactions = [love, withYou, calm, beautiful, haha, tea];

  static MajlisReactionKind reaction(String id) =>
      allReactions.firstWhere((r) => r.id == id, orElse: () => love);

  /// Report reasons (must match REPORT_REASONS in functions/majlis.js).
  static const reportReasons = ['unsafe', 'harassment', 'identity', 'spam', 'other'];

  /// Seconds per voice in "Take turns".
  static const turnSeconds = 120;
}
