// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/meal.dart';

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
    String path = join(await getDatabasesPath(), 'gymini.db');

    // BUMP VERSION TO 2 to trigger the upgrade
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createWorkoutTables(db);
        await _createMealTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createMealTable(db);
        }
      },
    );
  }

  Future<void> _createWorkoutTables(Database db) async {
    await db.execute(
        'CREATE TABLE workouts(id TEXT PRIMARY KEY, date TEXT, duration INTEGER)');
    await db.execute(
        'CREATE TABLE exercises(id TEXT PRIMARY KEY, workout_id TEXT, name TEXT, weight REAL, reps INTEGER, sets INTEGER, FOREIGN KEY(workout_id) REFERENCES workouts(id))');
  }

  Future<void> _createMealTable(Database db) async {
    await db.execute(
        'CREATE TABLE meals(id TEXT PRIMARY KEY, timestamp TEXT, type TEXT, items TEXT, hunger INTEGER)');
  }

  // --- WORKOUT CRUD ---

  Future<void> insertWorkout(Workout workout) async {
    final db = await database;
    await db.insert('workouts', workout.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (var exercise in workout.exercises) {
      await db.insert('exercises', exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    final db = await database;
    await db
        .delete('exercises', where: 'workout_id = ?', whereArgs: [workoutId]);
    await db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  Future<List<Workout>> getWorkoutsForDay(DateTime date) async {
    final db = await database;
    // Note: This matches the "Day" part of the string (YYYY-MM-DD)
    // So "2025-12-19T10:00" will still be found by "2025-12-19" query logic
    String dateStr = date.toIso8601String().substring(0, 10);

    final workoutMaps = await db.query('workouts',
        where: 'date LIKE ?',
        whereArgs: ['$dateStr%'] // Match anything starting with YYYY-MM-DD
        );

    List<Workout> workouts = [];
    for (var wMap in workoutMaps) {
      String workoutId = wMap['id'] as String;
      final exerciseMaps = await db
          .query('exercises', where: 'workout_id = ?', whereArgs: [workoutId]);

      List<Exercise> exercises = exerciseMaps
          .map((e) => Exercise(
                id: e['id'] as String,
                workoutId: e['workout_id'] as String,
                name: e['name'] as String,
                weight: (e['weight'] as num).toDouble(),
                reps: e['reps'] as int,
                sets: e['sets'] as int,
              ))
          .toList();

      workouts.add(Workout(
        id: workoutId,
        date: wMap['date'] as String,
        duration: wMap['duration'] as int,
        exercises: exercises,
      ));
    }
    return workouts;
  }

  // --- MEAL CRUD ---

  Future<void> insertMeal(Meal meal) async {
    final db = await database;
    await db.insert('meals', meal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMeal(String mealId) async {
    final db = await database;
    await db.delete('meals', where: 'id = ?', whereArgs: [mealId]);
  }

  // --- THE AI ENGINE (TIMELINE MERGE) ---

  Future<String> getContextForAI() async {
    final db = await database;

    // 1. Fetch EVERYTHING (No Limits)
    final workoutMaps = await db.query('workouts');
    final mealMaps = await db.query('meals');

    if (workoutMaps.isEmpty && mealMaps.isEmpty) {
      return "No previous history available.";
    }

    // 2. Create a mixed list of "Events"
    List<Map<String, dynamic>> timeline = [];

    // Process Workouts
    for (var wMap in workoutMaps) {
      String workoutId = wMap['id'] as String;
      String dateStr = wMap['date'] as String; // e.g. "2025-12-19T14:30:00"

      // Fetch details
      final exerciseMaps = await db
          .query('exercises', where: 'workout_id = ?', whereArgs: [workoutId]);
      List<String> details =
          exerciseMaps.map((e) => "${e['name']} (${e['weight']}kg)").toList();

      timeline.add({
        'type': 'WORKOUT',
        'timestamp': DateTime.parse(dateStr),
        'details':
            "Duration: ${wMap['duration']}m | Exercises: ${details.join(', ')}",
      });
    }

    // Process Meals
    for (var mMap in mealMaps) {
      timeline.add({
        'type': 'MEAL',
        'timestamp': DateTime.parse(mMap['timestamp'] as String),
        'details':
            "[${mMap['type']}] ${mMap['items']} (Hunger: ${mMap['hunger']}/5)",
      });
    }

    // 3. Sort Chronologically (Oldest to Newest)
    timeline.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

    // 4. Build the Story String
    StringBuffer buffer = StringBuffer();
    buffer.writeln("COMPLETE USER TIMELINE (Chronological Order):");

    for (var event in timeline) {
      DateTime ts = event['timestamp'];
      String timeStr =
          "${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";

      buffer.writeln("[$timeStr] ${event['type']}: ${event['details']}");
    }

    return buffer.toString();
  }

  // --- SETTINGS ---

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('exercises');
    await db.delete('workouts');
    await db.delete('meals'); // Clear meals too
  }

  Future<String> exportDataAsJson() async {
    final db = await database;
    final workouts = await db.query('workouts');
    final meals = await db.query('meals');
    // (Simplified export logic for brevity, expands on what you had)
    return const JsonEncoder.withIndent('  ').convert({
      'workouts': workouts,
      'meals': meals,
    });
  }
}
