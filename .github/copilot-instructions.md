# Gymini — Copilot Instructions

Summary
- Small local-first Flutter app that logs workouts and lets the user "chat" with an AI coach (Gymini) that analyzes local workout history.

Key Components (big picture)
- lib/features/* — UI screens: `LogWorkoutScreen` and `ChatScreen`.
- lib/services/* — Service layer:
  - `DatabaseService` — singleton wrapper around `sqflite` (local SQLite). Schema lives in `_initDatabase()` (tables: `workouts`, `exercises`).
  - `AIService` — builds a *system prompt* from local workout history and sends it to Gemini via `google_generative_ai` (model: `gemini-pro`).
- lib/models/* — `Workout` and `Exercise` model objects. Note: `Workout.toMap()` does *not* include exercises (exercises inserted separately).

Important patterns & project-specific behavior
- Local-first context for AI: The AI is intentionally restricted to use the local DB as its only context. The single source of truth for that prompt is:
  - `DatabaseService.getFullWorkoutHistoryAsText()` — this method formats historical workouts into a human-readable text block and is the *exact* context sent to Gemini. It's the primary integration point between data and AI.
- IDs: UUIDs are used for `id` and `workout_id` (see `uuid` usage in `LogWorkoutScreen`).
- DB column naming: snake_case (`workout_id`) while Dart uses camelCase in model properties.
- Singleton DB: `DatabaseService` is a singleton via a factory constructor — expect one DB connection across the app.

Where to edit for AI behavior
- `lib/services/ai_service.dart`:
  - Replace `static const String _apiKey = 'YOUR_GEMINI_API_KEY'` with an application-specific secret mechanism (env vars, `--dart-define`, or secure storage) — currently it's a placeholder and must be replaced to run.
  - The system prompt is built inline; any change to how the AI is instructed should be done here. Be careful: the history string can grow—consider truncation or summarization if you hit model token limits.

Developer workflows & commands
- Run app: `flutter run` (or `flutter run -d <device>` for specific devices)
- Run tests: `flutter test` (there are currently no tests; good first targets: `DatabaseService.getFullWorkoutHistoryAsText()` formatting and `DatabaseService.insertWorkout()` behavior)
- Debugging data flow: reproduce the AI behavior by:
  1. Run the app
  2. Add a workout using **Log Workout** screen
  3. Open **Chat with Coach** and ask a question — the AI response comes from `AIService.askGymini()` which uses DB history
- Inspecting DB: `sqflite` stores DB in platform-specific app storage (use logs or add a temporary path print in `_initDatabase()` to find the file path for direct inspection with SQLite tools.

Testing & recommended quick checks for PR reviewers
- Confirm `getFullWorkoutHistoryAsText()` output format (per-workout bullet lines) when insertion order and date ordering changes.
- Validate that `insertWorkout()` inserts both `workouts` and corresponding `exercises` rows.
- For AI tests, mock `GenerativeModel` calls and assert prompt content contains expected lines from history.

Helpful examples (concrete references)
- System prompt example (constructed in `lib/services/ai_service.dart`):

  "You are an elite gym coach named Gymini. Analyze the following training logs and answer the user's question based strictly on this data. If the logs don't support the answer, mention that.\n\n${history}\n\nUser Question: <user question>"

- DB formatting (from `getFullWorkoutHistoryAsText()`):
  - "- Date: 2024-01-01. Exercises: Bench Press (80.0kg x 5 reps, 3 sets), Squat (100.0kg x 5 reps, 3 sets)"

Security & operational notes ⚠️
- **Do not** commit real API keys. Replace the `_apiKey` placeholder with a secure mechanism before running in production.
- Be mindful of model token limits: long histories can exceed limits; implement summarization or time-window filters when scaling.

If something's unclear or you'd like me to expand any section (examples, testing checklists, or a CI checklist), tell me which part to iterate on. ✅
