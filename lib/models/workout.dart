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

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date,
    'duration': duration,
  };
}
