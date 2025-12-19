// lib/models/meal.dart
class Meal {
  final String id;
  final DateTime timestamp; // Date AND Time
  final String type; // Breakfast, Lunch, etc.
  final String items; // "Oatmeal and Eggs"
  final int hungerRating; // 1-5

  Meal({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.items,
    required this.hungerRating,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'items': items,
      'hunger': hungerRating,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      items: map['items'],
      hungerRating: map['hunger'],
    );
  }
}
