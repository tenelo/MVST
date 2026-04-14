import 'package:flutter/material.dart';

abstract class AppColors {
  // ── Couleurs de base ─────────────────────────────────────────────────────
  Color get couleurDfond;
  Color get bleuClaire;
  Color get bleuFonce;
  Color get bleuFonce2;
  Color get jauneBlanc;
  Color get vertA;
  Color get vertB;
  Color get bleuA;
  Color get bleuB;

  // ── Auth ──────────────────────────────────────────────────────────────────
  Color get authBackground;
  Color get authCardBackground;
  Color get authBorder;
  Color get authAccent;
  Color get authButton;
  Color get authButtonDisabled;
  Color get authTextPrimary;
  Color get authTextSecondary;
  Color get authDialogBackground;

  // ── Home & Models ─────────────────────────────────────────────────────────
  Color get homeBackground;
  Color get homeCardBackground;
  Color get homeBordurePetiteCarte;
  Color get homeAccent;
  Color get homeTextPrimary;
  Color get homeTabSelected;
  Color get homeTabUnselected;
  Color get homeDrawerBackground;
  Color get homeBandeauBackground;
  Color get homeBandeauBorder;

  // ── Design V2 ─────────────────────────────────────────────────────────────
  Color get homeHeaderTop;
  Color get homeHeaderBottom;
  Color get homeGrandeCarte;
  Color get homeButtonPrimary;
}

// ─── Thème Bleu  ───────────────────────────────────────────────────────────
class BlueColors implements AppColors {
  const BlueColors();

  @override
  Color get couleurDfond => const Color(0xFF1288E9);
  @override
  Color get bleuClaire => const Color(0xFF004f71);
  @override
  Color get bleuFonce => const Color(0xFF0a3752);
  @override
  Color get bleuFonce2 => const Color.fromARGB(255, 11, 0, 208);
  @override
  Color get jauneBlanc => const Color(0xFFFAF4B2);
  @override
  Color get vertA => const Color(0xFF128760);
  @override
  Color get vertB => const Color(0xFF1a5441);
  @override
  Color get bleuA => const Color(0xFF1288E9);
  @override
  Color get bleuB => const Color(0xFF1D3C6A);

  // ── Auth ──────────────────────────────────────────────────────────────────
  @override
  Color get authBackground => const Color(0xFF1A2B3C);
  @override
  Color get authCardBackground => const Color(0xFF1E3A5F);
  @override
  Color get authBorder => const Color(0xFF2A5080);
  @override
  Color get authAccent => const Color(0xFF64B5F6);
  @override
  Color get authButton => const Color(0xFF1565C0);
  @override
  Color get authButtonDisabled => const Color(0xFF1E3A5F);
  @override
  Color get authTextPrimary => const Color(0xFFFFFFFF);
  @override
  Color get authTextSecondary => const Color(0x80FFFFFF);
  @override
  Color get authDialogBackground => const Color(0xFF1E3A5F);

  // ── Home ─────────────────────────────────────────────────────────────────
  @override
  Color get homeBackground => const Color(0xFFF4F7FB);
  @override
  Color get homeCardBackground => const Color(0xFFFFFFFF);
  @override
  Color get homeBordurePetiteCarte =>
      const Color.fromARGB(255, 149, 202, 255);
  @override
  Color get homeAccent => const Color(0xFFFFE082);
  @override
  Color get homeTextPrimary => const Color(0xFF1A2D3E);
  @override
  Color get homeTabSelected => const Color(0xFF1565C0);
  @override
  Color get homeTabUnselected => const Color(0xFF90A4AE);
  @override
  Color get homeDrawerBackground => const Color(0xFF0D47A1);
  @override
  Color get homeBandeauBackground => const Color(0xFFE3F2FD);
  @override
  Color get homeBandeauBorder => const Color(0xFFBBDEFB);

  // ── V2 ───────────────────────────────────────────────────────────────────
  @override
  Color get homeHeaderTop => const Color(0xFF1565C0);
  @override
  Color get homeHeaderBottom => const Color(0xFF1E88E5);
  @override
  Color get homeGrandeCarte =>
      const Color.fromARGB(92, 216, 231, 251);
  @override
  Color get homeButtonPrimary => const Color(0xFF1565C0);
}

// ─── Thème Vert  ───────────────────────────────────────────────────────────
class GreenColors implements AppColors {
  const GreenColors();

  @override
  Color get couleurDfond => const Color(0xFF004D40);
  @override
  Color get bleuClaire => const Color(0xFF80CBC4);
  @override
  Color get bleuFonce => const Color(0xFF00695C);
  @override
  Color get bleuFonce2 => const Color(0xFF004D40);
  @override
  Color get jauneBlanc => const Color(0xFFFAF4B2);
  @override
  Color get vertA => const Color(0xFF128760);
  @override
  Color get vertB => const Color(0xFF1a5441);
  @override
  Color get bleuA => const Color(0xFF26A69A);
  @override
  Color get bleuB => const Color(0xFF1B5E20);

  // ── Auth ──────────────────────────────────────────────────────────────────
  @override
  Color get authBackground => const Color(0xFF0D2318);
  @override
  Color get authCardBackground => const Color(0xFF163D2A);
  @override
  Color get authBorder => const Color(0xFF1E5C3A);
  @override
  Color get authAccent => const Color(0xFF4CAF82);
  @override
  Color get authButton => const Color(0xFF1B6B41);
  @override
  Color get authButtonDisabled => const Color(0xFF163D2A);
  @override
  Color get authTextPrimary => const Color(0xFFFFFFFF);
  @override
  Color get authTextSecondary => const Color(0x80FFFFFF);
  @override
  Color get authDialogBackground => const Color(0xFF163D2A);

  // ── Home ─────────────────────────────────────────────────────────────────
  @override
  Color get homeBackground => const Color(0xFFF4FBF7);
  @override
  Color get homeCardBackground => const Color(0xFFFFFFFF);
  @override
  Color get homeBordurePetiteCarte =>
      const Color.fromARGB(255, 201, 247, 217);
  @override
  Color get homeAccent => const Color(0xFFFFE082);
  @override
  Color get homeTextPrimary => const Color(0xFF1A3A2A);
  @override
  Color get homeTabSelected => const Color(0xFF1B6B41);
  @override
  Color get homeTabUnselected => const Color(0xFF90A4AE);
  @override
  Color get homeDrawerBackground => const Color(0xFF0D3D22);
  @override
  Color get homeBandeauBackground => const Color(0xFFE8F5EE);
  @override
  Color get homeBandeauBorder => const Color(0xFFC8E6D4);

  // ── V2 ───────────────────────────────────────────────────────────────────
  @override
  Color get homeHeaderTop => const Color(0xFF0D3D22);
  @override
  Color get homeHeaderBottom => const Color(0xFF1B6B41);
  @override
  Color get homeGrandeCarte => const Color(0xFFF0FBF4);
  @override
  Color get homeButtonPrimary => const Color(0xFF1B6B41);
}
