import '../entities/post.dart';
import '../repositories/postRepository.dart';

class GetPosts {
  final PostRepository repository;

  GetPosts(this.repository);

  Future<List<Post>> call() async {
    return await repository.getPosts();
  }
}