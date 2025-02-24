import 'package:flutter/material.dart';
import 'package:ollama_chatbot/chat_bubble.dart';
import 'package:ollama_chatbot/message.dart';
import 'package:ollama_chatbot/ollama_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ollama_chatbot/response_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OllamaService ollamaService = OllamaService();

  List<Message> messages = [];
  bool _isLoading = false; // Tracks API call status
  String? currentStreamingMessage;

  // Sends the user message to Ollama
  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;

    String userMessage = _controller.text.trim();
    _controller.clear();

    setState(() {
      messages.add(Message(
        date: DateTime.now(),
        text: userMessage,
        isUser: true,
      ));
      _isLoading = true;
      currentStreamingMessage = '';
    });

    _scrollToBottom();

    try {
      await ollamaService.sendChatUsingStream(messages);
    } catch (e) {
      _showError("Failed to connect to Ollama: Make sure Ollama is running");
    }
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ollama Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              children: [
                ...messages.map((msg) => ChatBubble(message: msg)),
                if (_isLoading)
                  ResponseBubble(
                    stream: ollamaService.responseStream,
                    onComplete: (finalResponse) {
                      setState(() {
                        messages.add(Message(
                          date: DateTime.now(),
                          text: finalResponse,
                          isUser: false,
                        ));
                        _isLoading = false;
                      });
                      _scrollToBottom();
                    },
                  ),
              ],
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ollamaService.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.4, // Limit width
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer, // Background color
              borderRadius: BorderRadius.circular(20), // Rounded corners
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[700]),
                border: InputBorder
                    .none, // No border since it's wrapped in a container
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
