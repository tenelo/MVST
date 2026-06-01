import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/qrcode/creationQrCode.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:ticket_widget/ticket_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// DESIGN VIP TICKET — OBSIDIENNE & OR
// Remplace DetailsTickets + TicketData pour les tickets de type "vip"
// Structure identique à l'original, uniquement les couleurs changent.
// ══════════════════════════════════════════════════════════════════════════════

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0A0A14); // obsidienne
const Color _surface = Color(0xFF13131F); // surface sombre
const Color _gold = Color(0xFFD4AF37); // or pur
const Color _goldLight = Color(0xFFF0D060); // or clair
const Color _text = Color(0xFFF2F2F2); // texte blanc cassé
const Color _textDim = Color(0xFF888899); // texte atténué
const Color _accent = Color(0xFF6C63FF); // indigo accent
const Color _border = Color(0xFF2A2A3A); // bordure subtile

// ── Page principale ───────────────────────────────────────────────────────────
class VipDetailsTickets extends StatefulWidget {
  final String idTicket;
  final String idUtilisateur;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String etatScann;
  final String statut;
  final String prixTicket;
  final DateTime datePourCalcule;
  final String typeVoyage;

  const VipDetailsTickets({
    super.key,
    required this.idTicket,
    required this.idUtilisateur,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
    required this.statut,
    required this.prixTicket,
    required this.datePourCalcule,
    required this.typeVoyage,
  });

  @override
  State<VipDetailsTickets> createState() => _VipDetailsTicketsState();
}

class _VipDetailsTicketsState extends State<VipDetailsTickets> {
  late io.Socket socket;
  late String etatScannActuel;
  late StreamController<String> _etatScannController;

  @override
  void initState() {
    super.initState();
    etatScannActuel = widget.etatScann;
    _etatScannController = StreamController<String>.broadcast();
    _rafraichirEtat();
    _connecterSocket();
  }

  @override
  void dispose() {
    _etatScannController.close();
    socket.off('ticket_valide');
    socket.offAny();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    socket = io.io(
      kBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      final dateAvecUnderscores = widget.date.replaceAll(' ', '_');
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': dateAvecUnderscores,
        'heure': widget.heure,
      });
    });

    socket.connect();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.date.replaceAll(' ', '_'),
        'heure': widget.heure,
      });
    });

    socket.on('ticket_valide', (data) {
      if (data['idUtilisateur']?.toString() == widget.idUtilisateur &&
          int.tryParse(data['place'].toString()) == widget.place) {
        if (mounted) {
          setState(() {
            etatScannActuel = 'scanné';
            _etatScannController.add('scanné');
          });
        }
      }
    });

    socket.onDisconnect((_) {});
  }

  Future<void> _rafraichirEtat() async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/etatTicket.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'documentId': widget.idTicket,
          'place': widget.place,
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            etatScannActuel = data['etatScanne'];
            _etatScannController.add(etatScannActuel);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: _bg,
      appBar: AppBar(
        //   backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _gold),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: _gold, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Ticket VIP',
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Center(
          child: TicketWidget(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.78,
            padding: const EdgeInsets.all(0),
            child: StreamBuilder<String>(
              stream: _etatScannController.stream,
              initialData: etatScannActuel,
              builder: (context, snapshot) {
                return VipTicketCard(
                  idUtilisateur: widget.idUtilisateur,
                  idTicket: widget.idTicket,
                  place: widget.place,
                  nom: widget.nom,
                  contact: widget.contact,
                  date: widget.date,
                  heure: widget.heure,
                  depart: widget.depart,
                  destination: widget.destination,
                  prixTicket: widget.prixTicket,
                  etatScann: snapshot.data ?? etatScannActuel,
                  dateCalcule: widget.datePourCalcule,
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_gold, Color(0xFFB8902A)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            /* génération PDF — identique à l'original */
          },
          icon: const Icon(
            Icons.download_rounded,
            color: Colors.black87,
            size: 18,
          ),
          label: const Text(
            'Télécharger',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VipTicketCard — remplace TicketData pour l'affichage VIP
// ══════════════════════════════════════════════════════════════════════════════
class VipTicketCard extends StatelessWidget {
  final String idUtilisateur;
  final String idTicket;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String prixTicket;
  final String etatScann;
  final DateTime dateCalcule;

  const VipTicketCard({
    super.key,
    required this.idUtilisateur,
    required this.idTicket,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.prixTicket,
    required this.etatScann,
    required this.dateCalcule,
  });

  @override
  Widget build(BuildContext context) {
    final bool scanne = etatScann == 'scanné';
    final Color qrAccent = scanne ? _accent : _gold;

    return Container(
      decoration: const BoxDecoration(
        color: _surface,
        // Le TicketWidget gère lui-même le clip arrondi + découpe
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : logo + badge VIP + statut scan ─────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge MVST
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _gold, width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Mieux Vous Servir Transport',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // Badge VIP + MVST
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_gold, Color(0xFFB89020)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '★ VIP',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MVST',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Ref ticket
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                'Réf. ${idTicket.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 7,
                  color: _textDim,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // ── Ligne dorée séparatrice ───────────────────────────────────────
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gold.withValues(alpha: 0),
                    _gold,
                    _gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),

            // ── Trajet ───────────────────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      depart,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: _gold,
                        size: 20,
                      ),
                    ),
                    Text(
                      destination,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Infos en grille 2×2 ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InfoCell(label: 'Passager', value: nom),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCell(label: 'Contact', value: contact),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoCell(label: 'Date de voyage', value: date),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCell(label: 'Départ', value: '${formaterHeure(heure)} h'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoCell(
                    label: 'Tarif',
                    value: '$prixTicket FCFA',
                    valueColor: _goldLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCell(
                    label: 'Siège',
                    value: place.toString(),
                    valueColor: _goldLight,
                  ),
                ),
              ],
            ),

            // ── Ligne pointillée (séparation ticket) ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: List.generate(
                  28,
                  (i) => Expanded(
                    child: Container(
                      height: 1,
                      color: i.isEven ? _border : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

            // ── QR Code centré ────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  // Cadre QR
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scanne
                          ? _accent.withValues(alpha: 0.08)
                          : _gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: qrAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: SizedBox(
                      width: petitEcran ? 130 : 155,
                      height: petitEcran ? 130 : 155,
                      child: FittedBox(
                        child: CreationQrCode.buildQrCode(
                          idUtilisateur,
                          idTicket,
                          place,
                          nom,
                          contact,
                          date,
                          heure,
                          depart,
                          destination,
                          prixTicket,
                          etatScann,
                          dateCalcule,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Statut scan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: qrAccent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          scanne
                              ? Icons.check_circle_rounded
                              : Icons.qr_code_rounded,
                          color: qrAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          scanne ? 'Ticket validé' : 'Prêt à scanner',
                          style: TextStyle(
                            color: qrAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    'La compagnie MVST vous souhaite bon voyage !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textDim,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cellule d'information ─────────────────────────────────────────────────────
class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoCell({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _textDim,
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
