import 'package:flutter/material.dart';

/// C# 语法高亮器
class CSharpHighlighter {
  // C# 关键字
  static final Set<String> _keywords = {
    'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch',
    'char', 'checked', 'class', 'const', 'continue', 'decimal', 'default',
    'delegate', 'do', 'double', 'else', 'enum', 'event', 'explicit',
    'extern', 'false', 'finally', 'fixed', 'float', 'for', 'foreach',
    'goto', 'if', 'implicit', 'in', 'int', 'interface', 'internal',
    'is', 'lock', 'long', 'namespace', 'new', 'null', 'object',
    'operator', 'out', 'override', 'params', 'private', 'protected',
    'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed', 'short',
    'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch',
    'this', 'throw', 'true', 'try', 'typeof', 'uint', 'ulong',
    'unchecked', 'unsafe', 'ushort', 'using', 'virtual', 'void',
    'volatile', 'while', 'async', 'await', 'var', 'dynamic',
    'add', 'alias', 'ascending', 'descending', 'from', 'get',
    'global', 'group', 'into', 'join', 'let', 'orderby', 'partial',
    'remove', 'select', 'set', 'value', 'where', 'yield',
  };

  // C# 类型
  static final Set<String> _types = {
    'object', 'string', 'bool', 'byte', 'sbyte', 'char', 'decimal',
    'double', 'float', 'int', 'uint', 'long', 'ulong', 'short',
    'ushort', 'void', 'DateTime', 'TimeSpan', 'Guid', 'Uri',
    'Task', 'Action', 'Func', 'IEnumerable', 'IList', 'List',
    'Dictionary', 'HashSet', 'Queue', 'Stack', 'Array',
    'Nullable', 'ValueTuple', 'Tuple', 'Exception',
    'StringBuilder', 'Stream', 'FileStream', 'MemoryStream',
    'BinaryReader', 'BinaryWriter', 'StreamReader', 'StreamWriter',
    'TextReader', 'TextWriter', 'Console', 'Math', 'Convert',
    'Enum', 'Array', 'Delegate', 'MulticastDelegate',
  };

  // 预处理指令
  static final Set<String> _preprocessor = {
    '#define', '#undef', '#if', '#elif', '#else', '#endif',
    '#warning', '#error', '#line', '#region', '#endregion',
    '#pragma', '#nullable', '#pragma warning',
  };

  /// 检测文件是否为 C# 文件
  static bool isCSharpFile(String filePath) {
    return filePath.toLowerCase().endsWith('.cs');
  }

  /// 高亮 C# 代码
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
    int i = 0;

    // 定义颜色
    final keywordColor = isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF);
    final typeColor = isDark ? const Color(0xFF4EC9B0) : const Color(0xFF267F99);
    final stringColor = isDark ? const Color(0xFFCE9178) : const Color(0xFFA31515);
    final commentColor = isDark ? const Color(0xFF6A9955) : const Color(0xFF008000);
    final numberColor = isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658);
    final preprocessorColor = isDark ? const Color(0xFF9B9B9B) : const Color(0xFF808080);
    final normalColor = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000);
    final operatorColor = isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000);

    while (i < line.length) {
      // 跳过空白
      if (line[i].trim().isEmpty) {
        int start = i;
        while (i < line.length && line[i].trim().isEmpty) {
          i++;
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: normalColor),
        ));
        continue;
      }

      // 单行注释 //
      if (i < line.length - 1 && line[i] == '/' && line[i + 1] == '/') {
        spans.add(TextSpan(
          text: line.substring(i),
          style: TextStyle(color: commentColor, fontStyle: FontStyle.italic),
        ));
        break;
      }

      // 多行注释开始 /*
      if (i < line.length - 1 && line[i] == '/' && line[i + 1] == '*') {
        int start = i;
        i += 2;
        while (i < line.length - 1 && !(line[i] == '*' && line[i + 1] == '/')) {
          i++;
        }
        if (i < line.length - 1) i += 2;
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: commentColor, fontStyle: FontStyle.italic),
        ));
        continue;
      }

      // 字符串 ""
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
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: stringColor),
        ));
        continue;
      }

      // 字符 ''
      if (line[i] == "'") {
        int start = i;
        i++;
        while (i < line.length && line[i] != "'") {
          if (line[i] == '\\' && i + 1 < line.length) {
            i += 2;
          } else {
            i++;
          }
        }
        if (i < line.length) i++;
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: stringColor),
        ));
        continue;
      }

      // 逐字字符串 @"
      if (i < line.length - 1 && line[i] == '@' && line[i + 1] == '"') {
        int start = i;
        i += 2;
        while (i < line.length) {
          if (line[i] == '"' && (i + 1 >= line.length || line[i + 1] != '"')) {
            i++;
            break;
          }
          if (line[i] == '"' && i + 1 < line.length && line[i + 1] == '"') {
            i += 2;
          } else {
            i++;
          }
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: stringColor),
        ));
        continue;
      }

      // 插值字符串 $"
      if (i < line.length - 1 && line[i] == '\$' && line[i + 1] == '"') {
        int start = i;
        i += 2;
        int braceDepth = 0;
        while (i < line.length) {
          if (line[i] == '"' && braceDepth == 0) {
            i++;
            break;
          } else if (line[i] == '{') {
            braceDepth++;
            i++;
          } else if (line[i] == '}') {
            braceDepth--;
            i++;
          } else if (line[i] == '\\' && i + 1 < line.length) {
            i += 2;
          } else {
            i++;
          }
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: stringColor),
        ));
        continue;
      }

      // 预处理指令
      if (line[i] == '#') {
        int start = i;
        while (i < line.length && !line[i].trim().isEmpty) {
          i++;
        }
        final directive = line.substring(start, i).trim();
        final isPreprocessor = _preprocessor.any((p) => directive.startsWith(p));
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(
            color: isPreprocessor ? preprocessorColor : normalColor,
            fontWeight: isPreprocessor ? FontWeight.bold : FontWeight.normal,
          ),
        ));
        continue;
      }

      // 数字
      if (_isDigit(line[i]) || (line[i] == '.' && i + 1 < line.length && _isDigit(line[i + 1]))) {
        int start = i;
        bool hasDot = line[i] == '.';
        i++;
        while (i < line.length && (_isDigit(line[i]) || line[i] == '.' || line[i] == 'f' || line[i] == 'F' || line[i] == 'd' || line[i] == 'D' || line[i] == 'm' || line[i] == 'M' || line[i] == 'l' || line[i] == 'L' || line[i] == 'u' || line[i] == 'U')) {
          if (line[i] == '.') {
            if (hasDot) break;
            hasDot = true;
          }
          i++;
        }
        spans.add(TextSpan(
          text: line.substring(start, i),
          style: TextStyle(color: numberColor),
        ));
        continue;
      }

      // 标识符或关键字
      if (_isIdentifierStart(line[i])) {
        int start = i;
        i++;
        while (i < line.length && _isIdentifierPart(line[i])) {
          i++;
        }
        final word = line.substring(start, i);

        Color color = normalColor;
        FontWeight weight = FontWeight.normal;

        if (_keywords.contains(word)) {
          color = keywordColor;
          weight = FontWeight.bold;
        } else if (_types.contains(word)) {
          color = typeColor;
        }

        spans.add(TextSpan(
          text: word,
          style: TextStyle(color: color, fontWeight: weight),
        ));
        continue;
      }

      // 操作符
      spans.add(TextSpan(
        text: line[i],
        style: TextStyle(color: operatorColor),
      ));
      i++;
    }

    return spans;
  }

  static bool _isDigit(String char) {
    return char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
  }

  static bool _isIdentifierStart(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
           (code >= 97 && code <= 122) || // a-z
           code == 95; // _
  }

  static bool _isIdentifierPart(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || // A-Z
           (code >= 97 && code <= 122) || // a-z
           (code >= 48 && code <= 57) || // 0-9
           code == 95; // _
  }
}
