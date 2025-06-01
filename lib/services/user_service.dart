import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _boxName = 'userBox';

  /// 🔐 Ensures the box is opened before accessing
  Future<Box> _getBox() async {
    return await Hive.openBox(_boxName);
  }

  /// 📛 Returns a persistent, unique user/device ID
  Future<String> getOrCreateUserId() async {
    final box = await _getBox();
    final existingId = box.get('deviceId');
    if (existingId != null) return existingId;

    final uuid = const Uuid().v4();
    await box.put('deviceId', uuid);
    return uuid;
  }

  /// 🙋 Gets display name or defaults to "Anonymous"
  Future<String> getDisplayName() async {
    final box = await _getBox();
    return box.get('name', defaultValue: 'Anonymous');
  }

  /// 📧 Gets email address (nullable)
  Future<String?> getEmail() async {
    final box = await _getBox();
    return box.get('email');
  }

  /// 📝 Optional setter to save name
  Future<void> setDisplayName(String name) async {
    final box = await _getBox();
    await box.put('name', name);
  }

  /// 📝 Optional setter to save email
  Future<void> setEmail(String email) async {
    final box = await _getBox();
    await box.put('email', email);
  }
}
