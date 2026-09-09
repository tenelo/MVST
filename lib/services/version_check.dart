import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mvst/services/api_client.dart';

final c = Config.colors;

class VersionCheck {
  // App = 'client' pour MVST, lien de mise a jour = Play Store.
  static const String _app = 'client';
  static const String _urlMaj =
      'https://play.google.com/store/apps/details?id=com.app.mvst';

  /// A appeler au demarrage, apres le premier frame, avec un contexte valide.
  /// Bloque l'app si la version installee < version_minimale ;
  /// sinon propose une mise a jour douce si < version_recommandee.
  static Future<void> verifier(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final installee = info.version; // ex. "1.0.0"

      final resp = await ApiClient.instance.post(
        'versions.php',
        body: {'app': _app},
        timeout: const Duration(seconds: 8),
      );
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body);
      if (data['success'] != true) return;

      final minimale = data['version_minimale']?.toString() ?? '1.0.0';
      final recommandee = data['version_recommandee']?.toString() ?? '1.0.0';

      if (!context.mounted) return;

      if (_estInferieure(installee, minimale)) {
        _afficherBlocage(context);
      } else if (_estInferieure(installee, recommandee)) {
        _afficherSuggestion(context);
      }
    } catch (_) {
      // Ne jamais bloquer l'app en cas d'erreur.
    }
  }

  /// Compare deux versions "x.y.z". Renvoie true si [a] < [b].
  static bool _estInferieure(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va < vb) return true;
      if (va > vb) return false;
    }
    return false;
  }

  static Future<void> _ouvrirMaj() async {
    final uri = Uri.parse(_urlMaj);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// Ecran BLOQUANT : impossible de fermer, impossible de continuer.
  static void _afficherBlocage(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: c.bleuFonce2),
              SizedBox(width: 10),
              Expanded(child: Text('Mise à jour requise')),
            ],
          ),
          content: const Text(
            'Une nouvelle version de l\'application est disponible et '
            'nécessaire pour continuer. Merci de mettre à jour MVST.',
          ),
          actions: [
            ElevatedButton.icon(
              onPressed: _ouvrirMaj,
              icon: const Icon(Icons.download),
              label: const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestion DOUCE : on peut fermer et continuer.
  static void _afficherSuggestion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.new_releases_outlined, color: c.bleuFonce2),
            SizedBox(width: 10),
            Expanded(child: Text('Nouvelle version disponible')),
          ],
        ),
        content: const Text(
          'Une nouvelle version de MVST est disponible. '
          'Nous vous recommandons de mettre à jour.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _ouvrirMaj();
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
}
