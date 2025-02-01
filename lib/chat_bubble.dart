import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard support
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50, // Prevents the bubble from being too small
            maxWidth: MediaQuery.of(context).size.width * 0.75, // Adaptive max width
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.only(
                topLeft: !message.isUser ? Radius.zero : Radius.circular(20),
                topRight: message.isUser ? Radius.zero : Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4), // Space for copy button
                  child: message.isUser
                      ? SelectableText(
                    message.text,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                    ),
                  )
                      : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      code: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryFixedDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      p: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                    ),
                  ),
                ),
                if (!message.isUser) // Show copy button only for user messages
                  IconButton(
                    icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.surface, size: 18,),
                    onPressed: () => _copyToClipboard(context),
                    tooltip: 'Copy',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
