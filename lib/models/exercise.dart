// lib/models/exercise.dart
class Exercise {
  final String id;
  final String name;
  final int sets;
  final int reps;
  final double weight;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight'] ?? 0.0).toDouble(),
    );
  }
}
