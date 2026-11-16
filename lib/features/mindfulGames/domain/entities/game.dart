class Game {
  final int? id;
  final String title;
  final String iconPath;
  final String route;
  final String benefit;
  final String duration;
  final String description;

  Game({
    this.id,
    required this.title,
    required this.iconPath,
    required this.route,
    required this.benefit,
    required this.duration,
    required this.description
  });
}