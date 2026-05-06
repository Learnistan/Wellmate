class Activity {
  final int? activityId;
  final String title;
  final bool isCompleted;
  final String time;
  final String iconPath;
  final String route;

  Activity({
    this.activityId,
    required this.title,
    required this.isCompleted,
    required this.time,
    required this.iconPath,
    required this.route,
  });
}