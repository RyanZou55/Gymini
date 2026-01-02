// lib/models/gymini_response.dart
import 'dart:convert';

class GyminiResponse {
  final String responseText;
  final String actionType;
  final String? analysisInsight;
  final String? actionableAdvice;
  final List<SuggestedExercise>? suggestedRoutine;
  final TechniqueGuide? techniqueGuide;
  final ExerciseSubstitution? substitution;

  GyminiResponse({
    required this.responseText,
    required this.actionType,
    this.analysisInsight,
    this.actionableAdvice,
    this.suggestedRoutine,
    this.techniqueGuide,
    this.substitution,
  });

  factory GyminiResponse.fromJson(String jsonStr) {
    print("---------------- DEBUG PARSING START ----------------");

    String cleanJson =
        jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();

    // --- FORCE PRINT FULL JSON (Chunk Method) ---
    // This splits the long string into 800-character blocks so the console
    // cannot cut it off.
    print("↓↓↓ FULL RAW JSON BELOW ↓↓↓");
    const int chunkSize = 800;
    for (int i = 0; i < cleanJson.length; i += chunkSize) {
      int end =
          (i + chunkSize < cleanJson.length) ? i + chunkSize : cleanJson.length;
      print(cleanJson.substring(i, end));
    }
    print("↑↑↑ END RAW JSON ↑↑↑");
    // --------------------------------------------

    try {
      final Map<String, dynamic> data = jsonDecode(cleanJson);
      print("DEBUG: Action Type: ${data['action_type']}");

      // Parse Routine
      List<SuggestedExercise>? routine;
      if (data['suggested_routine'] != null) {
        routine = (data['suggested_routine'] as List).map((item) {
          return SuggestedExercise.fromMap(item);
        }).toList();

        print("\n--- 📋 PARSED ROUTINE DETAILS ---");
        for (var ex in routine) {
          print(">> Exercise: ${ex.name}");
          print(
              "   Sets: ${ex.sets} | Reps: ${ex.reps} | Weight: ${ex.weight}kg");
        }
        print("----------------------------------\n");
      }

      // Parse Technique
      TechniqueGuide? tech;
      if (data['technique_guide'] != null) {
        tech = TechniqueGuide.fromMap(data['technique_guide']);
      }

      // Parse Substitution
      ExerciseSubstitution? sub;
      if (data['substitution'] != null) {
        sub = ExerciseSubstitution.fromMap(data['substitution']);
      }

      return GyminiResponse(
        responseText: data['response_text'] ?? "...",
        actionType: data['action_type'] ?? "general_chat",
        analysisInsight: data['analysis_insight'],
        actionableAdvice: data['actionable_advice'],
        suggestedRoutine: routine,
        techniqueGuide: tech,
        substitution: sub,
      );
    } catch (e) {
      print("!!! CRITICAL JSON DECODE ERROR: $e");
      return GyminiResponse(
          responseText: "Error: $e", actionType: "general_chat");
    }
  }
}

// ... (Keep SuggestedExercise, TechniqueGuide, and ExerciseSubstitution classes exactly as they are) ...
class SuggestedExercise {
  final String name;
  final int sets;
  final int reps;
  final double? weight;

  SuggestedExercise(
      {required this.name,
      required this.sets,
      required this.reps,
      this.weight});

  factory SuggestedExercise.fromMap(Map<String, dynamic> map) {
    double? parseWeight() {
      var val = map['weight_kg'] ?? map['weight'] ?? map['load'];
      return (val as num?)?.toDouble();
    }

    return SuggestedExercise(
      name: map['exercise_name'] ?? map['exercise'] ?? 'Unknown',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: parseWeight(),
    );
  }
}

class TechniqueGuide {
  final List<String> cues;
  final List<String> mistakes;
  TechniqueGuide({required this.cues, required this.mistakes});
  factory TechniqueGuide.fromMap(Map<String, dynamic> map) => TechniqueGuide(
      cues: List<String>.from(map['cues'] ?? []),
      mistakes: List<String>.from(map['mistakes'] ?? []));
}

class ExerciseSubstitution {
  final String original;
  final String replacement;
  final String reason;
  ExerciseSubstitution(
      {required this.original,
      required this.replacement,
      required this.reason});
  factory ExerciseSubstitution.fromMap(Map<String, dynamic> map) =>
      ExerciseSubstitution(
          original: map['original_exercise'] ?? '',
          replacement: map['replacement'] ?? '',
          reason: map['reasoning'] ?? '');
}
