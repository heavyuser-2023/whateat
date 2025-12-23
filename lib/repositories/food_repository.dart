import 'dart:io';
import '../models/meal.dart';
import '../models/food_analysis_result.dart';
import '../services/food_recognition_service.dart';
import '../database/database_helper.dart';
import '../utils/logger.dart';

class FoodRepository {
  final FoodRecognitionService _recognitionService = FoodRecognitionService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<FoodAnalysisResult> analyzeFood(File imageFile, List<String> healthConditions) async {
    AppLogger.info('Repository: Analyzing food image');
    return await _recognitionService.analyzeFoodImage(imageFile, healthConditions);
  }

  Future<int> saveMeal(Meal meal) async {
    AppLogger.info('Repository: Saving meal ${meal.name}');
    return await _databaseHelper.insertMeal(meal);
  }

  Future<List<Meal>> getMealHistory() async {
    AppLogger.info('Repository: Fetching meal history');
    return await _databaseHelper.getMeals();
  }

  Future<void> deleteMeal(int id) async {
    AppLogger.info('Repository: Deleting meal ID $id');
    await _databaseHelper.deleteMeal(id);
  }
}
