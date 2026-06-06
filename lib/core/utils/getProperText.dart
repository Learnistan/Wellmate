import 'package:wellmate/core/enums/journeys.dart';

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

String getJourneyName(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyName;
    case .minarets:
      return loc.minaretsJourneyName;
    }
}

String getJourneyCity(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyCity;
    case .minarets:
      return loc.minaretsJourneyCity;
  }
}

String getJourneyDescription(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyDescription;
    case .minarets:
      return loc.minaretsJourneyDescription;
  }
}