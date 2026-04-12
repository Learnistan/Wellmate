import '../../domain/repository/appStorageRepository.dart';
import '../dataSources/local_storage_dataSource.dart';

class AppStorageRepositoryImpl implements AppStorageRepository {
  final LocalStorageDataSource localDataSource;

  AppStorageRepositoryImpl(this.localDataSource);

  @override
  Future<bool> getIsFirstLaunch() {
    return localDataSource.getIsFirstLaunch();
  }

  @override
  Future<void> setFirstLaunch(bool value) {
    return localDataSource.setFirstLaunch(value);
  }

  @override
  Future<bool> getIsLoggedIn() {
    return localDataSource.getIsLoggedIn();
  }

  @override
  Future<void> setIsLoggedIn(bool value) {
    return localDataSource.setIsLoggedIn(value);
  }
}