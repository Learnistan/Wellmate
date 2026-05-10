import '../../features/dailyActivities/domain/entities/activity.dart';

final List<Activity> defaultActivities = [
  Activity(
    id: 1,
    title: "activity_breathing",
    duration: "2",
    iconPath: "air",
    route: "/breathing",
    isActive: true
  ),
  Activity(
    id: 2,
    title: "activity_movement",
    duration: "15",
    iconPath: "walk",
    route: "/movement",
    isActive: true
  ),
  Activity(
    id: 3,
    title: "activity_hydration",
    duration: "10",
    iconPath: "water",
    route: '/hydration',
    isActive: true
  ),
  Activity(
    id: 4,
    title: "activity_body_scan",
    duration: "5",
    iconPath: "body",
    route: '/body-scan',
    isActive: true
  ),
  Activity(
    id: 5,
    title: "activity_burning_thoughts",
    duration: "5",
    iconPath: "fire",
    route: '/burning-thoughts',
    isActive: true
  ),

];