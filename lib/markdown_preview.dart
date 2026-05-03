import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'settings_service.dart';

class MarkdownPreview extends StatelessWidget {
  final String data;
  final bool isDark;
  final Color accentColor;

  const MarkdownPreview({
    super.key,
    required this.data,
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseTextColor = isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20);
    final secondaryColor = isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F);
    final codeBackground = isDark ? const Color(0xFF2B2930) : const Color(0xFFE7E0EC);
    final blockquoteColor = isDark ? const Color(0xFF49454F) : const Color(0xFFE7E0EC);

    return Markdown(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: baseTextColor,
        ),
        h1: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: accentColor,
          height: 1.4,
        ),
        h2: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentColor,
          height: 1.4,
        ),
        h3: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: accentColor,
          height: 1.4,
        ),
        h4: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: baseTextColor,
          height: 1.4,
        ),
        h5: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: baseTextColor,
          height: 1.4,
        ),
        h6: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
          height: 1.4,
        ),
        em: TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: baseTextColor,
        ),
        strong: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: baseTextColor,
        ),
        code: TextStyle(
          fontSize: 14,
          fontFamily: 'Consolas',
          backgroundColor: codeBackground,
          color: accentColor,
        ),
        codeblockPadding: const EdgeInsets.all(16),
        codeblockDecoration: BoxDecoration(
          color: codeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: secondaryColor,
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
          ),
          color: blockquoteColor.withOpacity(0.3),
        ),
        listBullet: TextStyle(
          fontSize: 15,
          color: accentColor,
        ),
        a: TextStyle(
          fontSize: 15,
          color: accentColor,
          decoration: TextDecoration.underline,
        ),
        tableHead: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: baseTextColor,
        ),
        tableBody: TextStyle(
          fontSize: 14,
          color: baseTextColor,
        ),
        tableBorder: TableBorder.all(
          color: secondaryColor.withOpacity(0.3),
          width: 1,
        ),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: secondaryColor.withOpacity(0.3), width: 1),
          ),
        ),
      ),
    );
  }
}
