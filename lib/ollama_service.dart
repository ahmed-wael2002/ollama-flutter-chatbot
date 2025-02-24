import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'message.dart';

class OllamaService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:11434/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final List<Message> _chatHistory = [];
  final Map<String, CachedResponse> _cache = {};

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

  Future<Message> sendMessage(String userInput) async {
    // Check cache first
    if (_cache.containsKey(userInput)) {
      final cached = _cache[userInput]!;
      if (!cached.isExpired(DateTime.now())) {
        return cached.response;
      } else {
        _cache.remove(userInput); // Remove expired cache entry
      }
    }

    Message userMessage = Message(
      date: DateTime.now(),
      text: userInput,
      isUser: true,
    );
    _chatHistory.add(userMessage);

    final response = await sendChat(_chatHistory);
    _cache[userInput] = CachedResponse(response);
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

  final _responseBuffer = StringBuffer();
  bool _isProcessingChunk = false;

  Future<void> sendChatUsingStream(List<Message> chatHistory) async {
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
      _responseBuffer.clear();

      await for (final data in stream) {
        if (_responseStreamController?.isClosed ?? true) break;

        final String chunk = utf8.decode(data);
        if (chunk.isEmpty) continue;

        await _processStreamChunk(chunk);
      }
    } catch (e) {
      print('Stream error: $e');
      if (!(_responseStreamController?.isClosed ?? true)) {
        _responseStreamController?.addError(e);
      }
      rethrow; // Rethrow to be caught by the UI layer
    }
  }

  Future<void> _processStreamChunk(String chunk) async {
    if (_isProcessingChunk) return;
    _isProcessingChunk = true;

    try {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.isEmpty) continue;

        try {
          final json = jsonDecode(line);

          if (json.containsKey('message')) {
            final String text = json['message']['content'] ?? '';
            if (text.isNotEmpty) {
              _responseBuffer.write(text);
              _responseStreamController?.add(_responseBuffer.toString());
            }
          }

          if (json['done'] == true) {
            await _responseStreamController?.close();
            return;
          }
        } catch (e) {
          print('Error processing chunk: $e');
        }
      }
    } finally {
      _isProcessingChunk = false;
    }
  }

  void clearExpiredCache() {
    final now = DateTime.now();
    _cache.removeWhere((_, cached) => cached.isExpired(now));
  }

  void closeStream() {
    if (!(_responseStreamController?.isClosed ?? true)) {
      _responseStreamController?.close();
    }
    _responseStreamController = null;
    _responseBuffer.clear();
  }

  void dispose() {
    closeStream();
    _cache.clear();
  }
}

class CachedResponse {
  final Message response;
  final DateTime expiry;

  CachedResponse(this.response)
      : expiry = DateTime.now().add(const Duration(minutes: 30));

  bool isExpired(DateTime now) => now.isAfter(expiry);
}
