import '../../domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    int? id,
    required String title,
    required bool isActive,
    required String time,
    required String iconPath,
    required String route,
  }) : super(
    id: id,
    title: title,
    isActive: isActive,
    duration: time,
    iconPath: iconPath,
    route: route,
  );

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      title: map['title'],
      isActive: map['isActive'] == 1,
      time: map['time'],
      iconPath: map['iconPath'],
      route: map['route'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isActive': isActive ? 1 : 0,
      'time': duration,
      'iconPath': iconPath,
      'route': route,
    };
  }
}