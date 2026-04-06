import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/postRemoteDataSource.dart';
import '../../data/repositories/postRepositoryImpl.dart';
import '../../domain/usecases/getPosts.dart';

final postProvider = FutureProvider((ref) async {
  final dataSource = PostRemoteDataSource();
  final repo = PostRepositoryImpl(dataSource);
  final usecase = GetPosts(repo);

  return usecase();
});