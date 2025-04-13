import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HealthConditionProvider extends ChangeNotifier {
  List<String> _healthConditions = [];
  
  List<String> get healthConditions => _healthConditions;
  
  Future<void> loadHealthConditions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedConditions = prefs.getStringList('health_conditions');
      
      if (storedConditions != null) {
        _healthConditions = storedConditions;
        notifyListeners();
        print('건강 상태 불러옴: $_healthConditions');
      }
    } catch (e) {
      print('건강 상태 불러오기 오류: $e');
    }
  }
  
  Future<void> updateHealthConditions(List<String> conditions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('health_conditions', conditions);
      
      _healthConditions = conditions;
      notifyListeners();
      print('건강 상태 업데이트됨: $_healthConditions');
    } catch (e) {
      print('건강 상태 업데이트 오류: $e');
    }
  }
} 