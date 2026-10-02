import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/journeys.dart';
import '../../domain/entities/profileEntity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.uid,
    required super.username,
    required super.dateOfBirth,
    super.selectedJourney,
  });

  factory ProfileModel.fromEntity(ProfileEntity e) => ProfileModel(
    uid: e.uid,
    username: e.username,
    dateOfBirth: e.dateOfBirth,
    selectedJourney: e.selectedJourney,
  );

  Map<String, dynamic> toLocal({required bool synced}) => {
    'remote_id': uid,
    'username': username,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'selected_journey': selectedJourney?.name,
    'is_synced': synced ? 1 : 0,
    'updated_at': DateTime.now().toIso8601String(),
  };

  Map<String, dynamic> toRemote() => {
    if (username != null) 'username': username,
    if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
    if (selectedJourney != null) 'selectedJourney': selectedJourney!.name,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory ProfileModel.fromRemote(String uid, Map<String, dynamic> data) {
    final journeyName = data['selectedJourney'] as String?;

    return ProfileModel(
      uid: uid,
      username: data['username'] ?? '',
      dateOfBirth: data["dateOfBirth"] == null
          ? null
          : DateTime.parse(data['dateOfBirth']),
      selectedJourney: journeyName == null
          ? null
          : Journeys.values.firstWhere((j) => j.name == journeyName),
    );
  }

  factory ProfileModel.fromLocal(Map<String, dynamic> row) {
    final journeyName = row['selected_journey'] as String?;

    return ProfileModel(
      uid: row['remote_id'] as String,
      username: row['username'] ?? '',
      dateOfBirth: row['date_of_birth'] == null
          ? null
          : DateTime.parse(row['date_of_birth'] as String),
      selectedJourney: journeyName == null
          ? null
          : Journeys.values.firstWhere((j) => j.name == journeyName),
    );
  }
}