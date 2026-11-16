import '../../domain/repositories/profileRepository.dart';
import '../dataSources/profileDataSource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource localDataSource;

  ProfileRepositoryImpl(this.localDataSource);

  @override
  Future<List<String>> getUnlockedJourneyNames() {
    return localDataSource.getUnlockedJourneyNames();
  }
}