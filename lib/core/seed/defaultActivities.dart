import '../../features/dailyActivities/domain/entities/activity.dart';

final List<Activity> defaultActivities = [
  Activity(
    activityId: 1,
    title: "activity_breathing",
    time: "2",
    iconPath: "air",
    route: "/breathing",
    isActive: true
  ),
  Activity(
    activityId: 2,
    title: "activity_movement",
    time: "15",
    iconPath: "walk",
    route: "/movement",
    isActive: true
  ),
  Activity(
    activityId: 3,
    title: "activity_hydration",
    time: "10",
    iconPath: "water",
    route: '/hydration',
    isActive: true
  ),
  Activity(
    activityId: 4,
    title: "activity_body_scan",
    time: "5",
    iconPath: "body",
    route: '/body-scan',
    isActive: true
  ),
  Activity(
    activityId: 5,
    title: "activity_burning_thoughts",
    time: "5",
    iconPath: "fire",
    route: '/burning-thoughts',
    isActive: true
  ),

];