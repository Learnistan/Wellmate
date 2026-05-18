class Activity {
  final int? id;
  final String title;
  final bool isActive;
  final String duration;
  final String iconPath;
  final String route;

  Activity({
    this.id,
    required this.title,
    required this.isActive,
    required this.duration,
    required this.iconPath,
    required this.route,
  });
}