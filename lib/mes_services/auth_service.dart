import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst/authentification/connection.dart';

class AuthService {
  // Vérifier si l'utilisateur est connecté
  static bool estConnecte() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Obtenir l'utilisateur connecté (peut être null)
  static User? getUtilisateur() {
    return FirebaseAuth.instance.currentUser;
  }

  // Obtenir l'UID de l'utilisateur connecté
  static String? getUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // Vérifier et rediriger vers connexion si non connecté
  static Future<bool> verifierEtRediriger(BuildContext context) async {
    if (!estConnecte()) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
        );
      }
      return false;
    }
    return true;
  }

  // Vérifier sans rediriger (juste retourner booléen)
  static bool verifier() {
    return estConnecte();
  }

  // Afficher un snackbar pour utilisateur non connecté
  static void afficherSnackNonConnecte(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text(
          'Vous n\'êtes pas authentifié. Connectez-vous pour accéder à cette page.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
