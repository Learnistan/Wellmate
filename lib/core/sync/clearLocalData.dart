import 'localClearable.dart';

class ClearLocalData {
  final List<LocalClearable> items;
  ClearLocalData(this.items);

  Future<void> call() async {
    for (final item in items) {
      try {
        await item.clearLocal();
      } catch (_) {} // one failure shouldn't stop the rest
    }
  }
}