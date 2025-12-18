import '../../models/gymini_response.dart';

abstract class AIProviderInterface {
  Future<GyminiResponse> sendMessage({
    required String apiKey,
    required String history,
    required String userProfile,
    required String userMessage,
  });
}
