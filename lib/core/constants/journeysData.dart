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
    Journeys.womenDress: JourneyModel(
        name: 'Afghan Women Dress',
        thumbnailImage: 'assets/icons/ic_dress.webp',
        animationPath: 'assets/videos/dress.mp4',
        city:'KABUL',
        description: 'Rebuilding & Strength',
        pauseSeconds: [
            0,
            5,
            10,
            16,
            21,
            28,
            35,
            49,
            56,
            62,
            68,
            74,
            81,
            85,
            88
        ]
    ),

  Journeys.menDress: JourneyModel(
      name: 'Kandahari Ghara',
      thumbnailImage: 'assets/icons/ic_gare.webp',
      animationPath: 'assets/videos/gare.mp4',
      city:'KANDAHAR',
      description: 'Identity & Pride',
      pauseSeconds: [
        0,
        3,
        8,
        13,
        19,
        24,
        28,
        33,
        38,
        43,
        50,
        54,
        61,
        65,
        72
      ]
  ),

  Journeys.pomegranateTree: JourneyModel(
      name: 'Pomegranate Tree',
      thumbnailImage: 'assets/icons/ic_pomegranate.webp',
      animationPath: 'assets/videos/pomegranate.mp4',
      city:'KANDAHAR',
      description: 'Growth & Patience',
      pauseSeconds: [
        0,
        5,
        8,
        11,
        15,
        17,
        22,
        25,
        28,
        30,
        33,
        35,
        38,
        40,
        46
      ]
  ),
};