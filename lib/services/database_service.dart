// lib/services/database_service.dart
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/workout.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'gymini.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals(
        id TEXT PRIMARY KEY,
        timestamp TEXT,
        type TEXT,
        items TEXT,
        hunger_before INTEGER,
        hunger_after INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts(
        id TEXT PRIMARY KEY,
        date TEXT,
        duration INTEGER,
        exercises TEXT 
      )
    ''');
  }

  // --- MEAL OPERATIONS ---
  Future<void> insertMeal(Meal meal) async {
    final db = await database;
    await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Meal>> getMealsByDate(DateTime date) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
    return List.generate(maps.length, (i) => Meal.fromMap(maps[i]));
  }

  // --- WORKOUT OPERATIONS ---
  Future<void> insertWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Workout>> getWorkoutsByDate(DateTime date) async {
    final db = await database;
    final startOfDay =
        DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      'workouts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
    );
    return List.generate(maps.length, (i) => Workout.fromMap(maps[i]));
  }

  // --- AI CONTEXT METHOD (UPDATED) ---
  Future<String> getContextForAI() async {
    final db = await database;

    final recentMeals =
        await db.query('meals', orderBy: 'timestamp DESC', limit: 100);
    final recentWorkouts =
        await db.query('workouts', orderBy: 'date DESC', limit: 50);

    String context = "Recent User Activity:\n";

    if (recentMeals.isNotEmpty) {
      context += "MEALS:\n";
      for (var m in recentMeals) {
        context += "- ${m['timestamp']}: ${m['items']} (${m['type']})\n";
      }
    }

    if (recentWorkouts.isNotEmpty) {
      context += "\nWORKOUTS:\n";
      for (var w in recentWorkouts) {
        // 1. Start with the basics
        String workoutSummary = "- ${w['date']} (${w['duration']} mins): ";

        // 2. Decode the exercises JSON string
        try {
          String exercisesJson = w['exercises'] as String;
          List<dynamic> exercisesList = jsonDecode(exercisesJson);

          if (exercisesList.isEmpty) {
            workoutSummary += "No exercises logged.";
          } else {
            // 3. Loop through and format specific exercises
            List<String> exerciseDetails = [];
            for (var ex in exercisesList) {
              // Extract details (safely handling types)
              String name = ex['name'] ?? 'Exercise';
              String type = ex['type'] ?? 'strength';

              if (type == 'cardio') {
                // Formatting for Cardio
                num distance = ex['distance'] ?? 0;
                num duration = ex['duration'] ?? 0;
                exerciseDetails.add("$name ${distance}km in ${duration}mins");
              } else {
                // Formatting for Strength
                int sets = ex['sets'] ?? 0;
                int reps = ex['reps'] ?? 0;
                // Handle weight as num to cover both int and double
                num weight = ex['weight'] ?? 0;
                exerciseDetails.add("$name ${sets}x$reps @ ${weight}kg");
              }
            }
            // Join them with commas
            workoutSummary += exerciseDetails.join(", ");
          }
        } catch (e) {
          workoutSummary += "[Error parsing exercises]";
        }

        context += "$workoutSummary\n";
      }
    }
    return context;
  }

  // --- EXPORT DATA METHOD ---
  Future<String> exportDataAsJson() async {
    final db = await database;
    final allMeals = await db.query('meals');
    final allWorkouts = await db.query('workouts');

    final data = {
      'meals': allMeals,
      'workouts': allWorkouts,
      'exported_at': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  // --- CLEAR DATA METHOD ---
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('meals');
    await db.delete('workouts');
  }
}
