import 'package:dio/dio.dart';

class OllamaService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:11434/api', // Local Ollama API
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  Future<String> sendPromptToOllama(String prompt) async {
    try {
      final response = await _dio.post(
        '/generate',
        data: {
          "model": "deepseek-coder:6.7b",
          "prompt": prompt,
          "stream": false
        },
      );

      if (response.statusCode == 200) {
        return response.data["response"] ?? "No response received.";
      } else {
        return "Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Error: $e";
    }
  }
}
