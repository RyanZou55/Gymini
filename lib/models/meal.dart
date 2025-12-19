// lib/models/meal.dart
class Meal {
  final String id;
  final DateTime timestamp;
  final String type;
  final String items;
  final int hungerRatingBefore;
  final int hungerRatingAfter;

  Meal({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.items,
    required this.hungerRatingBefore,
    required this.hungerRatingAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'items': items,
      'hunger_before': hungerRatingBefore,
      'hunger_after': hungerRatingAfter,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      type: map['type'],
      items: map['items'],
      hungerRatingBefore: map['hunger_before'] ?? 3, // Default if missing
      hungerRatingAfter: map['hunger_after'] ?? 4, // Default if missing
    );
  }
}
