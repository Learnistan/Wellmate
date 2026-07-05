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
    case "activity_mood_calibration":
      return loc.activity_mood_calibration;
    case "morning_intentions":
      return loc.morningIntentionsActivity;
    case "evening_close":
      return loc.eveningCloseActivity;
    default:
      return key;
  }
}

List getGameTexts(String key, AppLocalizations loc) {
  switch (key) {
    case "game_visualizing":
      return [loc.visualizingGameTitle, loc.visualizingGameBenefit, loc.visualizingGameDesc];
    case "game_bubbles":
      return [loc.bubblesGameTitle, loc.bubblesGameBenefit, loc.bubblesGameDesc];
    case "game_emotions":
      return [loc.emotionsGameTitle, loc.emotionsGameBenefit, loc.emotionsGameDesc];
    default:
      return [];
  }
}

String getJourneyName(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyName;
    case .minarets:
      return loc.minaretsJourneyName;
    case .womenDress:
      return loc.womenDressName;
    case .menDress:
      return loc.gharaName;
    case .pomegranateTree:
      return loc.pomegranateName;
    }
}

String getJourneyCity(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyCity;
    case .minarets:
      return loc.minaretsJourneyCity;
    case .womenDress:
      return loc.womenDressCity;
    case .menDress:
      return loc.gharaDressCity;
    case .pomegranateTree:
      return loc.pomegranateCity;
  }
}

String getJourneyDescription(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.carpetJourneyDescription;
    case .minarets:
      return loc.minaretsJourneyDescription;
    case .womenDress:
      return loc.womenDressDescription;
    case .menDress:
      return loc.gharaDescription;
    case .pomegranateTree:
      return loc.pomegranateDescription;
  }
}

String getJourneyExplanation(Journeys key, AppLocalizations loc) {
  switch (key) {
    case .carpet:
      return loc.journeyCarpetExp;
    case .minarets:
      return loc.journeyMinaretsExp;
    case .womenDress:
      return loc.journeyWomenDressExp;
    case .menDress:
      return loc.journeyMenDressExp;
    case .pomegranateTree:
      return loc.journeyPomegranateExp;
  }
}