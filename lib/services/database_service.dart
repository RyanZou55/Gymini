import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert'; // Required for JSON export
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

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createWorkoutTables(db);
        await _createMealTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createMealTable(db);
        }
        if (oldVersion < 3) {
          // Migration: Add new hunger columns if they don't exist
          var columns = await db.rawQuery('PRAGMA table_info(meals)');
          bool hasHungerBefore =
              columns.any((c) => c['name'] == 'hunger_before');

          if (!hasHungerBefore) {
            // Add columns and migrate old data
            try {
              await db.execute(
                  'ALTER TABLE meals ADD COLUMN hunger_before INTEGER DEFAULT 3');
              await db.execute(
                  'ALTER TABLE meals ADD COLUMN hunger_after INTEGER DEFAULT 4');

              // Attempt to copy old 'hunger' to 'hunger_before' if it existed
              // We wrap in try/catch in case 'hunger' didn't exist
              await db.execute('UPDATE meals SET hunger_before = hunger');
            } catch (e) {
              // Ignore migration errors if column missing
            }
          }
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
        'CREATE TABLE IF NOT EXISTS meals(id TEXT PRIMARY KEY, timestamp TEXT, type TEXT, items TEXT, hunger_before INTEGER, hunger_after INTEGER)');
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
    String dateStr = date.toIso8601String().substring(0, 10);

    final workoutMaps = await db
        .query('workouts', where: 'date LIKE ?', whereArgs: ['$dateStr%']);

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

  // --- AI CONTEXT ENGINE ---

  Future<String> getContextForAI() async {
    final db = await database;
    final workoutMaps = await db.query('workouts');
    final mealMaps = await db.query('meals');

    if (workoutMaps.isEmpty && mealMaps.isEmpty) {
      return "No previous history available.";
    }

    List<Map<String, dynamic>> timeline = [];

    // Process Workouts
    for (var wMap in workoutMaps) {
      String workoutId = wMap['id'] as String;
      String dateStr = wMap['date'] as String;

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
      // FIX 1 & 2: Explicit casting to 'int?' to satisfy Dart strict typing
      int hBefore =
          (mMap['hunger_before'] as int?) ?? (mMap['hunger'] as int?) ?? 3;
      int hAfter = (mMap['hunger_after'] as int?) ?? 4;

      timeline.add({
        'type': 'MEAL',
        'timestamp': DateTime.parse(mMap['timestamp'] as String),
        'details':
            "[${mMap['type']}] ${mMap['items']} (Hunger: $hBefore/5 -> $hAfter/5)",
      });
    }

    timeline.sort((a, b) =>
        (a['timestamp'] as DateTime).compareTo(b['timestamp'] as DateTime));

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

  // --- FIX 3 & 4: MISSING METHODS RESTORED ---

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('exercises');
    await db.delete('workouts');
    await db.delete('meals');
  }

  Future<String> exportDataAsJson() async {
    final db = await database;
    final workouts = await db.query('workouts');
    final meals = await db.query('meals');
    final exercises = await db.query('exercises');

    return const JsonEncoder.withIndent('  ').convert({
      'workouts': workouts,
      'exercises': exercises,
      'meals': meals,
    });
  }
}
