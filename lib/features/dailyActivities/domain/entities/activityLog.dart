class ActivityLog {
  final int? id;
  final int activityId;
  final String date;
  final String value;

  ActivityLog({
    this.id,
    required this.activityId,
    required this.date,
    required this.value,
  });
}