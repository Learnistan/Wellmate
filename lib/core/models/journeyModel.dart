class JourneyModel {
  final String name;
  final String thumbnailImage;
  final String animationPath;
  final String city;
  final String description;
  final String explanation;
  final List<int> pauseSeconds;

  const JourneyModel({
    required this.name,
    required this.thumbnailImage,
    required this.animationPath,
    required this.city,
    required this.description,
    required this.explanation,
    required this.pauseSeconds
  });

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      name: json['name'],
      thumbnailImage: json['thumbnailImage'],
      animationPath: json['animationPath'],
      city: json['city'],
      description: json['description'],
      explanation: json['explanation'],
      pauseSeconds: json['pauseSeconds']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'thumbnailImage': thumbnailImage,
      'animationPath': animationPath,
      'city': city,
      'description': description,
      'explanation': explanation,
      'pauseSeconds': pauseSeconds
    };
  }
}