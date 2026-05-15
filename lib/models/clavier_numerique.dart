import 'package:flutter/material.dart';
import 'package:mvst/mes_services/mesFonctions.dart';

class ClavierNumerique extends StatelessWidget {
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double sw;
  final bool desactive;
  final double scale;

  const ClavierNumerique({
    super.key,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.sw,
    this.desactive = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final touches = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    final btnSize = (sw * 0.20).clamp(65.0, 90.0);
    final spacing = (sw * 0.06).clamp(8.0, 20.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
      child: Column(
        children: touches.map((ligne) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing * 0.35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ligne.map((touche) {
                if (touche.isEmpty) {
                  return SizedBox(width: btnSize, height: btnSize * 0.85);
                }
                return ClavierAnime(
                  touche: touche,
                  onChiffre: onChiffre,
                  onSupprimer: onSupprimer,
                  colors: c,
                  size: btnSize,
                  desactive: desactive,
                  scale: scale,
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
