import '../../domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    int? id,
    required String title,
    required bool isActive,
    required String duration,
    required String iconPath,
    required String route,
  }) : super(
    id: id,
    title: title,
    isActive: isActive,
    duration: duration,
    iconPath: iconPath,
    route: route,
  );

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      title: map['title'],
      isActive: map['isActive'] == 1,
      duration: map['duration'],
      iconPath: map['iconPath'],
      route: map['route'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isActive': isActive ? 1 : 0,
      'duration': duration,
      'iconPath': iconPath,
      'route': route,
    };
  }
}