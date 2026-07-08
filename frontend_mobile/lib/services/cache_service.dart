import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appmobilegmao/models/work_order.dart';

class CacheService {
  static const String _ordersKey = 'cached_orders';
  static const String _lastSyncKey = 'last_sync_time';

  Future<void> cacheOrders(List<WorkOrder> orders, {String key = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = key.isEmpty ? _ordersKey : '${_ordersKey}_$key';
      final ordersJson = orders.map((o) => o.toJson()).toList();
      await prefs.setString(storageKey, jsonEncode(ordersJson));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Erreur cache: $e');
    }
  }

  Future<List<WorkOrder>?> getCachedOrders({String key = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storageKey = key.isEmpty ? _ordersKey : '${_ordersKey}_$key';
      final ordersString = prefs.getString(storageKey);

      if (ordersString == null) return null;

      final List<dynamic> ordersJson = jsonDecode(ordersString);
      return ordersJson.map((json) => WorkOrder.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  Future<void> cacheOrderDetails(String otNumber, WorkOrder order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'order_$otNumber';
      await prefs.setString(key, jsonEncode(order.toJson()));
    } catch (e) {
      debugPrint('Erreur cache détails: $e');
    }
  }

  Future<WorkOrder?> getCachedOrderDetails(String otNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'order_$otNumber';
      final orderString = prefs.getString(key);

      if (orderString == null) return null;

      return WorkOrder.fromJson(jsonDecode(orderString));
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);

      if (lastSyncString == null) return null;

      return DateTime.parse(lastSyncString);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordersKey);
      await prefs.remove('${_ordersKey}_mine');
      await prefs.remove('${_ordersKey}_all_open');
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      debugPrint('Erreur effacement: $e');
    }
  }
}