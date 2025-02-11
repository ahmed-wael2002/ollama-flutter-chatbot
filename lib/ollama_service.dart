import 'package:dio/dio.dart';
import 'message.dart';

class OllamaService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:11434/api', // Local Ollama API
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Stores chat history for context
  final List<Message> _chatHistory = [];

  // Handles sending chat messages
  Future<Message> sendChat(List<Message> chatHistory, {int retries = 3}) async {
    int attempt = 0;
    while (attempt < retries) {
      try {
        final response = await _dio.post(
          '/chat', // Updated endpoint
          data: {
            "model": "deepseek-coder:6.7b",
            "messages": chatHistory.map((msg) => msg.toJson()).toList(),
            "stream": false,
          },
        );

        if (response.statusCode == 200) {
          String aiResponse = response.data["message"]["content"] ?? "No response received.";

          // Create AI response message
          Message aiMessage = Message(
            date: DateTime.now(),
            text: aiResponse,
            isUser: false,
          );

          // Add response to chat history
          _chatHistory.add(aiMessage);

          return aiMessage;
        } else {
          throw Exception("Error: ${response.statusCode}");
          // return Message(date: DateTime.now(), text: "Error: ${response.statusCode}", isUser: false);
        }
      } catch (e) {
        // rethrow;
        attempt++;
        if (attempt >= retries) {
          // return Message(date: DateTime.now(), text: "Error: $e", isUser: false);
          rethrow;
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return Message(date: DateTime.now(), text: "Error: All retries failed.", isUser: false);
  }

  // Uses chat history for contextual responses
  Future<Message> sendMessage(String userInput) async {
    // Create user message and add it to history
    Message userMessage = Message(
      date: DateTime.now(),
      text: userInput,
      isUser: true,
    );
    _chatHistory.add(userMessage);

    // Send chat history to Ollama
    return await sendChat(_chatHistory);
  }

  // Optimized version with caching to avoid redundant API calls
  final Map<String, Message> _cache = {};

  Future<Message> sendMessageWithCache(String userInput) async {
    if (_cache.containsKey(userInput)) {
      return _cache[userInput]!;
    }

    Message response = await sendMessage(userInput);
    _cache[userInput] = response;
    return response;
  }
}
