import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Majlis mark: a tea glass as a microphone, with steam and sound.
/// Source: tool/art/majlis_logo.svg (the nav-bar icon is
/// assets/icons/ic_majlis_*.svg).
class MajlisLogo extends StatelessWidget {
  const MajlisLogo({super.key, this.size = 44, this.semanticLabel});
  final double size;
  final String? semanticLabel;

  static const svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><path d="M47.6 25.6C43.4 22 44.6 17.4 48.2 14.6C51.6 12 52.2 8.6 50.4 5.6C55.8 8.2 56.6 13.6 53.2 17.2C50.6 20 50.4 23 52.2 25.6Z" fill="#6E4A55"/><path d="M55.6 25.4C53.2 22.8 54 20 56.4 18.2C58.4 16.6 58.8 14.4 57.8 12.4C61.6 14.2 62 18 59.6 20.4C58 22 57.8 23.8 58.8 25.4Z" fill="#8A4A57"/><path d="M36.6 31.4H63.4C62.4 39.6 58.2 44 58.2 50.4C58.2 57 62.2 60.6 61.4 66.6C60.6 72.6 55.8 76 50 76C44.2 76 39.4 72.6 38.6 66.6C37.8 60.6 41.8 57 41.8 50.4C41.8 44 37.6 39.6 36.6 31.4Z" fill="#8A4A57"/><path d="M37.4 34.6H62.6L62 37.6H38Z" fill="#C17A82"/><path d="M35 30.2H65" stroke="#C17A82" stroke-width="2.6" stroke-linecap="round"/><path d="M42.4 40.6C44 45 44.4 48 44 51.6" stroke="#B06A77" stroke-width="1.6" stroke-linecap="round" fill="none" opacity=".7"/><path d="M32.6 57.6C32.6 73.6 40.6 82.4 50 82.4C59.4 82.4 67.4 73.6 67.4 57.6" stroke="#6E4A55" stroke-width="3.6" fill="none" stroke-linecap="round"/><path d="M50 82.4V91.6M40.4 92.4H59.6" stroke="#6E4A55" stroke-width="3.6" stroke-linecap="round"/><path d="M25.4 47.4C21.2 52.8 21.2 61.6 25.4 67M18.2 42.6C11.6 50.6 11.6 63.8 18.2 71.8M74.6 47.4C78.8 52.8 78.8 61.6 74.6 67M81.8 42.6C88.4 50.6 88.4 63.8 81.8 71.8" stroke="#C17A82" stroke-width="3" stroke-linecap="round" fill="none"/></svg>';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        svg,
        width: size,
        height: size,
        semanticsLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
      );
}
