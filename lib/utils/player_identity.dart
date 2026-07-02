import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

abstract final class PlayerIdentity {
  static const _storageKey = 'kalimat_player_id';
  static const _uuid = Uuid();

  static Future<String> currentId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final id = _uuid.v4();
    await prefs.setString(_storageKey, id);
    return id;
  }
}
