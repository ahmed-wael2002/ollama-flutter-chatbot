import 'package:flutter/material.dart';
import 'package:ollama_chatbot/chat_bubble.dart';
import 'package:ollama_chatbot/message.dart';
import 'package:ollama_chatbot/ollama_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
    });

    _scrollToBottom();

    try {
      // Send the full chat history for multi-turn conversations
      // Message response = await ollamaService.sendMessage(userMessage);
      Message response = await ollamaService.sendChat(messages);

      setState(() {
        messages.add(response);
      });
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
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: messages[index]);
              },
            ),
          ),
          if (_isLoading) // Show loading indicator when waiting for response
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingAnimationWidget.waveDots(
                    color: Theme.of(context).colorScheme.primary,
                    size: 25,
                  ),
                  SizedBox(width: 8),
                  Text("Ollama is writing", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18),)
                ],
              ),
            ),
          _buildInputField(),
        ],
      ),
    );
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
              color: Theme.of(context).colorScheme.surfaceContainer, // Background color
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
                border: InputBorder.none, // No border since it's wrapped in a container
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
