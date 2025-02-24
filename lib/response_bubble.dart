import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_bubble.dart';

class CodeHighlighter extends SyntaxHighlighter {
  @override
  TextSpan format(String source) {
    return TextSpan(
      style: const TextStyle(fontFamily: 'monospace'),
      text: source, // Simplified highlighting for now
    );
  }
}

class ResponseBubble extends StatelessWidget {
  final Stream<String> stream;
  final Function(String)? onComplete;

  const ResponseBubble({
    super.key,
    required this.stream,
    this.onComplete,
  });

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete?.call(''); // Notify completion with empty response
          });
          return const SizedBox.shrink(); // Don't show error in bubble
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onComplete?.call(snapshot.data!);
          });
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: MarkdownBody(
                        data: snapshot.data!,
                        selectable: true,
                        syntaxHighlighter: CodeHighlighter(),
                        styleSheet: MarkdownStyleSheet(
                          code: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontFamily: GoogleFonts.jetBrainsMono().fontFamily,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.secondaryFixedDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          p: TextStyle(
                            color: Theme.of(context).colorScheme.surface,
                            fontFamily: GoogleFonts.poppins().fontFamily,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.surface,
                        size: 18,
                      ),
                      onPressed: () =>
                          _copyToClipboard(context, snapshot.data!),
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
