import '../../../../core/enums/journeys.dart';
import '../repositories/profileRepository.dart';

class UpdateSelectedJourney {
  final ProfileRepository repository;
  UpdateSelectedJourney(this.repository);

  Future<void> call(String uid, Journeys journey) =>
      repository.updateSelectedJourney(uid, journey);
}