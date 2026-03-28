import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';

class InformationPrix extends StatelessWidget {
  Future<List<InfosTarifs>> recupererPrixDesTickets() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://mvst.tenelo.cloud/tarifsAxes_et_infos_gare.php?type=tarifs',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          Map<String, InfosTarifs> axesUniques = {};
          for (var item in data['tarifs']) {
            List<String> axeSplit = (item['axe'] as String).split(' ');
            if (axeSplit.length < 2) continue;
            String depart = axeSplit[0];
            String destination = axeSplit[1];
            List<String> tridAxe = [depart, destination]..sort();
            String axeTrie = tridAxe.join('-');
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
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: FutureBuilder<List<InfosTarifs>>(
        future: recupererPrixDesTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: c.homeButtonPrimary),
            );
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    color: c.homeButtonPrimary.withOpacity(0.3),
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

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: 12,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final tarif = snapshot.data![index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _carteTarif(tarif, screenWidth),
              );
            },
          );
        },
      ),
    );
  }

  Widget _carteTarif(InfosTarifs tarif, double screenWidth) {
    final c = Config.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.homeBordurePetiteCarte, width: 1),
      ),
      child: Column(
        children: [
          // ── Header MVST ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.homeButtonPrimary.withOpacity(0.08),
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

          // ── Trajet ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // Aller
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
                // Retour
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      tarif.destination,
                      style: TextStyle(
                        color: c.homeTextPrimary.withOpacity(0.6),
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    Icon(
                      Icons.sync_alt_outlined,
                      color: c.homeTextPrimary.withOpacity(0.3),
                      size: 16,
                    ),
                    Text(
                      tarif.depart,
                      style: TextStyle(
                        color: c.homeTextPrimary.withOpacity(0.6),
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Séparateur ────────────────────────────────────────────
          Divider(height: 0, color: c.homeBordurePetiteCarte),

          // ── Prix ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: c.homeAccent.withOpacity(0.08),
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
}
