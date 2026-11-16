import '../repositories/profileRepository.dart';

class GetActiveJourneysUseCase {
  final ProfileRepository repository;

  GetActiveJourneysUseCase(this.repository);

  Future<List<String>> call() {
    return repository.getUnlockedJourneyNames();
  }
}