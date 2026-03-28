import 'package:mvst/config/app_colors.dart';

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
}
