import '../../features/dailyActivities/domain/entities/activity.dart';

final List<Activity> defaultActivities = [
  Activity(
    activityId: 1,
    title: "activity_breathing",
    isCompleted: false,
    time: "2",
    iconPath: "air",
    route: "/breathing",
  ),
  Activity(
    activityId: 2,
    title: "activity_movement",
    isCompleted: false,
    time: "15",
    iconPath: "walk",
    route: "/movement",
  ),
  Activity(
      activityId: 3,
      title: "activity_hydration",
      time: "10",
      iconPath: "water",
      route: '/hydration',
      isCompleted: false
  ),
  Activity(
      activityId: 4,
      title: "activity_body_scan",
      time: "5",
      iconPath: "body",
      route: '/body-scan',
      isCompleted:  false
  ),
  Activity(
      activityId: 5,
      title: "activity_burning_thoughts",
      time: "5",
      iconPath: "fire",
      route: '/burning-thoughts',
      isCompleted: false
  ),

];