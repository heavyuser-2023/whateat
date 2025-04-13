import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../models/meal.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({Key? key}) : super(key: key);

  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealHistory();
  }

  Future<void> _loadMealHistory() async {
    try {
      setState(() => _isLoading = true);
      
      List<Meal> allMeals = [];
      
      // 1. SQLite에서 식사 기록 불러오기
      final dbMeals = await DatabaseHelper.instance.getMeals();
      allMeals.addAll(dbMeals);
      
      // 2. SharedPreferences에서 식사 기록 불러오기
      final prefs = await SharedPreferences.getInstance();
      final String? mealsJson = prefs.getString('saved_meals');
      
      if (mealsJson != null) {
        try {
          final List<dynamic> mealsList = jsonDecode(mealsJson);
          final localMeals = mealsList.map((map) => Meal.fromMap(map as Map<String, dynamic>)).toList();
          
          // SharedPreferences에서 불러온 식사 중 데이터베이스에 없는 것만 추가
          // (ID로 비교)
          for (final localMeal in localMeals) {
            if (localMeal.id != null && !dbMeals.any((m) => m.id == localMeal.id)) {
              allMeals.add(localMeal);
            }
          }
        } catch (e) {
          print('로컬 저장 식사 기록 파싱 오류: $e');
        }
      }
      
      // 날짜 기준 정렬 (최신순)
      allMeals.sort((a, b) => b.date.compareTo(a.date));
      
      setState(() {
        _meals = allMeals;
        _isLoading = false;
      });
    } catch (e) {
      print('식사 기록 불러오기 오류: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('식사 기록을 불러오는 중 오류가 발생했습니다.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeal(int id) async {
    try {
      // SQLite에서 삭제
      await DatabaseHelper.instance.deleteMeal(id);
      
      // SharedPreferences에서도 삭제
      await _deleteMealFromLocalStorage(id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식사 기록이 삭제되었습니다')),
      );
      _loadMealHistory();
    } catch (e) {
      print('식사 삭제 오류: $e');
      _showErrorDialog('식사 기록을 삭제하는 중 오류가 발생했습니다.');
    }
  }
  
  // SharedPreferences에서 식사 기록 삭제
  Future<void> _deleteMealFromLocalStorage(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? mealsJson = prefs.getString('saved_meals');
      
      if (mealsJson != null) {
        final List<dynamic> mealsList = jsonDecode(mealsJson);
        
        // 해당 ID를 가진 식사 제외
        final filteredMeals = mealsList.where((meal) {
          final Map<String, dynamic> mealMap = meal as Map<String, dynamic>;
          return mealMap['id'] != id;
        }).toList();
        
        // 다시 저장
        await prefs.setString('saved_meals', jsonEncode(filteredMeals));
        print('식사 기록이 로컬 저장소에서 삭제되었습니다: ID $id');
      }
    } catch (e) {
      print('로컬 저장소에서 식사 삭제 오류: $e');
      // 에러가 발생해도 앱 실행은 계속되도록 예외를 삼킴
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '식사 기록',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _meals.isEmpty
              ? const Center(
                  child: Text(
                    '아직 저장된 식사 기록이 없습니다',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _meals.length,
                  itemBuilder: (context, index) {
                    final meal = _meals[index];
                    return _buildMealCard(meal);
                  },
                ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일 HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(meal.name),
            subtitle: Text(dateFormat.format(meal.date)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(meal),
            ),
          ),
          if (File(meal.imagePath).existsSync())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(meal.imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.description),
                const SizedBox(height: 8),
                const Text(
                  '고려한 건강 상태:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8.0,
                  children: meal.healthConditions
                      .map((condition) => Chip(
                            label: Text(condition),
                            backgroundColor: Colors.green.shade100,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('식사 기록 삭제'),
        content: const Text('이 식사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMeal(meal.id!);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 