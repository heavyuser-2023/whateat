import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_condition.dart';
import '../models/meal.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('what_eat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_conditions(
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        isSelected INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        date TEXT NOT NULL,
        healthConditions TEXT NOT NULL
      )
    ''');

    // 기본 건강 조건 삽입
    for (var condition in defaultHealthConditions) {
      await db.insert('health_conditions', condition.toMap());
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final newConditions = [
        HealthCondition(
          id: 6, 
          name: '유방암', 
          description: '유방암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 7, 
          name: '대장암', 
          description: '대장암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 8, 
          name: '폐암', 
          description: '폐암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 9, 
          name: '근육질 몸만들기', 
          description: '근육량 증가를 위한 고단백 식단 필요',
        ),
        HealthCondition(
          id: 10, 
          name: '살빼기', 
          description: '체중 감량을 위한 저칼로리 식단 필요',
        ),
        HealthCondition(
          id: 11, 
          name: '위암', 
          description: '위암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 12, 
          name: '간암', 
          description: '간암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 13, 
          name: '췌장암', 
          description: '췌장암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 14, 
          name: '갑상선암', 
          description: '갑상선암 환자를 위한 식단 필요',
        ),
        HealthCondition(
          id: 15, 
          name: '전립선암', 
          description: '전립선암 환자를 위한 식단 필요',
        ),
      ];

      for (var condition in newConditions) {
        await db.insert('health_conditions', condition.toMap());
      }
    }
  }

  // 건강 조건 관련 메서드
  Future<List<HealthCondition>> getHealthConditions() async {
    final db = await instance.database;
    final result = await db.query('health_conditions');
    return result.map((json) => HealthCondition.fromMap(json)).toList();
  }

  Future<void> updateHealthCondition(HealthCondition condition) async {
    final db = await instance.database;
    await db.update(
      'health_conditions',
      condition.toMap(),
      where: 'id = ?',
      whereArgs: [condition.id],
    );
  }

  // 식사 관련 메서드
  Future<int> insertMeal(Meal meal) async {
    final db = await instance.database;
    return await db.insert('meals', meal.toMap());
  }

  Future<List<Meal>> getMeals() async {
    final db = await instance.database;
    final result = await db.query('meals', orderBy: 'date DESC');
    return result.map((json) => Meal.fromMap(json)).toList();
  }

  Future<Meal?> getMeal(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Meal.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<void> deleteMeal(int id) async {
    final db = await instance.database;
    await db.delete(
      'meals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
} 