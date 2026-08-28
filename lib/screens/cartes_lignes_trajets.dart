import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/auth_service.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/services/api_client.dart';

const Color _kVipGold = Color(0xFFFFD700);

class CartesLignesTrajets extends StatefulWidget {
  const CartesLignesTrajets({
    super.key,
    required this.depart,
    required this.destination,
    required this.typeVoyage,
  });
  final String depart;
  final String destination;
  final String typeVoyage;

  @override
  State<CartesLignesTrajets> createState() => _CartesLignesTrajetsState();
}

class _CartesLignesTrajetsState extends State<CartesLignesTrajets> {
  bool _loading = false;

  Future<Map<String, dynamic>?> _verifierUtilisateur() async {
    if (!AuthService.estConnecte()) return null;
    try {
      final res = await ApiClient.instance.post(
        'verifierUtilisateur.php',
        body: {'idUtilisateur': AuthService.getUid()},
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == false) return null;
        final int points = data['points'] ?? 0;
        if (points == 0) {
          if (mounted) _showRestrictedDialog();
          return null;
        }
        return {
          'nom': data['nom'] ?? '',
          'prenoms': data['prenoms'] ?? '',
          'telephone': data['telephone'] ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  void _showRestrictedDialog() {
    final c = Config.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.homeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Accès restreint',
              style: TextStyle(
                color: c.homeTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Votre profil est soumis à une restriction.\nVeuillez contacter l\'administrateur MVST Mobile.',
          style: TextStyle(color: c.homeTextPrimary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _getPrix() async {
    try {
      final res = await ApiClient.instance.post(
        'getPrixDesTickets.php',
        body: {'type': widget.typeVoyage},
        timeout: const Duration(seconds: 10),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          prixDesBillets.clear();
          for (final item in List<Map<String, dynamic>>.from(data['heures'])) {
            prixDesBillets[item['axe']] = item['prix'];
          }
          return prixDesBillets['${widget.depart} ${widget.destination}'];
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _onTap() async {
    if (!AuthService.estConnecte()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final userData = await _verifierUtilisateur();
      if (userData == null) return;
      final prix = await _getPrix();
      if (prix == null) throw Exception('Prix non trouvé');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Commande(
            idUtilisateur: AuthService.getUid()!,
            nom: userData['nom'],
            prenoms: userData['prenoms'] ?? '',
            telephone: userData['telephone'],
            prixDuBillet: prix,
            depart: widget.depart,
            destination: widget.destination,
            typeVoyage: widget.typeVoyage,
            ongletOrigine: widget.typeVoyage == 'vip' ? 2 : 0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final bool isVip = widget.typeVoyage == 'vip';

    final Color accent = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color textColor = isVip ? Colors.white : c.homeTextPrimary;
    final Color subColor = isVip
        ? Colors.white38
        : c.homeTextPrimary.withValues(alpha: 0.4);
    final Color iconBg = accent.withValues(alpha: 0.10);
    final Color btnColor = isVip ? _kVipGold : c.homeButtonPrimary;

    return InkWell(
      onTap: _loading ? null : _onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isVip
                    ? Icons.airline_seat_recline_extra
                    : Icons.directions_bus_rounded,
                color: accent,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.depart} → ${widget.destination}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ligne ${widget.depart} ${widget.destination}',
                    style: TextStyle(
                      color: subColor,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: c.homeAccent,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Réserver',
                  style: TextStyle(
                    color: c.homeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
