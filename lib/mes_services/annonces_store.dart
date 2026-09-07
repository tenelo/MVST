import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Une annonce (notification de diffusion) recue et conservee localement.
class Annonce {
  final String id;
  final String titre;
  final String message;
  final DateTime date;

  Annonce({
    required this.id,
    required this.titre,
    required this.message,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titre': titre,
        'message': message,
        'date': date.toIso8601String(),
      };

  factory Annonce.fromJson(Map<String, dynamic> j) => Annonce(
        id: j['id']?.toString() ?? '',
        titre: j['titre']?.toString() ?? '',
        message: j['message']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      );
}

/// Stockage local des annonces (SharedPreferences, cle unique JSON).
class AnnoncesStore {
  static const String _cle = 'annonces_locales';

  /// Lit toutes les annonces, plus recentes d'abord.
  static Future<List<Annonce>> lireToutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cle);
      if (brut == null || brut.isEmpty) return [];
      final liste = jsonDecode(brut);
      if (liste is! List) return [];
      final annonces = liste
          .map((e) => Annonce.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      annonces.sort((a, b) => b.date.compareTo(a.date));
      return annonces;
    } catch (_) {
      return [];
    }
  }

  /// Ajoute une annonce (ignore si une annonce du meme id existe deja).
  static Future<void> ajouter(Annonce annonce) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final annonces = await lireToutes();
      if (annonces.any((a) => a.id == annonce.id)) return;
      annonces.add(annonce);
      await prefs.setString(
        _cle,
        jsonEncode(annonces.map((a) => a.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Supprime les annonces dont l'id est dans [ids].
  static Future<void> supprimer(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final annonces = await lireToutes();
      annonces.removeWhere((a) => ids.contains(a.id));
      await prefs.setString(
        _cle,
        jsonEncode(annonces.map((a) => a.toJson()).toList()),
      );
    } catch (_) {}
  }
}
