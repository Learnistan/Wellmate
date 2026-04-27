import 'package:intl/intl.dart';

class TimeUtils {
  static String getDayTime({
    required String morning,
    required String noon,
    required String afternoon,
    required String evening,
    required String night,
    required String midnight
  }) {
    final hour = DateTime.now().hour;

    if (hour >= 4 && hour < 12) {
      return morning;
    } else if (hour == 12) {
      return noon;
    } else if (hour > 12 && hour < 18) {
      return afternoon;
    }  else if (hour >= 18 && hour < 20) {
      return evening;
    } else if (hour >= 20 && hour < 24) {
      return night;
    } else {
      return midnight;
    }
  }

  static String getFormattedDate(DateTime date, String locale) {
    return DateFormat('EEEE, d MMMM', locale).format(date);
  }
}