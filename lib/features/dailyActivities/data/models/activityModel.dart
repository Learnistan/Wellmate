import '../../domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    int? activityId,
    required String title,
    required bool isCompleted,
    required String time,
    required String iconPath,
    required String route,
  }) : super(
    activityId: activityId,
    title: title,
    isCompleted: isCompleted,
    time: time,
    iconPath: iconPath,
    route: route,
  );

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      activityId: map['activityId'],
      title: map['title'],
      isCompleted: map['isCompleted'] == 1,
      time: map['time'],
      iconPath: map['iconPath'],
      route: map['route'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'time': time,
      'iconPath': iconPath,
      'route': route,
    };
  }
}