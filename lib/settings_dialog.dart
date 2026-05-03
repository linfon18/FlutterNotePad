import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'settings_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final SettingsService _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _settingsService.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _selectPhotoBackground() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    
    if (file != null) {
      _settingsService.setPhotoBackground(file.path);
    }
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
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 24,
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
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('主题设置', accentColor, onSurfaceColor),
                    const SizedBox(height: 16),
                    _buildThemeSelector(accentColor, onSurfaceColor, isDark),
                    const SizedBox(height: 24),
                    _buildSectionTitle('主题色', accentColor, onSurfaceColor),
                    const SizedBox(height: 16),
                    _buildColorPicker(accentColor, onSurfaceColor),
                    const SizedBox(height: 24),
                    _buildSectionTitle('背景设置', accentColor, onSurfaceColor),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      '启用照片背景',
                      settings.enablePhotoBackground,
                      (value) => _settingsService.setEnablePhotoBackground(value),
                      accentColor,
                      onSurfaceColor,
                    ),
                    if (settings.enablePhotoBackground) ...[
                      const SizedBox(height: 12),
                      _buildPhotoBackgroundSelector(accentColor, onSurfaceColor),
                      const SizedBox(height: 12),
                      _buildSliderTile(
                        '背景透明度',
                        settings.backgroundOpacity,
                        0.0,
                        1.0,
                        (value) => _settingsService.setBackgroundOpacity(value),
                        accentColor,
                        onSurfaceColor,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle('界面设置', accentColor, onSurfaceColor),
                    const SizedBox(height: 16),
                    _buildSliderTile(
                      '控件不透明度',
                      settings.controlOpacity,
                      0.3,
                      1.0,
                      (value) => _settingsService.setControlOpacity(value),
                      accentColor,
                      onSurfaceColor,
                    ),
                    const SizedBox(height: 32),
                    _buildAboutSection(accentColor, onSurfaceColor, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(Color accentColor, Color onSurfaceColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                size: 32,
                color: accentColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FlutterNotePad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    Text(
                      '版本 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'linfon18 @ Loft Games',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '仅 Flutter 初学入手尝试，不保证更新',
            style: TextStyle(
              fontSize: 11,
              color: onSurfaceColor.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildGithubCard(onSurfaceColor, isDark),
        ],
      ),
    );
  }

  Widget _buildGithubCard(Color onSurfaceColor, bool isDark) {
    return GestureDetector(
      onTap: () {
        // 可以在这里添加打开 GitHub 链接的功能
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF24292E) : const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF30363D) : const Color(0xFFE1E4E8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.code_outlined,
              size: 20,
              color: isDark ? const Color(0xFF8B949E) : const Color(0xFF586069),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GitHub',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8B949E) : const Color(0xFF586069),
                    ),
                  ),
                  Text(
                    'linfon18',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: onSurfaceColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accentColor, Color onSurfaceColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: onSurfaceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(Color accentColor, Color onSurfaceColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择主题风格',
            style: TextStyle(
              fontSize: 13,
              color: onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildThemeOption(
                  '自动',
                  Icons.brightness_auto,
                  !isDark,
                  () => _settingsService.setDarkMode(false),
                  accentColor,
                  onSurfaceColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  '浅色',
                  Icons.light_mode,
                  !isDark,
                  () => _settingsService.setDarkMode(false),
                  accentColor,
                  onSurfaceColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildThemeOption(
                  '深色',
                  Icons.dark_mode,
                  isDark,
                  () => _settingsService.setDarkMode(true),
                  accentColor,
                  onSurfaceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
    Color accentColor,
    Color onSurfaceColor,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : onSurfaceColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : onSurfaceColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : onSurfaceColor.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? accentColor : onSurfaceColor.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(Color accentColor, Color onSurfaceColor) {
    final colors = [
      const Color(0xFFD0BCFF),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFF03A9F4),
      const Color(0xFF00BCD4),
      const Color(0xFF009688),
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFFCDDC39),
      const Color(0xFFFFEB3B),
      const Color(0xFFFFC107),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
      const Color(0xFFF44336),
      const Color(0xFFE91E63),
      const Color(0xFF9E9E9E),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '选择主题色',
                style: TextStyle(
                  fontSize: 13,
                  color: onSurfaceColor.withOpacity(0.7),
                ),
              ),
              Switch(
                value: _settingsService.settings.enableCustomColor,
                onChanged: (value) => _settingsService.setEnableCustomColor(value),
                activeColor: accentColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = _settingsService.settings.accentColor == color;
              return GestureDetector(
                onTap: () => _settingsService.setAccentColor(color),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? onSurfaceColor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBackgroundSelector(Color accentColor, Color onSurfaceColor) {
    final settings = _settingsService.settings;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '照片背景',
            style: TextStyle(
              fontSize: 13,
              color: onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          if (settings.photoBackgroundPath != null)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(File(settings.photoBackgroundPath!)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: onSurfaceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: onSurfaceColor.withOpacity(0.2)),
              ),
              child: Center(
                child: Icon(
                  Icons.image,
                  size: 40,
                  color: onSurfaceColor.withOpacity(0.3),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectPhotoBackground,
                  icon: Icon(Icons.folder_open, color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                  label: Text(
                    '选择图片',
                    style: TextStyle(
                      color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (settings.photoBackgroundPath != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _settingsService.setPhotoBackground(null),
                  icon: Icon(Icons.delete, color: Colors.red.withOpacity(0.8)),
                  tooltip: '删除背景',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    Color accentColor,
    Color onSurfaceColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: onSurfaceColor,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accentColor;
              }
              return onSurfaceColor.withOpacity(0.5);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    Color accentColor,
    Color onSurfaceColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: onSurfaceColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceColor,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: accentColor,
            inactiveColor: onSurfaceColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}
