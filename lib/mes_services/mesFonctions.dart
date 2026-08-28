import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:intl/intl.dart';

// ─── Listes globales des places ───────────────────────────────────────────────
// Gérées en temps réel par Socket.IO
List<int> listeDesPlacesOccupees = [];
List<int> listeDeVerification = [];
String? idDocPourNetoyage;

// ─── Conversion des dates ─────────────────────────────────────────────────────
class ConvertirHeure {
  static String formatDate(String date) {
    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime parsedDate = inputFormat.parse(date);
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate);
  }

  static String formatDatePourCalcule(String date) {
    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime parsedDate = inputFormat.parse(date);
    return DateFormat('yyyy-MM-dd', 'fr_FR').format(parsedDate);
  }
}

// ─── Formatage des heures ─────────────────────────────────────────────────────
/// "08:00:00" → "08:00"  |  "08:00" → "08:00"
String formaterHeure(String heure) {
  final parts = heure.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return heure;
}

// ─── Nettoyage des places temporaires au lancement ───────────────────────────
// Supprime les places choisies mais jamais finalisées
// (utilisateur ayant abandonné le processus d'achat)
//
// Volontairement en http.* direct plutôt que via ApiClient : cette fonction
// est aussi invoquée depuis l'Isolate d'arrière-plan lancé au démarrage
// (main.dart, _tachesArrierePlan/Isolate.spawn). ApiClient lit le token via
// flutter_secure_storage, qui repose sur des platform channels indisponibles
// dans un Isolate secondaire — l'utiliser ici bloquerait ou planterait
// silencieusement ce chemin. L'endpoint est un nettoyage best-effort, sans
// donnée sensible en retour et sans besoin d'authentification ; il reste
// donc en dehors d'ApiClient pour fonctionner à l'identique dans les deux
// contextes (isolate et appel normal).
Future<void> suppressionPlacesTemporaires() async {
  const String apiUrl = '$kBaseUrl/process_places_temporaires.php';
  try {
    final response = await http
        .get(Uri.parse(apiUrl))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["success"]) {
      } else {}
    }
  } catch (e) {}
}

// ─── Gestion des erreurs réseau ───────────────────────────────────────────────
enum TypeErreur { connexion, serveur, autre }

TypeErreur identifierErreur(dynamic e) {
  final message = e.toString().toLowerCase();
  // Les messages d'erreur contenant ces mots-clés indiquent généralement un problème de connexion
  if (message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('connection refused') ||
      message.contains('no address associated')) {
    return TypeErreur.connexion;
    // Les codes 500, 502, 503 et les timeouts indiquent généralement un problème côté serveur
  } else if (message.contains('500') ||
      message.contains('503') ||
      message.contains('502') ||
      message.contains('timeoutexception')) {
    return TypeErreur.serveur;
  }
  // Pour tout autre type d'erreur, on retourne "autre"
  return TypeErreur.autre;
}

void afficherErreur(BuildContext context, dynamic e) {
  final type = identifierErreur(e);

  String message;
  Color couleur;
  IconData icone;

  switch (type) {
    case TypeErreur.connexion:
      message =
          'Pas de connexion internet. Vérifiez votre réseau et réessayez.';
      couleur = Colors.orange;
      icone = Icons.wifi_off;
      break;
    case TypeErreur.serveur:
      message =
          'Le serveur est temporairement indisponible. Réessayez dans quelques instants.';
      couleur = Colors.red;
      icone = Icons.cloud_off;
      break;
    case TypeErreur.autre:
      message = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      couleur = Colors.grey[800]!;
      icone = Icons.error_outline;
      break;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 5),
      backgroundColor: couleur,
      content: Row(
        children: [
          Icon(icone, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

bool petitEcran = false; // sera défini au démarrage

// ═══════════════════════════════════════════════
// CLAVIER NUMÉRIQUE ANIMÉ
// ═══════════════════════════════════════════════

class ClavierAnime extends StatelessWidget {
  final String touche;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double size;
  final bool desactive;
  final double scale;

  const ClavierAnime({
    super.key,
    required this.touche,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.size,
    this.desactive = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    (size * 0.34).clamp(20.0, 28.0);

    return _AnimatedTouche(
      touche: touche,
      onChiffre: onChiffre,
      onSupprimer: onSupprimer,
      colors: c,
      size: size,
      desactive: desactive,
      scale: scale,
    );
  }
}

// ═══════════════════════════════════════════════
// _AnimatedTouche
// ═══════════════════════════════════════════════

class _AnimatedTouche extends StatefulWidget {
  const _AnimatedTouche({
    required this.touche,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.size,
    this.desactive = false,
    this.scale = 1.0,
  });
  final String touche;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double size;
  final bool desactive;
  final double scale;

  @override
  State<_AnimatedTouche> createState() => _AnimatedToucheState();
}

class _AnimatedToucheState extends State<_AnimatedTouche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.desactive) return;
    setState(() => _highlighted = true);
    _ctrl.forward().then((_) {
      _ctrl.reverse();
      Future.delayed(const Duration(milliseconds: 130), () {
        if (mounted) setState(() => _highlighted = false);
      });
    });
    if (widget.touche == '⌫') {
      widget.onSupprimer();
    } else {
      widget.onChiffre(widget.touche);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final fontSize = (widget.size * 0.34).clamp(20.0, 28.0);
    return GestureDetector(
      onTap: widget.desactive ? null : _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size * 0.85,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _highlighted
                ? c.authAccent.withValues(alpha: 0.20)
                : widget.desactive
                ? c.authCardBackground.withValues(alpha: 0.3)
                : c.authCardBackground,
            borderRadius: BorderRadius.circular(12 * widget.scale),
            boxShadow: _highlighted
                ? [
                    BoxShadow(
                      color: c.authAccent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.touche == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: widget.desactive
                      ? c.authTextPrimary.withValues(alpha: 0.2)
                      : _highlighted
                      ? c.authAccent
                      : c.authTextPrimary,
                  size: fontSize * 0.9,
                )
              : Text(
                  widget.touche,
                  style: TextStyle(
                    color: widget.desactive
                        ? c.authTextPrimary.withValues(alpha: 0.2)
                        : _highlighted
                        ? c.authAccent
                        : c.authTextPrimary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
