import '../../domain/entities/activityLog.dart';

class ActivityLogModel extends ActivityLog {
  ActivityLogModel({
    super.id,
    required super.activityId,
    required super.date,
    required super.value,
  });

  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['id'],
      activityId: map['activity_id'],
      date: map['date'],
      value: map['value'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'activity_id': activityId,
      'date': date,
      'value': value,
    };
  }
}