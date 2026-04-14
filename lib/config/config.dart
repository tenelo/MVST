import 'package:mvst/config/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { blue, green }

class Config {
  static AppThemeMode activeTheme = AppThemeMode.blue;

  static AppColors get colors {
    switch (activeTheme) {
      case AppThemeMode.blue:
        return const BlueColors();
      case AppThemeMode.green:
        return const GreenColors();
    }
  }

  /// Charge le thème sauvegardé. À appeler avant runApp().
  static Future<void> chargerTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme');
    if (saved != null) {
      activeTheme = AppThemeMode.values.firstWhere(
        (t) => t.name == saved,
        orElse: () => AppThemeMode.blue,
      );
    }
  }

  /// Sauvegarde le thème actif.
  static Future<void> sauvegarderTheme(AppThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme.name);
    activeTheme = theme;
  }
}
