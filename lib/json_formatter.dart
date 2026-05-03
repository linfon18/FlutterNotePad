import 'dart:convert';
import 'package:flutter/material.dart';

/// JSON 格式化器 - 提供 JSON 解析、格式化和验证功能
class JsonFormatter {
  /// 检测文本是否为有效的 JSON
  static bool isValidJson(String text) {
    if (text.trim().isEmpty) return false;
    try {
      jsonDecode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 格式化 JSON 字符串（美化输出）
  static String format(String text, {String indent = '  '}) {
    if (text.trim().isEmpty) return text;
    
    try {
      final dynamic decoded = jsonDecode(text);
      final encoder = JsonEncoder.withIndent(indent);
      return encoder.convert(decoded);
    } catch (e) {
      // 如果解析失败，返回原文本
      return text;
    }
  }

  /// 压缩 JSON 字符串（去除所有空白）
  static String minify(String text) {
    if (text.trim().isEmpty) return text;
    
    try {
      final dynamic decoded = jsonDecode(text);
      return jsonEncode(decoded);
    } catch (e) {
      return text;
    }
  }

  /// 验证 JSON 并返回错误信息
  static String? validate(String text) {
    if (text.trim().isEmpty) return 'JSON 不能为空';
    
    try {
      jsonDecode(text);
      return null; // 验证通过
    } on FormatException catch (e) {
      return 'JSON 格式错误: ${e.message}';
    } catch (e) {
      return '验证错误: $e';
    }
  }

  /// 获取 JSON 的统计信息
  static JsonStats getStats(String text) {
    if (!isValidJson(text)) {
      return JsonStats(valid: false);
    }

    try {
      final dynamic decoded = jsonDecode(text);
      return _analyzeNode(decoded);
    } catch (e) {
      return JsonStats(valid: false);
    }
  }

  /// 递归分析 JSON 节点
  static JsonStats _analyzeNode(dynamic node, {JsonStats? stats}) {
    final result = stats ?? JsonStats(valid: true);
    
    if (node == null) {
      result.nullCount++;
    } else if (node is bool) {
      result.booleanCount++;
    } else if (node is num) {
      result.numberCount++;
    } else if (node is String) {
      result.stringCount++;
    } else if (node is List) {
      result.arrayCount++;
      result.arrayItemCount += node.length;
      for (final item in node) {
        _analyzeNode(item, stats: result);
      }
    } else if (node is Map) {
      result.objectCount++;
      result.keyCount += node.length;
      node.forEach((key, value) {
        result.keys.add(key.toString());
        _analyzeNode(value, stats: result);
      });
    }
    
    return result;
  }

  /// 将 JSON 转换为 Dart 类结构
  static String generateDartClass(String jsonText, String className) {
    if (!isValidJson(jsonText)) {
      return '// 无效的 JSON';
    }

    try {
      final dynamic decoded = jsonDecode(jsonText);
      final buffer = StringBuffer();
      
      buffer.writeln('class $className {');
      _generateDartFields(buffer, decoded, '  ');
      buffer.writeln();
      
      // 生成 fromJson 构造函数
      buffer.writeln('  $className.fromJson(Map<String, dynamic> json) {');
      _generateFromJson(buffer, decoded, '    ');
      buffer.writeln('  }');
      buffer.writeln();
      
      // 生成 toJson 方法
      buffer.writeln('  Map<String, dynamic> toJson() {');
      buffer.writeln('    final Map<String, dynamic> data = <String, dynamic>{};');
      _generateToJson(buffer, decoded, '    ');
      buffer.writeln('    return data;');
      buffer.writeln('  }');
      buffer.writeln('}');
      
      return buffer.toString();
    } catch (e) {
      return '// 生成失败: $e';
    }
  }

  static void _generateDartFields(StringBuffer buffer, dynamic node, String indent) {
    if (node is Map) {
      node.forEach((key, value) {
        final fieldName = _toCamelCase(key.toString());
        final type = _getDartType(value);
        buffer.writeln('$indent$type $fieldName;');
      });
    }
  }

  static void _generateFromJson(StringBuffer buffer, dynamic node, String indent) {
    if (node is Map) {
      node.forEach((key, value) {
        final fieldName = _toCamelCase(key.toString());
        buffer.writeln('$indent$fieldName = json[\'$key\'];');
      });
    }
  }

  static void _generateToJson(StringBuffer buffer, dynamic node, String indent) {
    if (node is Map) {
      node.forEach((key, value) {
        final fieldName = _toCamelCase(key.toString());
        buffer.writeln('$indent\'data\'][\'$key\'] = $fieldName;');
      });
    }
  }

  static String _getDartType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is String) return 'String';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final itemType = _getDartType(value.first);
      return 'List<$itemType>';
    }
    if (value is Map) return 'Map<String, dynamic>';
    return 'dynamic';
  }

  static String _toCamelCase(String str) {
    final parts = str.split(RegExp(r'[_-]'));
    if (parts.length <= 1) return str;
    
    return parts.first + parts.skip(1).map((p) {
      if (p.isEmpty) return '';
      return p[0].toUpperCase() + p.substring(1);
    }).join();
  }

  /// 查找 JSON 路径
  static List<String> findPaths(String jsonText, String key) {
    final paths = <String>[];
    if (!isValidJson(jsonText)) return paths;

    try {
      final dynamic decoded = jsonDecode(jsonText);
      _findPathsRecursive(decoded, key, '', paths);
    } catch (e) {
      // 忽略错误
    }
    
    return paths;
  }

  static void _findPathsRecursive(dynamic node, String targetKey, String currentPath, List<String> paths) {
    if (node is Map) {
      node.forEach((key, value) {
        final newPath = currentPath.isEmpty ? key : '$currentPath.$key';
        if (key == targetKey) {
          paths.add(newPath);
        }
        _findPathsRecursive(value, targetKey, newPath, paths);
      });
    } else if (node is List) {
      for (int i = 0; i < node.length; i++) {
        final newPath = '$currentPath[$i]';
        _findPathsRecursive(node[i], targetKey, newPath, paths);
      }
    }
  }
}

/// JSON 统计信息
class JsonStats {
  bool valid;
  int nullCount = 0;
  int booleanCount = 0;
  int numberCount = 0;
  int stringCount = 0;
  int arrayCount = 0;
  int arrayItemCount = 0;
  int objectCount = 0;
  int keyCount = 0;
  Set<String> keys = {};

  JsonStats({required this.valid});

  int get totalNodes => nullCount + booleanCount + numberCount + stringCount + arrayCount + objectCount;

  @override
  String toString() {
    if (!valid) return '无效的 JSON';
    return '''JSON 统计:
- 总节点数: $totalNodes
- 对象数: $objectCount
- 数组数: $arrayCount
- 键值对数: $keyCount
- 字符串: $stringCount
- 数字: $numberCount
- 布尔值: $booleanCount
- null: $nullCount
- 数组项: $arrayItemCount''';  }
}

/// JSON 高亮组件
class JsonHighlightWidget extends StatelessWidget {
  final String jsonText;
  final bool isDark;

  const JsonHighlightWidget({
    super.key,
    required this.jsonText,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!JsonFormatter.isValidJson(jsonText)) {
      return Text(
        jsonText,
        style: TextStyle(
          fontFamily: 'Consolas',
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black,
        ),
      );
    }

    final formatted = JsonFormatter.format(jsonText);
    final spans = _highlightJson(formatted);

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(
        fontFamily: 'Consolas',
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  List<TextSpan> _highlightJson(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      spans.addAll(_highlightLine(line));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  List<TextSpan> _highlightLine(String line) {
    final spans = <TextSpan>[];
    int i = 0;

    while (i < line.length) {
      // 跳过前导空白
      if (line[i] == ' ' || line[i] == '\t') {
        int start = i;
        while (i < line.length && (line[i] == ' ' || line[i] == '\t')) {
          i++;
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ));
        continue;
      }

      // 字符串
      if (line[i] == '"') {
        int start = i;
        i++;
        while (i < line.length && line[i] != '"') {
          if (line[i] == '\\' && i + 1 < line.length) {
            i += 2;
          } else {
            i++;
          }
        }
        if (i < line.length) i++;
        
        final str = line.substring(start, i);
        // 检查是否是键
        final isKey = i < line.length && line[i] == ':';
        
        spans.add(TextSpan(
          text: str,
          style: TextStyle(
            color: isKey 
                ? (isDark ? const Color(0xFF9CDCFE) : const Color(0xFF0451A5))
                : (isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515)),
          ),
        ));
        continue;
      }

      // 数字
      if (_isDigit(line[i]) || (line[i] == '-' && i + 1 < line.length && _isDigit(line[i + 1]))) {
        int start = i;
        i++;
        while (i < line.length && (_isDigit(line[i]) || line[i] == '.' || line[i] == 'e' || line[i] == 'E' || line[i] == '+' || line[i] == '-')) {
          i++;
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(
            color: isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658),
          ),
        ));
        continue;
      }

      // 关键字 (true, false, null)
      if (line.substring(i).startsWith('true') ||
          line.substring(i).startsWith('false') ||
          line.substring(i).startsWith('null')) {
        int start = i;
        while (i < line.length && line[i].toLowerCase() != line[i].toUpperCase()) {
          i++;
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(
            color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
            fontWeight: FontWeight.bold,
          ),
        ));
        continue;
      }

      // 其他字符（括号、冒号、逗号等）
      spans.add(TextSpan(
        text: line[i],
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
      ));
      i++;
    }

    return spans;
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }
}
