class PostRemoteDataSource {
  Future<List<Map<String, dynamic>>> getPosts() async {
    await Future.delayed(const Duration(seconds: 1));

    return [
      {"id": 1, "title": "First habit"},
      {"id": 2, "title": "Second habit"},
    ];
  }
}