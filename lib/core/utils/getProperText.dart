import '../../l10n/app_localizations.dart';

String getActivityTitle(String key, AppLocalizations loc) {
  switch (key) {
    case "activity_breathing":
      return loc.activity_breathing;
    case "activity_movement":
      return loc.activity_movement;
    case "activity_hydration":
      return loc.activity_hydration;
    case "activity_body_scan":
      return loc.activity_body_scan;
    case "activity_burning_thoughts":
      return loc.activity_burning_thoughts;
    default:
      return key;
  }
}