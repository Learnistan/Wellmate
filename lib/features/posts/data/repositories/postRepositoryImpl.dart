import '../../domain/entities/post.dart';
import '../../domain/repositories/postRepository.dart';
import '../datasources/postRemoteDataSource.dart';
import '../models/postModel.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource dataSource;

  PostRepositoryImpl(this.dataSource);

  @override
  Future<List<Post>> getPosts() async {
    final data = await dataSource.getPosts();

    return data.map((e) => PostModel.fromJson(e)).toList();
  }
}