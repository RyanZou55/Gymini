// lib/models/exercise.dart

class Exercise {
  final String id;
  final String name;
  final String type; // 'strength' or 'cardio'

  // Strength-specific fields
  final int sets;
  final int reps;
  final double weight;

  // Cardio-specific fields
  final double? distance; // in km
  final int? duration; // in minutes

  Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.sets = 0,
    this.reps = 0,
    this.weight = 0.0,
    this.distance,
    this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'distance': distance,
      'duration': duration,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'strength',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
      distance: (map['distance'] as num?)?.toDouble(),
      duration: map['duration'] as int?,
    );
  }
}
