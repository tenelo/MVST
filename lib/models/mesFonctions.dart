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

// ─── Nettoyage des places temporaires au lancement ───────────────────────────
// Supprime les places choisies mais jamais finalisées
// (utilisateur ayant abandonné le processus d'achat)
Future<void> suppressionPlacesTemporaires() async {
  const String apiUrl =
      '$kBaseUrl/process_places_temporaires.php';
  try {
    final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));
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
