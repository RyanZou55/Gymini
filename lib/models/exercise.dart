class Exercise {
  final String id;
  final String workoutId;
  final String name;
  final double weight;
  final int reps;
  final int sets;

  Exercise({
    required this.id,
    required this.workoutId,
    required this.name,
    required this.weight,
    required this.reps,
    required this.sets,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'workout_id': workoutId,
    'name': name,
    'weight': weight,
    'reps': reps,
    'sets': sets,
  };
}
