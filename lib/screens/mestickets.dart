import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/detailsTickets.dart';

DateTime? dateActuelle = DateTime.now();
DateTime? dateDemain = DateTime.utc(
  dateActuelle!.year,
  dateActuelle!.month,
  dateActuelle!.day + 1,
);
DateTime? dateApresDemain = DateTime.utc(
  dateActuelle!.year,
  dateActuelle!.month,
  dateActuelle!.day + 2,
);
DateTime? dateAujourdhui = DateTime.utc(
  dateActuelle!.year,
  dateActuelle!.month,
  dateActuelle!.day,
);

String? dateDAujourdhui;
String? dateDeDemain;
String? dateDapresDemain;

class MesTickets extends StatefulWidget {
  const MesTickets({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  State<MesTickets> createState() => _MesTicketsState();
}

class _MesTicketsState extends State<MesTickets> {
  final String baseUrl = 'https://mvst.tenelo.cloud';

  @override
  void initState() {
    super.initState();
    dateActuelle = DateTime.now();
    dateDAujourdhui = DateFormat(
      'EEEE d MMMM y',
      'fr_FR',
    ).format(dateAujourdhui!);
    dateDeDemain = DateFormat('EEEE d MMMM y', 'fr_FR').format(dateDemain!);
    dateDapresDemain = DateFormat(
      'EEEE d MMMM y',
      'fr_FR',
    ).format(dateApresDemain!);
  }

  Future<List<Map<String, dynamic>>> recuperationDeMesTickets() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperation_mes_tickets.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idUtilisateur": widget.idUtilisateur}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['tickets']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Erreur de connexion au serveur.');
      }
    } catch (e) {
      afficherErreur(context, e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Liste tickets ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: 12,
                ),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: recuperationDeMesTickets(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
                      ) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.wifi_off_outlined,
                                  color: c.homeButtonPrimary,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Vérifiez la connexion',
                                  style: TextStyle(
                                    color: c.homeTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: c.homeButtonPrimary,
                            ),
                          );
                        }
                        if (snapshot.data == null || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: c.homeButtonPrimary.withValues(alpha:0.4),
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Vous n'avez aucun ticket",
                                  style: TextStyle(
                                    color: c.homeTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Réservez votre premier voyage',
                                  style: TextStyle(
                                    color: c.homeTextPrimary.withValues(alpha:0.5),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (BuildContext context, int index) {
                            Map<String, dynamic> ticket = snapshot.data![index];
                            final String typeVoyage =
                                ticket['typeVoyage'] ?? 'standard';
                            final String verifDate = ticket['date'];
                            final bool isVip = typeVoyage == 'vip';
                            final bool isRecent =
                                verifDate == dateDAujourdhui ||
                                verifDate == dateDeDemain ||
                                verifDate == dateDapresDemain;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildTicketCard(
                                context,
                                ticket: ticket,
                                isVip: isVip,
                                isRecent: isRecent,
                                typeVoyage: typeVoyage,
                                screenWidth: screenWidth,
                              ),
                            );
                          },
                        );
                      },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context, {
    required Map<String, dynamic> ticket,
    required bool isVip,
    required bool isRecent,
    required String typeVoyage,
    required double screenWidth,
  }) {
    final c = Config.colors;

    // ── Couleurs selon type et date ───────────────────────────────────────
    final Color cardBg = isVip ? const Color(0xFF12122A) : c.homeCardBackground;

    final Color cardBorder = isVip
        ? const Color(0xFFFFD700)
        : isRecent
        ? c.homeButtonPrimary
        : Colors.grey.withValues(alpha:0.4);

    final Color accentColor = isVip
        ? const Color(0xFFFFD700)
        : isRecent
        ? c
              .homeButtonPrimary // ← bleu vif si date proche
        : c.homeTextPrimary.withValues(alpha:0.4); // ← grisé si passé

    final Color textColor = isVip ? Colors.white : c.homeTextPrimary;

    final Color subTextColor = isVip
        ? Colors.white54
        : c.homeTextPrimary.withValues(alpha:0.55);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsTickets(
            idTicket: ticket['documentId'],
            idUtilisateur: ticket['idUtilisateur'],
            nom: ticket['nom'],
            contact: ticket['telephone'],
            date: ticket['date'],
            heure: ticket['heure'],
            depart: ticket['depart'],
            destination: ticket['destination'],
            place: ticket['place'],
            etatScann: ticket['etatScanne'],
            statut: ticket['statut'],
            prixTicket: ticket['prixDuTicket'].toString(),
            datePourCalcule: ticket['datePourCalcule'] != null
                ? DateTime.parse(ticket['datePourCalcule'])
                : DateTime.now(),
            typeVoyage: typeVoyage,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder, width: isRecent ? 1.5 : 1),
        ),
        child: Column(
          children: [
            // ── Bandeau supérieur coloré ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isVip
                    ? const Color(0xFFFFD700).withValues(alpha:0.15)
                    : isRecent
                    ? c.homeButtonPrimary.withValues(alpha:0.08)
                    : Colors.grey.withValues(alpha:0.06),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ── Trajet ─────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        ticket['depart'],
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.arrow_forward,
                          color: accentColor,
                          size: 14,
                        ),
                      ),
                      Text(
                        ticket['destination'],
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                  // ── Badge VIP ou statut ────────────────────────────
                  if (isVip)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '★ VIP',
                        style: TextStyle(
                          color: Color(0xFF12122A),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Corps du ticket ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // ── Infos principales ─────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          icon: Icons.calendar_today_outlined,
                          label: ticket['date'],
                          textColor: textColor,
                          subColor: subTextColor,
                          accentColor: accentColor,
                          screenWidth: screenWidth,
                        ),
                        const SizedBox(height: 6),
                        _infoRow(
                          icon: Icons.access_time_outlined,
                          label: '${ticket['heure']} h',
                          textColor: textColor,
                          subColor: subTextColor,
                          accentColor: accentColor,
                          screenWidth: screenWidth,
                          isBold: true,
                        ),
                        const SizedBox(height: 6),
                        _infoRow(
                          icon: Icons.event_seat_outlined,
                          label: 'Siège N° ${ticket['place']}',
                          textColor: textColor,
                          subColor: subTextColor,
                          accentColor: accentColor,
                          screenWidth: screenWidth,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  // ── Séparateur pointillé ───────────────────────────
                  Container(
                    width: 1,
                    height: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: isVip
                            ? const Color(0xFFFFD700).withValues(alpha:0.3)
                            : c.homeBordurePetiteCarte,
                      ),
                    ),
                  ),

                  // ── Logo + bouton ──────────────────────────────────
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'MVST',
                        style: TextStyle(
                          color: accentColor,
                          fontFamily: 'Lobster',
                          fontSize: screenWidth * 0.055,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets(
                              idTicket: ticket['documentId'],
                              idUtilisateur: ticket['idUtilisateur'],
                              nom: ticket['nom'],
                              contact: ticket['telephone'],
                              date: ticket['date'],
                              heure: ticket['heure'],
                              depart: ticket['depart'],
                              destination: ticket['destination'],
                              place: ticket['place'],
                              etatScann: ticket['etatScanne'],
                              statut: ticket['statut'],
                              prixTicket: ticket['prixDuTicket'].toString(),
                              datePourCalcule: ticket['datePourCalcule'] != null
                                  ? DateTime.parse(ticket['datePourCalcule'])
                                  : DateTime.now(),
                              typeVoyage: typeVoyage,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor, width: 0.8),
                          ),
                          child: Text(
                            'Détails',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color subColor,
    required Color accentColor,
    required double screenWidth,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: accentColor.withValues(alpha:0.7), size: 13),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: isBold ? textColor : textColor.withValues(alpha:0.85),
              fontSize: screenWidth * 0.031,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Séparateur pointillé ───────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double y = 0;
    const double dashHeight = 4;
    const double gapHeight = 4;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) => false;
}
