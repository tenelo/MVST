import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_direct_caller_plugin/flutter_direct_caller_plugin.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/services/api_client.dart';

class LocalisationsDesGars extends StatefulWidget {
  LocalisationsDesGars({super.key});

  @override
  State<LocalisationsDesGars> createState() => _LocalisationsDesGarsState();
}

class _LocalisationsDesGarsState extends State<LocalisationsDesGars> {
  late final Future<List<Map<String, dynamic>>> _infosGaresFuture =
      infosGares();

  Future<List<Map<String, dynamic>>> infosGares() async {
    try {
      final response = await ApiClient.instance.get(
        'tarifsAxes_et_infos_gare.php?type=gares',
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(
            data['tarifs'].map(
              (item) => {
                'ville': item['ville'],
                'description': item['description'],
                'telephone': item['telephone'],
              },
            ),
          );
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _infosGaresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: c.homeButtonPrimary),
            );
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_outlined,
                    color: c.homeButtonPrimary.withValues(alpha:0.3),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune donnée disponible',
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
              final info = snapshot.data![index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _carteGare(
                  context,
                  info['ville'],
                  info['description'],
                  info['telephone'],
                  screenWidth,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _carteGare(
    BuildContext context,
    String ville,
    String description,
    String telephone,
    double screenWidth,
  ) {
    final c = Config.colors;

    return Container(
      decoration: BoxDecoration(
        color: c.homeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.homeBordurePetiteCarte, width: 1),
      ),
      child: Column(
        children: [
          // ── Header gare ───────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: c.homeButtonPrimary.withValues(alpha:0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: c.homeButtonPrimary, size: 18),
                const SizedBox(width: 8),
                Text(
                  ville,
                  style: TextStyle(
                    color: c.homeButtonPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.038,
                  ),
                ),
              ],
            ),
          ),
          // ── Description ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 4,
                  style: TextStyle(
                    color: c.homeTextPrimary.withValues(alpha:0.75),
                    fontSize: screenWidth * 0.032,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      FlutterDirectCallerPlugin.callNumber(telephone);
                    },
                    icon: Icon(
                      Icons.phone_outlined,
                      color: Config.colors.homeAccent,
                      size: 16,
                    ),
                    label: Text(
                      'Appeler la gare',
                      style: TextStyle(
                        color: Config.colors.homeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.homeButtonPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
