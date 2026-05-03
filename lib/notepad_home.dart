import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_service.dart';
import 'settings_dialog.dart';
import 'search_dialog.dart';
import 'markdown_preview.dart';
import 'log_highlighter.dart';
import 'encoding_detector.dart';
import 'json_formatter.dart';
import 'csharp_highlighter.dart';

class NotePadHome extends StatefulWidget {
  const NotePadHome({super.key});

  @override
  State<NotePadHome> createState() => _NotePadHomeState();
}

class _NotePadHomeState extends State<NotePadHome> with WindowListener {
  final TextEditingController _controller = TextEditingController();
  final SettingsService _settingsService = SettingsService();
  final FocusNode _focusNode = FocusNode();
  String _currentFile = '';
  bool _isModified = false;
  bool _isMaximized = false;
  bool _isMarkdownPreview = false;
  bool _isSplitView = false;
  bool _isLogFile = false;
  bool _isJsonFile = false;
  bool _isJsonPreview = false;
  bool _isCSharpFile = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _controller.addListener(_onTextChanged);
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _controller.removeListener(_onTextChanged);
    _settingsService.removeListener(_onSettingsChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _newFile() async {
    if (_isModified) {
      final result = await _showSaveDialog();
      if (result == null) return;
      if (result) await _saveFile();
    }
    setState(() {
      _controller.clear();
      _currentFile = '';
      _isModified = false;
      _isMarkdownPreview = false;
      _isLogFile = false;
    });
  }

  Future<void> _openFile() async {
    if (_isModified) {
      final result = await _showSaveDialog();
      if (result == null) return;
      if (result) await _saveFile();
    }

    const XTypeGroup textGroup = XTypeGroup(
      label: '文本文件',
      extensions: ['txt', 'md', 'markdown', 'log', 'json', 'xml', 'yaml', 'yml', 'ini', 'conf', 'cfg', 'properties', 'bat', 'cmd', 'sh', 'py', 'js', 'ts', 'html', 'css', 'java', 'c', 'cpp', 'h', 'hpp', 'cs', 'go', 'rs', 'php', 'rb', 'swift', 'kt', 'dart'],
    );
    const XTypeGroup allGroup = XTypeGroup(
      label: '所有文件',
      extensions: [],
    );

    try {
      final XFile? file = await openFile(acceptedTypeGroups: [textGroup, allGroup]);

      if (file != null) {
        // 检查文件大小
        final fileObj = File(file.path);
        final fileSize = await fileObj.length();
        const maxSize = 10 * 1024 * 1024; // 10MB

        if (fileSize > maxSize) {
          if (mounted) {
            final shouldOpen = await _showLargeFileDialog(fileSize);
            if (shouldOpen != true) return;
          }
        }

        try {
          String content;

          // 大文件使用流式读取
          if (fileSize > 1024 * 1024) {
            // 大于 1MB 使用分段读取
            content = await _readLargeFile(file.path);
          } else {
            // 小文件直接读取
            try {
              content = await file.readAsString();
            } catch (e) {
              content = await _readWithEncoding(file.path);
            }
          }

          if (mounted) {
            setState(() {
              _controller.text = content;
              _currentFile = file.path;
              _isModified = false;
              _checkIfMarkdown();
            });
          }
        } catch (e) {
          debugPrint('读取文件失败: $e');
          if (mounted) {
            _showErrorDialog('无法读取文件', '文件可能不是文本格式或无法访问。\n错误: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('打开文件对话框失败: $e');
    }
  }

  Future<String> _readLargeFile(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    // 使用智能编码检测
    return EncodingDetector.decodeWithAutoDetect(bytes);
  }

  Future<String> _readWithEncoding(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    // 使用智能编码检测
    return EncodingDetector.decodeWithAutoDetect(bytes);
  }

  Future<bool?> _showLargeFileDialog(int fileSize) async {
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    final accentColor = settings.enableCustomColor
        ? settings.accentColor
        : const Color(0xFFD0BCFF);

    final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 8),
            Text('大文件警告', style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
          ],
        ),
        content: Text(
          '文件大小为 $sizeInMB MB，打开大文件可能会导致应用响应缓慢。\n\n是否继续打开？',
          style: TextStyle(color: isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('继续打开', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _checkIfMarkdown() {
    final ext = _currentFile.toLowerCase().split('.').last;
    if (ext == 'md' || ext == 'markdown') {
      _isMarkdownPreview = false;
    }
    _isLogFile = LogHighlighter.isLogFile(_currentFile);
    _isJsonFile = ext == 'json' || ext == 'jsonc';
    _isJsonPreview = false;
    _isCSharpFile = CSharpHighlighter.isCSharpFile(_currentFile);
  }

  Future<void> _reloadFile() async {
    if (_currentFile.isNotEmpty) {
      final file = File(_currentFile);
      if (await file.exists()) {
        final content = await file.readAsString();
        setState(() {
          _controller.text = content;
          _isModified = false;
        });
      }
    }
  }

  Future<void> _saveFile() async {
    if (_currentFile.isEmpty) {
      await _saveAsFile();
    } else {
      final file = File(_currentFile);
      await file.writeAsString(_controller.text);
      setState(() => _isModified = false);
    }
  }

  // JSON 处理方法
  void _formatJson() {
    final formatted = JsonFormatter.format(_controller.text);
    setState(() {
      _controller.text = formatted;
      _isModified = true;
    });
    _showJsonMessage('JSON 已格式化');
  }

  void _minifyJson() {
    final minified = JsonFormatter.minify(_controller.text);
    setState(() {
      _controller.text = minified;
      _isModified = true;
    });
    _showJsonMessage('JSON 已压缩');
  }

  void _validateJson() {
    final error = JsonFormatter.validate(_controller.text);
    if (error == null) {
      final stats = JsonFormatter.getStats(_controller.text);
      _showJsonValidationDialog('JSON 验证通过', stats.toString());
    } else {
      _showJsonValidationDialog('JSON 验证失败', error, isError: true);
    }
  }

  void _toggleJsonPreview() {
    setState(() {
      _isJsonPreview = !_isJsonPreview;
    });
    _showJsonMessage(_isJsonPreview ? 'JSON 高亮预览已开启' : 'JSON 高亮预览已关闭');
  }

  Future<void> _generateDartClass() async {
    final className = await _showClassNameDialog();
    if (className != null && className.isNotEmpty) {
      final dartCode = JsonFormatter.generateDartClass(_controller.text, className);
      await _showDartCodeDialog(className, dartCode);
    }
  }

  void _showJsonMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showJsonValidationDialog(String title, String content, {bool isError = false}) async {
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
          ],
        ),
        content: SelectableText(
          content,
          style: TextStyle(
            fontFamily: 'Consolas',
            fontSize: 13,
            color: isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定', style: TextStyle(color: settings.enableCustomColor ? settings.accentColor : const Color(0xFFD0BCFF))),
          ),
        ],
      ),
    );
  }

  Future<String?> _showClassNameDialog() async {
    final controller = TextEditingController(text: 'MyClass');
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Text('生成 Dart 类', style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '类名',
            hintText: '输入类名',
            labelStyle: TextStyle(color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E)),
            hintStyle: TextStyle(color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E)),
          ),
          style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20)),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('取消', style: TextStyle(color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('生成', style: TextStyle(color: settings.enableCustomColor ? settings.accentColor : const Color(0xFFD0BCFF))),
          ),
        ],
      ),
    );
  }

  Future<void> _showDartCodeDialog(String className, String code) async {
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Text('生成的 Dart 类: $className', style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
        content: Container(
          width: 600,
          height: 400,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2B2930) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'Consolas',
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              _showJsonMessage('代码已复制到剪贴板');
            },
            child: Text('复制', style: TextStyle(color: settings.enableCustomColor ? settings.accentColor : const Color(0xFFD0BCFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭', style: TextStyle(color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsFile() async {
    final FileSaveLocation? location = await getSaveLocation(
      suggestedName: 'untitled.txt',
    );
    
    if (location != null) {
      final file = File(location.path);
      await file.writeAsString(_controller.text);
      setState(() {
        _currentFile = location.path;
        _isModified = false;
        _checkIfMarkdown();
      });
    }
  }

  Future<bool?> _showSaveDialog() async {
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Text('保存更改?', style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
        content: Text('文档已修改，是否保存?', style: TextStyle(color: isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('不保存', style: TextStyle(color: settings.enableCustomColor ? settings.accentColor : const Color(0xFFD0BCFF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('保存', style: TextStyle(color: settings.enableCustomColor ? settings.accentColor : const Color(0xFFD0BCFF))),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showErrorDialog(String title, String message) {
    final settings = _settingsService.settings;
    final isDark = settings.isDarkMode;
    final accentColor = settings.enableCustomColor
        ? settings.accentColor
        : const Color(0xFFD0BCFF);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        title: Text(title, style: TextStyle(color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
        content: Text(message, style: TextStyle(color: isDark ? const Color(0xFFCAC4D0) : const Color(0xFF49454F))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定', style: TextStyle(color: accentColor)),
          ),
        ],
      ),
    );
  }

  void _showSearch() {
    showDialog(
      context: context,
      builder: (context) => SearchDialog(
        textController: _controller,
      ),
    );
  }

  void _showAboutDialog(Color accentColor, Color onSurfaceColor) {
    final isDark = _settingsService.settings.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Container(
          width: 400,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note,
                size: 64,
                color: accentColor,
              ),
              const SizedBox(height: 16),
              Text(
                'FlutterNotePad',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '版本 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '开发者',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'linfon18',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@ Loft Games',
                      style: TextStyle(
                        fontSize: 14,
                        color: onSurfaceColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '一款跨平台、小巧、便携、耐看的文本编辑器\n支持 Markdown 预览和全格式文件',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: isDark ? const Color(0xFF381E72) : Colors.white,
                minimumSize: const Size(120, 40),
              ),
              child: const Text('确定'),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Future<void> _minimizeWindow() async {
    await windowManager.minimize();
  }

  Future<void> _maximizeWindow() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  Future<void> _closeWindow() async {
    if (_isModified) {
      final result = await _showSaveDialog();
      if (result == null) return;
      if (result) await _saveFile();
    }
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settingsService.settings;
    final accentColor = settings.enableCustomColor 
        ? settings.accentColor 
        : const Color(0xFFD0BCFF);
    final isDark = settings.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Column(
          children: [
            _buildTitleBar(accentColor, isDark),
            Expanded(child: _buildEditor(accentColor, isDark)),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    final settings = _settingsService.settings;
    
    if (settings.enablePhotoBackground && settings.photoBackgroundPath != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(settings.photoBackgroundPath!)),
          fit: BoxFit.cover,
          opacity: settings.backgroundOpacity,
        ),
      );
    }
    
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1a1a2e),
          Color(0xFF16213e),
          Color(0xFF0f3460),
          Color(0xFF533483),
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildTitleBar(Color accentColor, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF);
    final onSurfaceColor = isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(_settingsService.settings.controlOpacity),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF49454F).withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: _maximizeWindow,
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      _currentFile.isEmpty 
                        ? 'FlutterNotePad ${_isModified ? "*" : ""}' 
                        : '${_currentFile.split(Platform.pathSeparator).last} ${_isModified ? "*" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildWindowButton(
            icon: Icons.remove,
            onPressed: _minimizeWindow,
            color: onSurfaceColor,
          ),
          _buildWindowButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            onPressed: _maximizeWindow,
            color: onSurfaceColor,
          ),
          _buildCloseButton(),
        ],
      ),
    );
  }

  Widget _buildWindowButton({required IconData icon, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      width: 46,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: const Color(0xFF49454F).withOpacity(0.5),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: 46,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _closeWindow,
          hoverColor: const Color(0xFFE81123),
          child: Icon(Icons.close, size: 16, color: _settingsService.settings.isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20)),
        ),
      ),
    );
  }

  Widget _buildEditor(Color accentColor, bool isDark) {
    final surfaceColor = isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF);
    final onSurfaceColor = isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20);
    final controlOpacity = _settingsService.settings.controlOpacity;

    return Row(
      children: [
        _buildSidebar(accentColor, onSurfaceColor, surfaceColor),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(controlOpacity),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF49454F).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildToolbar(accentColor, onSurfaceColor, surfaceColor),
                  Expanded(child: _buildContentArea(accentColor, onSurfaceColor, surfaceColor)),
                  _buildStatusBar(onSurfaceColor, surfaceColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(Color accentColor, Color onSurfaceColor, Color surfaceColor) {
    final isMarkdown = _currentFile.toLowerCase().endsWith('.md') || 
                       _currentFile.toLowerCase().endsWith('.markdown');
    
    return Container(
      width: 60,
      margin: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(_settingsService.settings.controlOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF49454F).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildSidebarButton(Icons.note_add_outlined, '新建', _newFile, accentColor, onSurfaceColor),
          _buildSidebarButton(Icons.folder_open_outlined, '打开', _openFile, accentColor, onSurfaceColor),
          _buildSidebarButton(Icons.save_outlined, '保存', _saveFile, accentColor, onSurfaceColor),
          Divider(color: onSurfaceColor.withOpacity(0.2), indent: 12, endIndent: 12),
          _buildSidebarButton(Icons.undo_outlined, '撤销', () {}, accentColor, onSurfaceColor),
          _buildSidebarButton(Icons.redo_outlined, '重做', () {}, accentColor, onSurfaceColor),
          if (isMarkdown) ...[
            Divider(color: onSurfaceColor.withOpacity(0.2), indent: 12, endIndent: 12),
            _buildSidebarButton(
              _isMarkdownPreview ? Icons.edit : Icons.preview,
              _isMarkdownPreview ? '编辑' : '预览',
              () {
                setState(() {
                  _isMarkdownPreview = !_isMarkdownPreview;
                });
              },
              accentColor,
              onSurfaceColor,
            ),
            _buildSidebarButton(
              _isSplitView ? Icons.view_agenda : Icons.view_column,
              _isSplitView ? '单视图' : '分屏',
              () {
                setState(() {
                  _isSplitView = !_isSplitView;
                  if (_isSplitView) _isMarkdownPreview = false;
                });
              },
              accentColor,
              onSurfaceColor,
            ),
          ],
          if (_isLogFile) ...[
            Divider(color: onSurfaceColor.withOpacity(0.2), indent: 12, endIndent: 12),
            _buildSidebarButton(
              _isModified ? Icons.visibility : Icons.edit,
              _isModified ? '查看模式' : '编辑模式',
              () {
                setState(() {
                  // 切换编辑/查看模式
                  if (_isModified) {
                    // 从编辑模式切换到查看模式，需要重新加载文件
                    _reloadFile();
                  } else {
                    // 从查看模式切换到编辑模式
                    _isModified = true;
                  }
                });
              },
              accentColor,
              onSurfaceColor,
            ),
          ],
          if (_isJsonFile) ...[
            Divider(color: onSurfaceColor.withOpacity(0.2), indent: 12, endIndent: 12),
            _buildSidebarButton(
              _isJsonPreview ? Icons.code : Icons.preview,
              _isJsonPreview ? '编辑 JSON' : '高亮预览',
              _toggleJsonPreview,
              accentColor,
              onSurfaceColor,
            ),
            _buildSidebarSubmenuButton(
              Icons.data_object,
              'JSON 工具',
              [
                _buildSubmenuItem(Icons.format_align_left, '格式化', _formatJson),
                _buildSubmenuItem(Icons.compress, '压缩', _minifyJson),
                _buildSubmenuItem(Icons.check_circle_outline, '验证', _validateJson),
                const PopupMenuDivider(),
                _buildSubmenuItem(Icons.generating_tokens, '生成 Dart 类', _generateDartClass),
              ],
              accentColor,
              onSurfaceColor,
            ),
          ],
          if (_isCSharpFile) ...[
            Divider(color: onSurfaceColor.withOpacity(0.2), indent: 12, endIndent: 12),
            _buildSidebarButton(
              _isModified ? Icons.visibility : Icons.edit,
              _isModified ? '查看模式' : '编辑模式',
              () {
                setState(() {
                  if (_isModified) {
                    _reloadFile();
                  } else {
                    _isModified = true;
                  }
                });
              },
              accentColor,
              onSurfaceColor,
            ),
          ],
          const Spacer(),
          _buildSidebarButton(Icons.settings_outlined, '设置', _showSettings, accentColor, onSurfaceColor),
          _buildSidebarButton(Icons.info_outline, '关于', () => _showAboutDialog(accentColor, onSurfaceColor), accentColor, onSurfaceColor),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(IconData icon, String tooltip, VoidCallback onPressed, Color accentColor, Color onSurfaceColor) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            hoverColor: accentColor.withOpacity(0.15),
            child: Icon(icon, size: 22, color: onSurfaceColor.withOpacity(0.8)),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSubmenuButton(
    IconData icon,
    String tooltip,
    List<PopupMenuEntry> items,
    Color accentColor,
    Color onSurfaceColor,
  ) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: PopupMenuButton(
          offset: const Offset(50, 0),
          color: _settingsService.settings.isDarkMode ? const Color(0xFF2B2930) : const Color(0xFFFEF7FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (context) => items,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: accentColor.withOpacity(0.15),
              child: Icon(icon, size: 22, color: onSurfaceColor.withOpacity(0.8)),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem _buildSubmenuItem(IconData icon, String label, VoidCallback onTap) {
    final isDark = _settingsService.settings.isDarkMode;
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
        ],
      ),
    );
  }

  Widget _buildToolbar(Color accentColor, Color onSurfaceColor, Color surfaceColor) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: const Color(0xFF49454F).withOpacity(0.3))),
      ),
      child: Row(
        children: [
          _buildToolbarButton('文件', [
            _buildMenuItem('新建', 'Ctrl+N', _newFile),
            _buildMenuItem('打开', 'Ctrl+O', _openFile),
            _buildMenuItem('保存', 'Ctrl+S', _saveFile),
            _buildMenuItem('另存为', 'Ctrl+Shift+S', _saveAsFile),
          ], onSurfaceColor),
          _buildToolbarButton('编辑', [
            _buildMenuItem('撤销', 'Ctrl+Z', () {}),
            _buildMenuItem('重做', 'Ctrl+Y', () {}),
            const PopupMenuDivider(),
            _buildMenuItem('剪切', 'Ctrl+X', () {}),
            _buildMenuItem('复制', 'Ctrl+C', () {}),
            _buildMenuItem('粘贴', 'Ctrl+V', () {}),
            const PopupMenuDivider(),
            _buildMenuItem('查找', 'Ctrl+F', _showSearch),
          ], onSurfaceColor),
          _buildToolbarButton('视图', [
            _buildMenuItem('放大字体', 'Ctrl++', () {}),
            _buildMenuItem('缩小字体', 'Ctrl+-', () {}),
          ], onSurfaceColor),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search, size: 18, color: onSurfaceColor.withOpacity(0.8)),
            onPressed: _showSearch,
            tooltip: '查找 (Ctrl+F)',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, List<PopupMenuEntry> items, Color onSurfaceColor) {
    return PopupMenuButton(
      offset: const Offset(0, 40),
      color: _settingsService.settings.isDarkMode ? const Color(0xFF2B2930) : const Color(0xFFFEF7FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, color: onSurfaceColor),
        ),
      ),
      itemBuilder: (context) => items,
    );
  }

  PopupMenuItem _buildMenuItem(String label, String shortcut, VoidCallback onTap) {
    final isDark = _settingsService.settings.isDarkMode;
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20))),
          Text(shortcut, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF938F99) : const Color(0xFF79747E))),
        ],
      ),
    );
  }

  Widget _buildContentArea(Color accentColor, Color onSurfaceColor, Color surfaceColor) {
    if (_isSplitView) {
      return Row(
        children: [
          Expanded(
            child: _buildTextArea(accentColor, onSurfaceColor, surfaceColor),
          ),
          Container(
            width: 1,
            color: onSurfaceColor.withOpacity(0.2),
          ),
          Expanded(
            child: Container(
              color: surfaceColor.withOpacity(0.3),
              child: MarkdownPreview(
                data: _controller.text,
                isDark: _settingsService.settings.isDarkMode,
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      );
    }

    if (_isMarkdownPreview) {
      return Container(
        color: surfaceColor.withOpacity(0.3),
        child: MarkdownPreview(
          data: _controller.text,
          isDark: _settingsService.settings.isDarkMode,
          accentColor: accentColor,
        ),
      );
    }

    if (_isJsonPreview && _isJsonFile) {
      return Container(
        color: surfaceColor.withOpacity(0.3),
        padding: const EdgeInsets.all(16),
        child: JsonHighlightWidget(
          jsonText: _controller.text,
          isDark: _settingsService.settings.isDarkMode,
        ),
      );
    }

    return _buildTextArea(accentColor, onSurfaceColor, surfaceColor);
  }

  Widget _buildTextArea(Color accentColor, Color onSurfaceColor, Color surfaceColor) {
    final settings = _settingsService.settings;
    
    // 如果是日志文件且不是编辑模式，显示高亮视图
    if (_isLogFile && !_isModified) {
      return _buildLogViewer(accentColor, onSurfaceColor, settings.isDarkMode);
    }
    
    // 如果是 C# 文件且不是编辑模式，显示语法高亮视图
    if (_isCSharpFile && !_isModified) {
      return _buildCSharpViewer(accentColor, onSurfaceColor, settings.isDarkMode);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontSize: 15,
          height: 1.6,
          color: onSurfaceColor,
          fontFamily: 'Consolas',
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: '开始输入...',
          hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.5)),
          contentPadding: EdgeInsets.zero,
        ),
        cursorColor: accentColor,
        cursorWidth: 2,
        cursorRadius: const Radius.circular(1),
        selectionControls: materialTextSelectionControls,
      ),
    );
  }

  Widget _buildLogViewer(Color accentColor, Color onSurfaceColor, bool isDark) {
    final spans = LogHighlighter.highlight(_controller.text, isDark);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(children: spans),
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            fontFamily: 'Consolas',
          ),
        ),
      ),
    );
  }

  Widget _buildCSharpViewer(Color accentColor, Color onSurfaceColor, bool isDark) {
    final spans = CSharpHighlighter.highlight(_controller.text, isDark);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText.rich(
          TextSpan(children: spans),
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            fontFamily: 'Consolas',
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(Color onSurfaceColor, Color surfaceColor) {
    final isMarkdown = _currentFile.toLowerCase().endsWith('.md') || 
                       _currentFile.toLowerCase().endsWith('.markdown');
    
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        border: Border(top: BorderSide(color: const Color(0xFF49454F).withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                _isModified ? '已修改' : '就绪',
                style: TextStyle(fontSize: 11, color: onSurfaceColor.withOpacity(0.7)),
              ),
              if (_currentFile.isNotEmpty) ...[
                const SizedBox(width: 16),
                Text(
                  _currentFile,
                  style: TextStyle(fontSize: 11, color: onSurfaceColor.withOpacity(0.7)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isMarkdown) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isMarkdownPreview ? 'Markdown 预览' : (_isSplitView ? '分屏模式' : 'Markdown'),
                    style: TextStyle(fontSize: 10, color: onSurfaceColor.withOpacity(0.8)),
                  ),
                ),
              ],
              if (_isLogFile) ...[
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal, size: 10, color: const Color(0xFF4CAF50)),
                      const SizedBox(width: 4),
                      Text(
                        'Log',
                        style: TextStyle(fontSize: 10, color: const Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Text(
            '${_controller.text.length} 字符 | ${_controller.text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} 词',
            style: TextStyle(fontSize: 11, color: onSurfaceColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
}
