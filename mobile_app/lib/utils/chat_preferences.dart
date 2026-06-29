import 'package:shared_preferences/shared_preferences.dart';

String _encodeIntSet(Set<int> values) {
  final sorted = values.toList()..sort();
  return sorted.join(',');
}

Set<int> _decodeIntSet(String? value) {
  if (value == null || value.trim().isEmpty) return <int>{};
  return value
      .split(',')
      .map((item) => int.tryParse(item.trim()))
      .whereType<int>()
      .toSet();
}

Future<void> restoreHiddenChatRoom(int roomId) async {
  if (roomId <= 0) return;

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id') ?? 0;
  if (userId <= 0) return;

  final key = 'mobile_chat_preferences:$userId:hidden';
  final hiddenRoomIds = _decodeIntSet(prefs.getString(key));
  if (!hiddenRoomIds.remove(roomId)) return;

  await prefs.setString(key, _encodeIntSet(hiddenRoomIds));
}
