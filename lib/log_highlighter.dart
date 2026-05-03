import 'package:flutter/material.dart';

class LogHighlighter {
  static List<TextSpan> highlight(String text, bool isDark) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      spans.addAll(_highlightLine(line, isDark));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }
  
  static List<TextSpan> _highlightLine(String line, bool isDark) {
    final spans = <TextSpan>[];
    final lowerLine = line.toLowerCase();
    
    // 定义颜色
    final errorColor = isDark ? const Color(0xFFFF6B6B) : const Color(0xFFD32F2F);
    final warnColor = isDark ? const Color(0xFFFFD93D) : const Color(0xFFF9A825);
    final infoColor = isDark ? const Color(0xFF6BCB77) : const Color(0xFF388E3C);
    final debugColor = isDark ? const Color(0xFF4D96FF) : const Color(0xFF1976D2);
    final timestampColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);
    final normalColor = isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20);
    
    // 检查是否是日志级别行
    final errorPatterns = ['error', 'fatal', 'critical', 'exception', 'failed'];
    final warnPatterns = ['warn', 'warning'];
    final infoPatterns = ['info', 'information'];
    final debugPatterns = ['debug', 'trace'];
    
    // 时间戳模式
    final timestampPattern = RegExp(
      r'^\d{4}[-/]\d{2}[-/]\d{2}[\sT]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})?'
    );
    
    // 检查整行是否匹配某种级别
    Color? lineColor;
    bool isLevelLine = false;
    
    for (final pattern in errorPatterns) {
      if (lowerLine.contains(pattern)) {
        lineColor = errorColor;
        isLevelLine = true;
        break;
      }
    }
    
    if (!isLevelLine) {
      for (final pattern in warnPatterns) {
        if (lowerLine.contains(pattern)) {
          lineColor = warnColor;
          isLevelLine = true;
          break;
        }
      }
    }
    
    if (!isLevelLine) {
      for (final pattern in infoPatterns) {
        if (lowerLine.contains(pattern)) {
          lineColor = infoColor;
          isLevelLine = true;
          break;
        }
      }
    }
    
    if (!isLevelLine) {
      for (final pattern in debugPatterns) {
        if (lowerLine.contains(pattern)) {
          lineColor = debugColor;
          isLevelLine = true;
          break;
        }
      }
    }
    
    // 如果有时间戳，先高亮时间戳
    final timestampMatch = timestampPattern.firstMatch(line);
    if (timestampMatch != null) {
      final timestamp = line.substring(timestampMatch.start, timestampMatch.end);
      spans.add(TextSpan(
        text: timestamp,
        style: TextStyle(color: timestampColor, fontFamily: 'Consolas'),
      ));
      
      final rest = line.substring(timestampMatch.end);
      if (rest.isNotEmpty) {
        spans.add(TextSpan(
          text: rest,
          style: TextStyle(
            color: lineColor ?? normalColor,
            fontFamily: 'Consolas',
            fontWeight: isLevelLine ? FontWeight.w600 : FontWeight.normal,
          ),
        ));
      }
    } else {
      // 整行使用对应颜色
      spans.add(TextSpan(
        text: line,
        style: TextStyle(
          color: lineColor ?? normalColor,
          fontFamily: 'Consolas',
          fontWeight: isLevelLine ? FontWeight.w600 : FontWeight.normal,
        ),
      ));
    }
    
    return spans;
  }
  
  static bool isLogFile(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return ext == 'log' || 
           filename.toLowerCase().contains('log') ||
           filename.toLowerCase().contains('error') ||
           filename.toLowerCase().contains('debug');
  }
}
