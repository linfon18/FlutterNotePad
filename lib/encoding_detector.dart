import 'dart:convert';
import 'package:fast_gbk/fast_gbk.dart';

/// 编码检测器 - 自动检测并解码各种编码的文本
class EncodingDetector {
  /// 检测字节数据的编码并解码为字符串
  static String decodeWithAutoDetect(List<int> bytes) {
    if (bytes.isEmpty) return '';

    // 1. 首先检查 BOM (Byte Order Mark)
    final bomEncoding = _detectBOM(bytes);
    if (bomEncoding != null) {
      return _decodeWithBOM(bytes, bomEncoding);
    }

    // 2. 尝试 UTF-8 解码并验证
    final utf8Result = _tryDecodeUTF8(bytes);
    if (utf8Result.isValid) {
      return utf8Result.text;
    }

    // 3. 检测是否包含中文编码特征
    final hasChineseChars = _hasChineseEncodingPattern(bytes);
    if (hasChineseChars) {
      // 尝试 GBK 解码
      try {
        return gbk.decode(bytes);
      } catch (e) {
        // GBK 解码失败，继续尝试其他方式
      }
    }

    // 4. 尝试 GBK 解码（即使未检测到中文特征，也可能是 GBK）
    try {
      final gbkText = gbk.decode(bytes);
      // 检查解码结果是否合理
      if (!_containsGarbledText(gbkText)) {
        return gbkText;
      }
    } catch (e) {
      // GBK 解码失败
    }

    // 5. 如果 UTF-8 解码有结果但验证失败，返回 UTF-8 结果
    if (utf8Result.text.isNotEmpty) {
      return utf8Result.text;
    }

    // 6. 最后回退到 Latin-1 (ISO-8859-1) - 单字节编码，不会失败
    return latin1.decode(bytes, allowInvalid: true);
  }

  /// 检测 BOM
  static Encoding? _detectBOM(List<int> bytes) {
    if (bytes.length >= 3) {
      // UTF-8 BOM: EF BB BF
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        return utf8;
      }
    }
    if (bytes.length >= 2) {
      // UTF-16 BE BOM: FE FF
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        return _UTF16BEEncoding();
      }
      // UTF-16 LE BOM: FF FE
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        return _UTF16LEEncoding();
      }
    }
    return null;
  }

  /// 使用 BOM 解码
  static String _decodeWithBOM(List<int> bytes, Encoding encoding) {
    if (encoding == utf8) {
      // 跳过 UTF-8 BOM
      return utf8.decode(bytes.sublist(3));
    }
    return encoding.decode(bytes);
  }

  /// 尝试 UTF-8 解码并验证
  static _DecodeResult _tryDecodeUTF8(List<int> bytes) {
    try {
      final text = utf8.decode(bytes, allowMalformed: false);
      // 检查是否包含大量替换字符或其他乱码特征
      if (_containsGarbledText(text)) {
        return _DecodeResult(text: text, isValid: false);
      }
      return _DecodeResult(text: text, isValid: true);
    } catch (e) {
      // 解码失败，包含无效 UTF-8 序列
      return _DecodeResult(
        text: utf8.decode(bytes, allowMalformed: true),
        isValid: false,
      );
    }
  }

  /// 检测是否包含中文编码特征（GBK/GB2312）
  static bool _hasChineseEncodingPattern(List<int> bytes) {
    int gbkPatternCount = 0;
    int totalDoubleByte = 0;

    for (int i = 0; i < bytes.length - 1; i++) {
      final b1 = bytes[i];
      final b2 = bytes[i + 1];

      // 检查双字节字符
      if (b1 >= 0x80) {
        totalDoubleByte++;
        // GBK 汉字区: 0xB0A1 - 0xF7FE
        if ((b1 >= 0xB0 && b1 <= 0xF7) &&
            ((b2 >= 0xA1 && b2 <= 0xFE) || (b2 >= 0x40 && b2 <= 0x7E))) {
          gbkPatternCount++;
        }
      }
    }

    // 如果双字节字符中大部分是 GBK 模式，则认为是中文编码
    if (totalDoubleByte > 10 && gbkPatternCount > totalDoubleByte * 0.5) {
      return true;
    }

    return false;
  }

  /// 检查文本是否包含乱码特征
  static bool _containsGarbledText(String text) {
    // 检查替换字符
    final replacementCount = text.runes.where((r) => r == 0xFFFD).length;
    if (replacementCount > text.length * 0.01) {
      return true;
    }

    // 检查控制字符（除了常见的换行、制表符等）
    final controlCharCount = text.runes.where((r) {
      return r < 32 && r != 9 && r != 10 && r != 13;
    }).length;
    if (controlCharCount > text.length * 0.05) {
      return true;
    }

    return false;
  }

  /// 编码字符串为 GBK 字节
  static List<int> encodeGBK(String text) {
    return gbk.encode(text);
  }
}

class _DecodeResult {
  final String text;
  final bool isValid;

  _DecodeResult({required this.text, required this.isValid});
}

/// UTF-16 BE 编码
class _UTF16BEEncoding extends Encoding {
  const _UTF16BEEncoding();

  @override
  Converter<List<int>, String> get decoder => _UTF16BEDecoder();

  @override
  Converter<String, List<int>> get encoder => _UTF16BEEncoder();

  @override
  String get name => 'utf-16be';
}

class _UTF16BEDecoder extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length - 1; i += 2) {
      final codeUnit = (input[i] << 8) | input[i + 1];
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }
}

class _UTF16BEEncoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String input) {
    final result = <int>[];
    for (final codeUnit in input.codeUnits) {
      result.add((codeUnit >> 8) & 0xFF);
      result.add(codeUnit & 0xFF);
    }
    return result;
  }
}

/// UTF-16 LE 编码
class _UTF16LEEncoding extends Encoding {
  const _UTF16LEEncoding();

  @override
  Converter<List<int>, String> get decoder => _UTF16LEDecoder();

  @override
  Converter<String, List<int>> get encoder => _UTF16LEEncoder();

  @override
  String get name => 'utf-16le';
}

class _UTF16LEDecoder extends Converter<List<int>, String> {
  @override
  String convert(List<int> input) {
    final buffer = StringBuffer();
    for (int i = 0; i < input.length - 1; i += 2) {
      final codeUnit = input[i] | (input[i + 1] << 8);
      buffer.writeCharCode(codeUnit);
    }
    return buffer.toString();
  }
}

class _UTF16LEEncoder extends Converter<String, List<int>> {
  @override
  List<int> convert(String input) {
    final result = <int>[];
    for (final codeUnit in input.codeUnits) {
      result.add(codeUnit & 0xFF);
      result.add((codeUnit >> 8) & 0xFF);
    }
    return result;
  }
}
