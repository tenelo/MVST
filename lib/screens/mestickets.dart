import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/detailsTickets.dart';
import 'package:ticket_material/ticket_material.dart';

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
          final tickets = List<Map<String, dynamic>>.from(data['tickets']);
          tickets.sort((a, b) {
            final dateA = a['datePourCalcule'] != null
                ? DateTime.tryParse(a['datePourCalcule']) ?? DateTime(0)
                : DateTime(0);
            final dateB = b['datePourCalcule'] != null
                ? DateTime.tryParse(b['datePourCalcule']) ?? DateTime(0)
                : DateTime(0);
            return dateB.compareTo(dateA);
          });
          return tickets;
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Erreur de connexion au serveur.');
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
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
                                  color: c.homeButtonPrimary.withValues(
                                    alpha: 0.4,
                                  ),
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
                                    color: c.homeTextPrimary.withValues(
                                      alpha: 0.5,
                                    ),
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

    // Vérifier si la date du ticket est passée
    final bool isDatePassed = _isTicketDatePassed(ticket['date']);

    // Si la date est passée, appliquer un filtre gris
    final Color cardBg = isDatePassed
        ? Colors.grey[300]!
        : c.homeBandeauBackground;

    final Color vertVip = const Color(0xFF00D87E);

    final Color accentColor = isDatePassed
        ? Colors.grey[400]!
        : (isRecent
              ? c.homeButtonPrimary
              : c.homeTextPrimary.withValues(alpha: 0.4));

    final Color textColor = isVip
        ? (isDatePassed ? Colors.grey[400]! : c.homeTextPrimary)
        : (isDatePassed ? Colors.black : c.homeTextPrimary);

    final Color subTextColor = isVip
        ? (isDatePassed ? Colors.grey[500]! : c.homeTextPrimary)
        : (isDatePassed ? Colors.black : c.homeTextPrimary);

    void ouvrirDetails() => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailsTickets(
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
    );

    return TicketMaterial(
      height: 110,
      colorBackground: cardBg,
      radiusBorder: 14,
      flexLefSize: 72,
      flexMaskSize: 6,
      flexRightSize: 22,
      colorShadow: isVip ? vertVip : accentColor,
      shadowSize: 3,
      tapHandler: ouvrirDetails,

      // ── Partie gauche : infos trajet ──────────────────────────────────
      leftChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Trajet
            Row(
              children: [
                Text(
                  ticket['depart'],
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.036,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: 14,
                  ),
                ),
                Flexible(
                  child: Text(
                    ticket['destination'],
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.036,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVip) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D87E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '★ VIP',
                      style: TextStyle(
                        color: Color(0xFF050E08),
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Date
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: accentColor.withValues(alpha: 0.7),
                  size: 12,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    ticket['date'],
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: screenWidth * 0.029,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Heure + Siège
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: accentColor.withValues(alpha: 0.7),
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  '${ticket['heure']} h',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.030,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.event_seat_outlined,
                  color: accentColor.withValues(alpha: 0.7),
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  'Siège ${ticket['place']}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.030,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Partie droite : logo + bouton ─────────────────────────────────
      rightChild: GestureDetector(
        onTap: ouvrirDetails,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MVST',
              style: TextStyle(
                color: accentColor,
                //color: isVip ? vertVip : accentColor,
                fontFamily: 'Lobster',
                fontSize: screenWidth * 0.048,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isVip ? vertVip : accentColor,
                  width: 0.8,
                ),
              ),
              child: Text(
                'Détails',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Méthode pour vérifier si la date est passée
bool _isTicketDatePassed(String dateString) {
  try {
    final DateFormat formatter = DateFormat('EEEE d MMMM y', 'fr_FR');
    final DateTime ticketDate = formatter.parse(dateString);

    // Date d'aujourd'hui (sans l'heure)
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Comparer les dates
    return ticketDate.isBefore(today);
  } catch (e) {
    // Si erreur de parsing, considérer comme non expiré
    return false;
  }
}
