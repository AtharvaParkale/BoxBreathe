import 'package:hive_flutter/hive_flutter.dart';

abstract class LocalStorage {
  Future<void> init();
  Future<void> put(String boxName, String key, dynamic value);
  dynamic get(String boxName, String key, {dynamic defaultValue});
  Future<void> delete(String boxName, String key);
}

class HiveLocalStorage implements LocalStorage {
  @override
  Future<void> init() async {
    await Hive.initFlutter();
  }

  @override
  Future<void> put(String boxName, String key, dynamic value) async {
    final box = await Hive.openBox(boxName);
    await box.put(key, value);
  }

  @override
  dynamic get(String boxName, String key, {dynamic defaultValue}) {
    // We can't synchronously open box if it's not open, but for simple settings 
    // we usually open boxes at startup or await. 
    // For this simple app, we'll assume boxes are opened or we await openBox.
    // However, Hive.box(name) throws if not opened.
    // Let's change this to async or ensure box is open.
    // For simplicity, let's open on demand or ensure opened.
    // Better practice: open specific boxes at app start.
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box(boxName).get(key, defaultValue: defaultValue);
    } else {
      // This is blocking/async mismatch. 
      // Ideally we should make get async or pre-open boxes.
      // Given the requirement "SettingsBloc", we can make it async.
      throw Exception('Box $boxName not open'); 
    }
  }
  
  // Async get for safety
  Future<dynamic> getAsync(String boxName, String key, {dynamic defaultValue}) async {
    final box = await Hive.openBox(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  @override
  Future<void> delete(String boxName, String key) async {
    final box = await Hive.openBox(boxName);
    await box.delete(key);
  }
}
