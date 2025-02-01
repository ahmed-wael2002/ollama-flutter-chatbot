import 'package:flutter/material.dart';
import 'package:ollama_chatbot/chat_bubble.dart';
import 'package:ollama_chatbot/message.dart';
import 'package:dio/dio.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:11434/api', // Ollama API base URL
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  List<Message> messages = [];
  bool _isLoading = false; // Tracks API call status

  // Sends the prompt to Ollama and returns a Markdown response
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;

    String userMessage = _controller.text;
    _controller.clear();

    // Add user message to chat
    setState(() {
      messages.add(Message(
        date: DateTime.now(),
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
    });

    // Scroll to the bottom
    _scrollToBottom();

    try {
      final response = await _dio.post(
        '/generate',
        data: {
          "model": "deepseek-coder:6.7b",
          "prompt": userMessage,
          "stream": false
        },
      );

      if (response.statusCode == 200) {
        String aiResponse = response.data["response"] ?? "No response received.";
        setState(() {
          messages.add(Message(
            date: DateTime.now(),
            text: aiResponse,
            isUser: false,
          ));
        });
      } else {
        _showError("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Failed to connect to AI: $e");
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: messages[index]);
              },
            ),
          ),
          if (_isLoading) // Show loading indicator when waiting for response
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(), // Send on Enter
                ),
              ),
              IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
