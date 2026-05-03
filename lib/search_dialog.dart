import 'package:flutter/material.dart';
import 'settings_service.dart';

class SearchDialog extends StatefulWidget {
  final TextEditingController textController;

  const SearchDialog({
    super.key,
    required this.textController,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final SettingsService _settingsService = SettingsService();
  bool _caseSensitive = false;
  bool _wholeWord = false;
  int _currentMatchIndex = 0;
  List<TextRange> _matches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _findMatches();
  }

  void _findMatches() {
    final searchText = _searchController.text;
    final fullText = widget.textController.text;
    
    if (searchText.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = 0;
      });
      return;
    }

    final matches = <TextRange>[];
    String sourceText = fullText;
    String targetText = searchText;
    
    if (!_caseSensitive) {
      sourceText = fullText.toLowerCase();
      targetText = searchText.toLowerCase();
    }

    int start = 0;
    while (true) {
      final index = sourceText.indexOf(targetText, start);
      if (index == -1) break;
      
      if (_wholeWord) {
        final before = index > 0 ? fullText[index - 1] : ' ';
        final after = index + targetText.length < fullText.length 
            ? fullText[index + targetText.length] 
            : ' ';
        
        final isWordChar = (String c) => 
            RegExp(r'[a-zA-Z0-9\u4e00-\u9fa5]').hasMatch(c);
        
        if (isWordChar(before) || isWordChar(after)) {
          start = index + 1;
          continue;
        }
      }
      
      matches.add(TextRange(
        start: index,
        end: index + searchText.length,
      ));
      start = index + 1;
    }

    setState(() {
      _matches = matches;
      if (_currentMatchIndex >= _matches.length) {
        _currentMatchIndex = _matches.isEmpty ? 0 : _matches.length - 1;
      }
    });

    _selectCurrentMatch();
  }

  void _selectCurrentMatch() {
    if (_matches.isEmpty || _currentMatchIndex >= _matches.length) return;
    
    final match = _matches[_currentMatchIndex];
    widget.textController.selection = TextSelection(
      baseOffset: match.start,
      extentOffset: match.end,
    );
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
    });
    _selectCurrentMatch();
  }

  void _previousMatch() {
    if (_matches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _matches.length) % _matches.length;
    });
    _selectCurrentMatch();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settingsService.settings;
    final accentColor = settings.enableCustomColor 
        ? settings.accentColor 
        : const Color(0xFFD0BCFF);
    final isDark = settings.isDarkMode;
    final surfaceColor = isDark ? const Color(0xFF1C1B1F) : const Color(0xFFFEF7FF);
    final onSurfaceColor = isDark ? const Color(0xFFE6E1E5) : const Color(0xFF1D1B20);

    return Dialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '查找',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: onSurfaceColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: onSurfaceColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: onSurfaceColor),
              decoration: InputDecoration(
                hintText: '输入要查找的内容...',
                hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: accentColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: onSurfaceColor.withOpacity(0.5)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: onSurfaceColor.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: accentColor),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildCheckbox(
                  label: '区分大小写',
                  value: _caseSensitive,
                  onChanged: (value) {
                    setState(() {
                      _caseSensitive = value ?? false;
                    });
                    _findMatches();
                  },
                  accentColor: accentColor,
                  onSurfaceColor: onSurfaceColor,
                ),
                const SizedBox(width: 16),
                _buildCheckbox(
                  label: '全字匹配',
                  value: _wholeWord,
                  onChanged: (value) {
                    setState(() {
                      _wholeWord = value ?? false;
                    });
                    _findMatches();
                  },
                  accentColor: accentColor,
                  onSurfaceColor: onSurfaceColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _matches.isEmpty 
                      ? '无匹配项' 
                      : '${_currentMatchIndex + 1} / ${_matches.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurfaceColor.withOpacity(0.7),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _matches.isEmpty ? null : _previousMatch,
                      icon: Icon(Icons.arrow_upward, color: _matches.isEmpty ? onSurfaceColor.withOpacity(0.3) : accentColor),
                      tooltip: '上一个',
                    ),
                    IconButton(
                      onPressed: _matches.isEmpty ? null : _nextMatch,
                      icon: Icon(Icons.arrow_downward, color: _matches.isEmpty ? onSurfaceColor.withOpacity(0.3) : accentColor),
                      tooltip: '下一个',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Color accentColor,
    required Color onSurfaceColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: accentColor,
          checkColor: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: onSurfaceColor,
          ),
        ),
      ],
    );
  }
}
