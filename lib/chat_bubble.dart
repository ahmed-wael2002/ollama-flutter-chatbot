import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard support
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message.dart';

class CodeHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    return TextSpan(
      style: const TextStyle(fontFamily: 'monospace'),
      children: [
        WidgetSpan(
          child: HighlightView(
            source,
            language: 'dart', // Change based on expected code language
            theme: draculaTheme, // Choose a theme (e.g., draculaTheme, atomOneDarkTheme)
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }
}

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
            minWidth: 50,
            maxWidth: MediaQuery.of(context).size.width * 0.75,
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
                  padding: const EdgeInsets.only(right: 4),
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
                    syntaxHighlighter: CodeHighlighter(), // Use custom highlighter
                    styleSheet: MarkdownStyleSheet(
                      code: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryFixedDim,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      p: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontFamily: GoogleFonts.poppins().fontFamily,
                      ),
                    ),
                  ),
                ),
                if (!message.isUser)
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      color: Theme.of(context).colorScheme.surface,
                      size: 18,
                    ),
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
