import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationHistoryService {
  static const String historyKey = 'ent_oncall_notification_history';
  static const int maxHistoryItems = 50;

  static Future<void> addMessage(String title, String body) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
    );

    history.insert(0, newItem);
    
    // Limit history size
    if (history.length > maxHistoryItems) {
      history.removeRange(maxHistoryItems, history.length);
    }

    final jsonList = history.map((item) => item.toJson()).toList();
    await prefs.setString(historyKey, jsonEncode(jsonList));
  }

  static Future<List<NotificationItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(historyKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => NotificationItem.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    final index = history.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = history[index];
      history[index] = NotificationItem(
        id: item.id,
        title: item.title,
        body: item.body,
        timestamp: item.timestamp,
        isRead: true,
      );
      
      final jsonList = history.map((item) => item.toJson()).toList();
      await prefs.setString(historyKey, jsonEncode(jsonList));
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(historyKey);
  }
}
