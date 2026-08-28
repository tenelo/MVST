import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/services/api_client.dart';

// ── VIP constants ─────────────────────────────────────────────────────────────
final Color vertVIP = const Color.fromARGB(255, 2, 136, 80);

// ── Helper: parse "Ferké Abidjan" → (depart, destination) ────────────────────
(String, String) _parseAxe(String axe) {
  final parts = axe.trim().split(' ');
  if (parts.length < 2) return (axe, axe);
  return (parts[0], parts.sublist(1).join(' '));
}

class InformationPrix extends StatefulWidget {
  const InformationPrix({super.key});

  @override
  State<InformationPrix> createState() => _InformationPrixState();
}

class _InformationPrixState extends State<InformationPrix> {
  late final Future<List<List<InfosTarifs>>> _tarifsFuture = Future.wait([
    _chargerStandard(),
    _chargerVip(),
  ]);

  // ── Standard prices ───────────────────────────────────────────────────────
  Future<List<InfosTarifs>> _chargerStandard() async {
    try {
      final response = await ApiClient.instance.get(
        'tarifsAxes_et_infos_gare.php?type=tarifs',
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, InfosTarifs> axesUniques = {};
          for (var item in data['tarifs']) {
            final List<String> axeSplit = (item['axe'] as String).split(' ');
            if (axeSplit.length < 2) continue;
            final String depart = axeSplit[0];
            final String destination = axeSplit[1];
            final List<String> tridAxe = [depart, destination]..sort();
            final String axeTrie = tridAxe.join('-');
            if (!axesUniques.containsKey(axeTrie)) {
              axesUniques[axeTrie] = InfosTarifs(
                depart,
                destination,
                item['prix'] as int,
              );
            }
          }
          return axesUniques.values.toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── VIP prices ────────────────────────────────────────────────────────────
  Future<List<InfosTarifs>> _chargerVip() async {
    try {
      final response = await ApiClient.instance.get(
        'prixTickets.php?type=vip',
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final Map<String, InfosTarifs> axesUniques = {};
          for (var item in data['prix']) {
            final (depart, destination) = _parseAxe(item['axe'] as String);
            final List<String> tridAxe = [depart, destination]..sort();
            final String axeTrie = tridAxe.join('-');
            if (!axesUniques.containsKey(axeTrie)) {
              axesUniques[axeTrie] = InfosTarifs(
                depart,
                destination,
                item['prix'] as int,
              );
            }
          }
          return axesUniques.values.toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: FutureBuilder<List<List<InfosTarifs>>>(
        future: _tarifsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: c.homeButtonPrimary),
            );
          }

          final standard = snapshot.data?[0] ?? [];
          final vip = snapshot.data?[1] ?? [];

          if (standard.isEmpty && vip.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    color: c.homeButtonPrimary.withValues(alpha: 0.3),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun tarif disponible',
                    style: TextStyle(
                      color: c.homeTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 12,
            ),
            children: [
              // ── Section STANDARD ────────────────────────────────────────
              if (standard.isNotEmpty) ...[
                _enteteSection(
                  'TARIFS STANDARD',
                  Icons.directions_bus_outlined,
                  c.homeButtonPrimary,
                ),
                const SizedBox(height: 10),
                ...standard.map(
                  (tarif) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _carteStandard(tarif, screenWidth, c),
                  ),
                ),
              ],

              // ── Section VIP ─────────────────────────────────────────────
              if (vip.isNotEmpty) ...[
                const SizedBox(height: 8),
                _enteteSection(
                  'TARIFS VIP',
                  Icons.star_rounded,
                  const Color.fromARGB(255, 1, 130, 67),
                ),
                const SizedBox(height: 10),
                ...vip.map(
                  (tarif) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _carteVip(tarif, screenWidth, c),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── En-tête de section ────────────────────────────────────────────────────
  Widget _enteteSection(String titre, IconData icone, Color couleur) {
    return Row(
      children: [
        Icon(icone, color: couleur, size: 18),
        const SizedBox(width: 8),
        Text(
          titre,
          style: TextStyle(
            color: couleur,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: couleur.withValues(alpha: 0.3))),
      ],
    );
  }

  // ── Carte Standard ────────────────────────────────────────────────────────
  Widget _carteStandard(InfosTarifs tarif, double screenWidth, dynamic c) {
    return Container(
      decoration: BoxDecoration(
        color: c.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.homeBordurePetiteCarte, width: 1),
      ),
      child: Column(
        children: [
          // Header MVST
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.homeButtonPrimary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                'MVST',
                style: TextStyle(
                  color: c.homeButtonPrimary,
                  fontFamily: 'Lobster',
                  fontSize: screenWidth * 0.045,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
          // Trajet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      tarif.depart,
                      style: TextStyle(
                        color: c.homeButtonPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.036,
                      ),
                    ),
                    Icon(
                      Icons.sync_alt_outlined,
                      color: c.homeButtonPrimary,
                      size: 18,
                    ),
                    Text(
                      tarif.destination,
                      style: TextStyle(
                        color: c.homeButtonPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.036,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      tarif.destination,
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(alpha: 0.6),
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    Icon(
                      Icons.sync_alt_outlined,
                      color: c.homeTextPrimary.withValues(alpha: 0.3),
                      size: 16,
                    ),
                    Text(
                      tarif.depart,
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(alpha: 0.6),
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 0, color: c.homeBordurePetiteCarte),
          // Prix
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c.homeAccent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                '${tarif.prix} FCFA',
                style: TextStyle(
                  color: c.homeButtonPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.042,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte VIP ─────────────────────────────────────────────────────────────
  Widget _carteVip(InfosTarifs tarif, double screenWidth, dynamic c) {
    return Container(
      decoration: BoxDecoration(
        color: c.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.homeBordurePetiteCarte, width: 1),
      ),
      child: Column(
        children: [
          // Header VIP
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 210, 248, 230),

              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: vertVIP, size: 16),
                const SizedBox(width: 6),
                Text(
                  'MVST VIP',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 1, 130, 67),
                    fontFamily: 'Lobster',
                    fontSize: screenWidth * 0.045,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.star_rounded, color: vertVIP, size: 16),
              ],
            ),
          ),
          // Trajet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      tarif.depart,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 1, 130, 67),
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.036,
                      ),
                    ),
                    Icon(
                      Icons.sync_alt_outlined,
                      color: const Color.fromARGB(255, 1, 130, 67),
                      size: 18,
                    ),
                    Text(
                      tarif.destination,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 1, 130, 67),
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.036,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      tarif.destination,
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(
                          alpha: 0.6,
                        ), // ← Changé
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    Icon(
                      Icons.sync_alt_outlined,
                      color: c.homeTextPrimary.withValues(
                        alpha: 0.3,
                      ), // ← Changé
                      size: 16,
                    ),
                    Text(
                      tarif.depart,
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(
                          alpha: 0.6,
                        ), // ← Changé
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 0, color: const Color.fromARGB(255, 1, 130, 67)),
          // Prix
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c.homeAccent.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Text(
                '${tarif.prix} FCFA',
                style: TextStyle(
                  color: const Color.fromARGB(255, 1, 130, 67),
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.042,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
