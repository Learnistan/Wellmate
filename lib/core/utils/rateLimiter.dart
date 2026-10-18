import 'package:shared_preferences/shared_preferences.dart';

class RateLimiter {
  static const _key = 'chat_timestamps';

  final int maxRequests;
  final Duration window;

  RateLimiter({
    this.maxRequests = 15,
    this.window = const Duration(hours: 1),
  });

  Future<Duration?> tryConsume() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;

    final times = (prefs.getStringList(_key) ?? [])
        .map(int.parse)
        .where((t) => now - t < windowMs)
        .toList();

    if (times.length >= maxRequests) {
      final oldest = times.reduce((a, b) => a < b ? a : b);
      return Duration(milliseconds: oldest + windowMs - now);
    }

    times.add(now);
    await prefs.setStringList(_key, times.map((t) => t.toString()).toList());
    return null;
  }
}