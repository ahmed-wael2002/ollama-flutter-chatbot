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
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty || _isLoading) return;

    _controller.clear();
    FocusScope.of(context).unfocus(); // Hide keyboard after sending

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
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        currentStreamingMessage = null;
      });

      ollamaService.closeStream();

      String errorMessage = "Connection failed: ";
      if (e.toString().contains("Connection refused")) {
        errorMessage += "Please check if Ollama is running";
      } else {
        errorMessage += e.toString();
      }

      _showError(errorMessage);
    }
  }

  void _showError(String errorMessage) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ollama Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                messages.clear();
                _isLoading = false;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length + (_isLoading ? 1 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    if (index == messages.length && _isLoading) {
                      return ResponseBubble(
                        stream: ollamaService.responseStream,
                        onComplete: (finalResponse) {
                          setState(() {
                            if (finalResponse.isNotEmpty) {
                              messages.add(Message(
                                date: DateTime.now(),
                                text: finalResponse,
                                isUser: false,
                              ));
                            }
                            _isLoading = false;
                          });
                          _scrollToBottom();
                        },
                      );
                    }
                    return ChatBubble(message: messages[index]);
                  },
                ),
              ),
            ),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    ollamaService.dispose();
    ollamaService.closeStream(); // Ensure stream is closed when disposing
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 3,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: _isLoading ? null : _sendMessage,
            icon: Icon(
              _isLoading ? Icons.hourglass_empty : Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
