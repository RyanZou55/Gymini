import 'dart:convert';

class GyminiResponse {
  final String responseText;
  final String
      actionType; // 'general_chat', 'routine_suggestion', 'analysis', 'education', 'adjustment'

  // Diagnostics
  final String? analysisInsight;
  final String? actionableAdvice;

  // Planning
  final List<SuggestedExercise>? suggestedRoutine;

  // Education
  final TechniqueGuide? techniqueGuide;

  // Adjustment
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
    // Sanitize: Sometimes AI adds markdown ```json ... ``` wrapper. We remove it.
    String cleanJson =
        jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();

    final Map<String, dynamic> data = jsonDecode(cleanJson);

    // Parse Routine
    List<SuggestedExercise>? routine;
    if (data['suggested_routine'] != null) {
      routine = (data['suggested_routine'] as List)
          .map((item) => SuggestedExercise.fromMap(item))
          .toList();
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
  }
}

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
    return SuggestedExercise(
      name: map['exercise_name'] ?? 'Unknown',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      weight: (map['weight_kg'] as num?)?.toDouble(),
    );
  }
}

class TechniqueGuide {
  final List<String> cues;
  final List<String> mistakes;

  TechniqueGuide({required this.cues, required this.mistakes});

  factory TechniqueGuide.fromMap(Map<String, dynamic> map) {
    return TechniqueGuide(
      cues: List<String>.from(map['cues'] ?? []),
      mistakes: List<String>.from(map['mistakes'] ?? []),
    );
  }
}

class ExerciseSubstitution {
  final String original;
  final String replacement;
  final String reason;

  ExerciseSubstitution(
      {required this.original,
      required this.replacement,
      required this.reason});

  factory ExerciseSubstitution.fromMap(Map<String, dynamic> map) {
    return ExerciseSubstitution(
      original: map['original_exercise'] ?? '',
      replacement: map['replacement'] ?? '',
      reason: map['reasoning'] ?? '',
    );
  }
}
