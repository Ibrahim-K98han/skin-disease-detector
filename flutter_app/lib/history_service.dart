import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_model.dart';

class HistoryService {
  static const String _key = 'scan_history';

  // History save করা
  static Future<void> saveHistory(HistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();

    // আগের history load করো
    List<HistoryItem> history = await getHistory();

    // নতুন item সামনে যোগ করো
    history.insert(0, item);

    // সর্বোচ্চ ৫০টা রাখব
    if (history.length > 50) {
      history = history.take(50).toList();
    }

    // Save করো
    List<String> jsonList =
        history.map((e) => json.encode(e.toMap())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  // History load করা
  static Future<List<HistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_key);

    if (jsonList == null) return [];

    return jsonList
        .map((e) => HistoryItem.fromMap(json.decode(e)))
        .toList();
  }

  // History মুছে ফেলা
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}