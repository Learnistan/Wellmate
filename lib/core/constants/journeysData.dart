import '../enums/journeys.dart';
import '../models/journeyModel.dart';

const Map<Journeys, JourneyModel> journeysData = {
  Journeys.carpet: JourneyModel(
    name: 'Mazar Carpet',
    thumbnailImage: 'assets/icons/ic_carpet.webp',
    animationPath: 'assets/videos/Carpet.mp4',
    city: 'MAZAR',
    description: 'Care & Rebuilding',
    pauseSeconds: [
      0,
      5,
      11,
      16,
      21,
      27,
      32,
      37,
      43,
      48,
      53,
      59,
      64,
      69,
      80
    ]
  ),

  Journeys.minarets: JourneyModel(
    name: 'Minarets of Herat',
    thumbnailImage: 'assets/icons/ic_minarets.webp',
    animationPath: 'assets/videos/Minarets.mp4',
    city:'HERAT',
    description: 'Rebuilding & Strength',
    pauseSeconds: [
      0,
      1,
      3,
      4,
      21,
      5,
      8,
      9,
      10,
      11,
      13,
      16,
      18,
      23,
      32
    ]
  ),
};