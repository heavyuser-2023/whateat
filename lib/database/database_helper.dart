import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_condition.dart';
import '../models/meal.dart';
import 'dart:io';

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
      version: 3,
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
        imageData BLOB,
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
    
    // 버전 2에서 3으로 업그레이드: meals 테이블에 imageData 컬럼 추가
    if (oldVersion < 3) {
      try {
        // 이미 imageData 컬럼이 있는지 확인
        final tableInfo = await db.rawQuery("PRAGMA table_info(meals)");
        final hasImageData = tableInfo.any((column) => column['name'] == 'imageData');
        
        if (!hasImageData) {
          await db.execute('ALTER TABLE meals ADD COLUMN imageData BLOB');
          print('meals 테이블에 imageData 컬럼 추가됨');
        } else {
          print('meals 테이블에 이미 imageData 컬럼이 존재함');
        }
      } catch (e) {
        print('meals 테이블 업그레이드 오류: $e');
      }
    }
  }

  // 건강 조건 관련 메서드
  Future<List<HealthCondition>> getHealthConditions() async {
    final db = await instance.database;
    final result = await db.query('health_conditions');
    
    // 건강 상태 데이터가 비어있으면 기본 데이터 삽입
    if (result.isEmpty) {
      print('건강 상태 테이블이 비어있어 기본 데이터를 삽입합니다.');
      await _resetHealthConditions(db);
      return await db.query('health_conditions').then(
        (data) => data.map((json) => HealthCondition.fromMap(json)).toList()
      );
    }
    
    return result.map((json) => HealthCondition.fromMap(json)).toList();
  }
  
  // 건강 상태 테이블 초기화
  Future<void> _resetHealthConditions(Database db) async {
    try {
      // 기존 데이터 삭제
      await db.delete('health_conditions');
      
      // 기본 건강 조건 삽입
      for (var condition in defaultHealthConditions) {
        await db.insert('health_conditions', condition.toMap());
      }
      print('건강 상태 기본 데이터 ${defaultHealthConditions.length}개 삽입 완료');
    } catch (e) {
      print('건강 상태 초기화 오류: $e');
    }
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
    try {
      print('데이터베이스 식사 정보 저장 시작: ${meal.name}'); // 디버그 로그
      final db = await instance.database;
      final mealMap = meal.toMap();
      
      // id 필드가 null이 아니면 ID 필드를 제거 (자동 증가 필드가 작동하도록)
      if (mealMap.containsKey('id') && mealMap['id'] == null) {
        mealMap.remove('id');
      }
      
      // 이미지 파일이 있으면 바이너리 데이터로 읽어서 저장
      if (meal.imagePath.isNotEmpty) {
        try {
          final File imageFile = File(meal.imagePath);
          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            mealMap['imageData'] = imageBytes;
            print('이미지 데이터 크기: ${imageBytes.length} 바이트'); // 디버그 로그
          } else {
            print('이미지 파일이 존재하지 않음: ${meal.imagePath}'); // 디버그 로그
            mealMap['imageData'] = null;
          }
        } catch (e) {
          print('이미지 데이터 로드 오류: $e'); // 디버그 로그
          mealMap['imageData'] = null;
        }
      } else {
        mealMap['imageData'] = null;
      }
      
      final id = await db.insert('meals', mealMap);
      print('데이터베이스 식사 저장 완료, ID: $id'); // 디버그 로그
      return id;
    } catch (e) {
      print('데이터베이스 식사 저장 오류: $e'); // 디버그 로그
      return -1; // 오류 발생 시 -1 반환
    }
  }

  Future<List<Meal>> getMeals() async {
    try {
      print('데이터베이스에서 모든 식사 정보 불러오기 시작'); // 디버그 로그
      final db = await instance.database;
      final result = await db.query('meals', orderBy: 'date DESC');
      print('데이터베이스에서 불러온 식사 수: ${result.length}'); // 디버그 로그
      
      final meals = result.map((json) {
        try {
          return Meal.fromMap(json);
        } catch (e) {
          print('개별 식사 레코드 변환 오류: $e');
          return null;
        }
      }).whereType<Meal>().toList(); // null 값 필터링
      
      print('변환된 식사 객체 수: ${meals.length}'); // 디버그 로그
      return meals;
    } catch (e) {
      print('모든 식사 불러오기 오류: $e'); // 디버그 로그
      return []; // 오류 발생 시 빈 목록 반환
    }
  }

  Future<Meal?> getMeal(int id) async {
    try {
      print('데이터베이스에서 식사 정보 조회, ID: $id'); // 디버그 로그
      final db = await instance.database;
      final maps = await db.query(
        'meals',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        try {
          return Meal.fromMap(maps.first);
        } catch (e) {
          print('식사 정보 변환 오류, ID: $id, 오류: $e');
          return null;
        }
      } else {
        print('ID가 $id인 식사 정보 없음');
        return null;
      }
    } catch (e) {
      print('식사 정보 조회 오류, ID: $id, 오류: $e');
      return null;
    }
  }

  Future<void> deleteMeal(int id) async {
    try {
      print('데이터베이스에서 식사 정보 삭제 시작, ID: $id'); // 디버그 로그
      final db = await instance.database;
      
      // 식사 정보 조회 (삭제 전 이미지 파일 확인을 위해)
      final mealToDelete = await getMeal(id);
      
      // 데이터베이스에서 삭제
      final deletedCount = await db.delete(
        'meals',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      print('데이터베이스에서 삭제된 식사 수: $deletedCount, ID: $id'); // 디버그 로그
      
      // 연결된 이미지 파일도 삭제 시도
      if (mealToDelete != null && mealToDelete.imagePath.isNotEmpty) {
        try {
          final imageFile = File(mealToDelete.imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
            print('식사 이미지 파일 삭제 완료: ${mealToDelete.imagePath}');
          } else {
            print('삭제할 이미지 파일이 존재하지 않음: ${mealToDelete.imagePath}');
          }
        } catch (e) {
          print('이미지 파일 삭제 오류: $e');
          // 데이터베이스 작업은 성공했으므로 예외를 삼킴
        }
      }
    } catch (e) {
      print('식사 정보 삭제 오류, ID: $id, 오류: $e');
      throw Exception('식사 정보 삭제 중 오류가 발생했습니다: $e');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
} 