import 'package:flutter/cupertino.dart';

import '../../../../core/constants/journeysData.dart';
import '../../../../core/enums/journeys.dart';
import '../../../../core/models/journeyModel.dart';
import '../../domain/useCases/getActiveJourneysUseCase.dart';

class ProfileProvider extends ChangeNotifier {
  final GetActiveJourneysUseCase getActiveJourneysUseCase;

  ProfileProvider(this.getActiveJourneysUseCase);

  List<String> unlockedJourneyNames = [];

  Future<void> loadJourneys() async {
    unlockedJourneyNames = await getActiveJourneysUseCase();

    notifyListeners();
  }

  List<MapEntry<Journeys, JourneyModel>> get unlockedJourneys {
    return journeysData.entries.where((entry) {
      return unlockedJourneyNames.contains(entry.key.name);
    }).toList();
  }
}