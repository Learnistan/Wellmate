class Activity {
  final int? activityId;
  final String title;
  final bool isActive;
  final String time;
  final String iconPath;
  final String route;

  Activity({
    this.activityId,
    required this.title,
    required this.isActive,
    required this.time,
    required this.iconPath,
    required this.route,
  });
}