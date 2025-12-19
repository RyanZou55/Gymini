// lib/models/workout.dart
import 'dart:convert';
import 'exercise.dart';

class Workout {
  final String id;
  final String date;
  final int duration;
  final List<Exercise> exercises;

  Workout({
    required this.id,
    required this.date,
    required this.duration,
    required this.exercises,
  });

  // Convert a Workout object into a Map object (for Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'duration': duration,
      // We convert the list of exercises to a JSON string to store it in a single column
      'exercises': jsonEncode(exercises.map((e) => e.toMap()).toList()),
    };
  }

  // Convert a Map object (from Database) into a Workout object
  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      date: map['date'],
      duration: map['duration'] ?? 0,
      exercises: map['exercises'] != null
          ? (jsonDecode(map['exercises']) as List)
              .map((e) => Exercise.fromMap(e))
              .toList()
          : [],
    );
  }
}
