// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';
import '../models/exercise.dart';

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE workouts(id TEXT PRIMARY KEY, date TEXT, duration INTEGER)');
        await db.execute(
            'CREATE TABLE exercises(id TEXT PRIMARY KEY, workout_id TEXT, name TEXT, weight REAL, reps INTEGER, sets INTEGER, FOREIGN KEY(workout_id) REFERENCES workouts(id))');
      },
    );
  }

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
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    final workoutMaps =
        await db.query('workouts', where: 'date = ?', whereArgs: [dateStr]);

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

  // --- AI CONTEXT METHOD ---
  Future<String> getContextForAI() async {
    final db = await database;

    // Fetch ALL workouts (Oldest -> Newest)
    final workoutMaps = await db.query('workouts', orderBy: 'date ASC');

    if (workoutMaps.isEmpty) {
      return "No previous workout history available.";
    }

    StringBuffer buffer = StringBuffer();
    buffer.writeln(
        "USER WORKOUT HISTORY (Total Sessions: ${workoutMaps.length}):");

    for (var wMap in workoutMaps) {
      String workoutId = wMap['id'] as String;
      String date = wMap['date'] as String;

      final exerciseMaps = await db
          .query('exercises', where: 'workout_id = ?', whereArgs: [workoutId]);

      List<String> details = exerciseMaps.map((e) {
        return "${e['name']} (${e['weight']}kg x ${e['reps']} x ${e['sets']})";
      }).toList();

      buffer.writeln("- $date: ${details.join(', ')}");
    }

    return buffer.toString();
  }
}
