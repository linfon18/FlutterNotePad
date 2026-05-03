import 'package:flutter/material.dart';
import 'settings_service.dart';
import 'notepad_home.dart';

class NotePadApp extends StatefulWidget {
  const NotePadApp({super.key});

  @override
  State<NotePadApp> createState() => _NotePadAppState();
}

class _NotePadAppState extends State<NotePadApp> {
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

  @override
  Widget build(BuildContext context) {
    final settings = _settingsService.settings;
    final accentColor = settings.enableCustomColor 
        ? settings.accentColor 
        : const Color(0xFFD0BCFF);
    final isDark = settings.isDarkMode;

    return MaterialApp(
      title: 'FlutterNotePad',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(accentColor, isDark),
      home: const NotePadHome(),
    );
  }

  ThemeData _buildTheme(Color accentColor, bool isDark) {
    final onAccentColor = _getOnColor(accentColor);
    
    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: accentColor,
          onPrimary: onAccentColor,
          primaryContainer: accentColor.withOpacity(0.25),
          onPrimaryContainer: accentColor,
          secondary: const Color(0xFFCCC2DC),
          onSecondary: const Color(0xFF332D41),
          secondaryContainer: const Color(0xFF4A4458),
          onSecondaryContainer: const Color(0xFFE8DEF8),
          surface: const Color(0xFF1C1B1F),
          onSurface: const Color(0xFFE6E1E5),
          surfaceVariant: const Color(0xFF49454F),
          onSurfaceVariant: const Color(0xFFCAC4D0),
          background: const Color(0xFF141218),
          onBackground: const Color(0xFFE6E1E5),
          outline: const Color(0xFF938F99),
          outlineVariant: const Color(0xFF49454F),
        ),
        scaffoldBackgroundColor: const Color(0xFF141218),
        fontFamily: 'Segoe UI',
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor;
            }
            return const Color(0xFF938F99);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor.withOpacity(0.3);
            }
            return const Color(0xFF49454F);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accentColor,
          inactiveTrackColor: const Color(0xFF49454F),
          thumbColor: accentColor,
          overlayColor: accentColor.withOpacity(0.1),
        ),
        iconTheme: IconThemeData(color: accentColor),
        primaryIconTheme: IconThemeData(color: accentColor),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: accentColor,
          onPrimary: Colors.white,
          primaryContainer: accentColor.withOpacity(0.2),
          onPrimaryContainer: accentColor,
          secondary: const Color(0xFF625B71),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFE8DEF8),
          onSecondaryContainer: const Color(0xFF1D192B),
          surface: const Color(0xFFFEF7FF),
          onSurface: const Color(0xFF1D1B20),
          surfaceVariant: const Color(0xFFE7E0EC),
          onSurfaceVariant: const Color(0xFF49454F),
          background: const Color(0xFFFFFBFE),
          onBackground: const Color(0xFF1D1B20),
          outline: const Color(0xFF79747E),
          outlineVariant: const Color(0xFFCAC4D0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFBFE),
        fontFamily: 'Segoe UI',
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor;
            }
            return const Color(0xFF79747E);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor.withOpacity(0.3);
            }
            return const Color(0xFFE7E0EC);
          }),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accentColor,
          inactiveTrackColor: const Color(0xFFE7E0EC),
          thumbColor: accentColor,
          overlayColor: accentColor.withOpacity(0.1),
        ),
        iconTheme: IconThemeData(color: accentColor),
        primaryIconTheme: IconThemeData(color: accentColor),
      );
    }
  }

  Color _getOnColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
