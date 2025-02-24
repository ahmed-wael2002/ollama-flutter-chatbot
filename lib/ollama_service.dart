import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data'; // Add this import for Uint8List
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
          String aiResponse =
              response.data["message"]["content"] ?? "No response received.";

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
    return Message(
        date: DateTime.now(),
        text: "Error: All retries failed.",
        isUser: false);
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

  // Create a new StreamController for each request
  StreamController<String>? _responseStreamController;
  Stream<String>? _currentStream;

  Stream<String> get responseStream {
    _responseStreamController?.close();
    _responseStreamController = StreamController<String>.broadcast();
    _currentStream = _responseStreamController?.stream;
    return _currentStream!;
  }

  Future<void> sendChatUsingStream(List<Message> chatHistory) async {
    String fullResponse = '';

    try {
      final response = await _dio.post(
        '/chat',
        data: {
          "model": "deepseek-coder:6.7b",
          "messages": chatHistory.map((msg) => msg.toJson()).toList(),
          "stream": true,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Connection': 'keep-alive'},
        ),
      );

      final Stream<Uint8List> stream = response.data.stream;

      await for (final data in stream) {
        if (_responseStreamController?.isClosed ?? true) break;

        final String chunk = utf8.decode(data);
        if (chunk.isNotEmpty) {
          // Fixed syntax error here
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.isEmpty) continue;
            try {
              final Map<String, dynamic> json = jsonDecode(line);

              if (json.containsKey('message')) {
                final String text = json['message']['content'] ?? '';
                if (text.isNotEmpty) {
                  fullResponse += text;
                  _responseStreamController?.add(fullResponse);
                }
              }

              if (json.containsKey('done') && json['done'] == true) {
                if (!(_responseStreamController?.isClosed ?? true)) {
                  await _responseStreamController?.close();
                }
                return;
              }
            } catch (e) {
              print('Error processing chunk: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Stream error: $e');
      _responseStreamController?.addError(e);
      await _responseStreamController?.close();
    }
  }

  void dispose() {
    _responseStreamController?.close();
    _responseStreamController = null;
  }
}
