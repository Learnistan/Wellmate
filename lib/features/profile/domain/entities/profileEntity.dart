import '../../../../core/enums/journeys.dart';

class ProfileEntity {
  final String uid;
  final String username;
  final DateTime dateOfBirth;
  final Journeys? selectedJourney;

  const ProfileEntity({
    required this.uid,
    required this.username,
    required this.dateOfBirth,
    this.selectedJourney,
  });
}