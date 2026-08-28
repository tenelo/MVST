import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/services/api_client.dart';
import 'package:mvst/services/token_storage.dart';

/// Utilisateur authentifié, indépendamment de la source (token Laravel ;
/// en transition, une session Firebase peut encore alimenter la même forme
/// depuis home.dart le temps que le reste de l'app migre).
class AppUser {
  const AppUser({required this.uid, this.displayName});
  final String uid;
  final String? displayName;
}

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // ── Cache en mémoire ──────────────────────────────────────────────────
  // Alimenté par [chargerDepuisStorage], appelé après un login Laravel
  // réussi (connection.dart). Le routage de démarrage (relire ce cache au
  // relancement de l'app, dans main.dart) est traité séparément, à venir.
  static String? _token;
  static String? _idUtilisateur;
  static String? _nomUtilisateur;

  static Future<void> chargerDepuisStorage() async {
    _token = await TokenStorage.getToken();
    _idUtilisateur = await _storage.read(key: 'user_idUtilisateur');
    _nomUtilisateur = await _storage.read(key: 'user_name');
  }

  // Vérifier si l'utilisateur est connecté (token Laravel présent)
  static bool estConnecte() {
    return _token != null;
  }

  // Obtenir l'utilisateur connecté (peut être null)
  static AppUser? getUtilisateur() {
    if (_idUtilisateur == null) return null;
    return AppUser(uid: _idUtilisateur!, displayName: _nomUtilisateur);
  }

  // Obtenir l'idUtilisateur de l'utilisateur connecté
  static String? getUid() {
    return _idUtilisateur;
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

  // ── Déconnexion centralisée ─────────────────────────────────────────────
  // Point unique appelé par home.dart et pin_unlock.dart, pour éviter que
  // les deux endroits divergent sur ce qui est réellement nettoyé.
  static Future<void> deconnexion() async {
    // a) Révocation du token côté serveur. La déconnexion locale ne doit
    // jamais être bloquée par un souci réseau.
    try {
      await ApiClient.instance.post('logout');
    } catch (_) {}

    // b) Token local.
    await TokenStorage.deleteToken();

    // c) Identité locale + cache interne.
    await _storage.delete(key: 'user_idUtilisateur');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'user_pin');
    _token = null;
    _idUtilisateur = null;
    _nomUtilisateur = null;

    // d) Vieille session Firebase éventuelle.
    await FirebaseAuth.instance.signOut();
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
