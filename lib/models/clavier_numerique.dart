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
    // Calcul de la taille des boutons 18% de la largeur, avec des limites min/max pour éviter les tailles extrêmes
    // la taille max est de 80 pour les très grands écrans, et min de 55 pour les petits écrans
    final btnSize = (sw * 0.18).clamp(55.0, 80.0);
    // Espacement entre les lignes, calculé à partir de la largeur de l'écran, avec des limites pour éviter les espacements trop petits ou trop grands
    final spacing = (sw * 0.05).clamp(7.0, 18.0);

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
