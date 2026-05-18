import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class Reservation extends StatefulWidget {
  const Reservation({
    super.key,
    required this.idDate,
    required this.nombreDeTicket,
    required this.prixUnitaire,
    required this.id,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.datePourCalcule,
    required this.mois,
    required this.moisAnnee,
    required this.annee,
    required this.heure,
    required this.destination,
    required this.depart,
    // Par défaut, le type de voyage est 'standard'. Si c'est une réservation VIP, il faut passer 'vip' lors de la création de l'instance.
    this.typeVoyage = 'standard',
  });

  final String idDate;
  final int nombreDeTicket;
  final int prixUnitaire;
  final String id;
  final List<int> place;
  final String nom;
  final String contact;
  final String date;
  final DateTime datePourCalcule;
  final String heure;
  final String destination;
  final String depart;
  final String mois;
  final String moisAnnee;
  final String annee;
  final String typeVoyage;

  @override
  State<Reservation> createState() => _ReservationState();
}

class _ReservationState extends State<Reservation> {
  bool _isLoading = false;
  bool _isNavigating = false;
  late io.Socket _socket;

  bool get _isVip => widget.typeVoyage == 'vip';

  @override
  void initState() {
    super.initState();
    _connecterSocket();
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    if (!_isNavigating) _nettoyer();
    super.dispose();
  }

  void _connecterSocket() {
    _socket = io.io(
      kBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();
  }
  // dans le payload, on envoie un documentId unique pour chaque réservation, basé sur le trajet, la date, l'heure et l'idDate. Cela permettra aux admins de suivre les réservations en temps réel et d'identifier facilement chaque ticket acheté.
  // typeVoyage est envoyé pour différencier les réservations VIP des standard, ce qui peut être utile pour les statistiques et la gestion des places.
  // par defaut, le statut est 'valide' et l'etatScanne est 'nonScanné', ce qui correspond à une réservation fraîchement confirmée. Ces champs pourront être mis à jour plus tard par les admins lors du processus de validation et de scan des tickets.
  // le typeVoyage par défaut est 'standard',

  Future<void> _confirmerReservation() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('$kBaseUrl/ajouterTickets.php');

    try {
      final payload = {
        'documentId':
            '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h',
        'idUtilisateur': widget.id,
        'nom': widget.nom,
        'telephone': widget.contact,
        'date': widget.date,
        'heure': widget.heure,
        'depart': widget.depart,
        'destination': widget.destination,
        'prixDuTicket': widget.prixUnitaire,
        'places': widget.place,
        'statut': 'valide',
        'etatScanne': 'nonScanné',
        'datePourCalcule': widget.datePourCalcule.toIso8601String(),
        'typeVoyage': widget.typeVoyage,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          listeDeVerification.clear();

          // ── Notifier les admins en temps réel ────────────────────────────
          final documentId =
              '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h';

          _socket.emit('rejoindre_room', {
            'depart': widget.depart,
            'destination': widget.destination,
            'date': widget.idDate,
            'heure': widget.heure,
          });

          _socket.emit('place_achetee', {
            'documentId': documentId,
            'depart': widget.depart,
            'destination': widget.destination,
            'date': widget.idDate,
            'heure': widget.heure,
          });

          if (mounted) {
            final bloc = BlocProvider.of<BlocCompteur>(context);
            bloc.add(EventInitialise());
            setState(() => _isNavigating = true);
            _afficherSucces();
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        } else {
          if (mounted) _afficherErreur();
        }
      } else {
        if (mounted) _afficherErreur();
      }
    } catch (_) {
      if (mounted) _afficherErreur();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _afficherSucces() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color.fromARGB(255, 1, 79, 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Réservation confirmée avec succès !',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherErreur() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          'La réservation a échoué. Réessayez.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _nettoyer() async {
    listeDeVerification.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenW = MediaQuery.of(context).size.width;

    final Color headerTop = _isVip
        ? c.authButtonDisabled
        : c.authButtonDisabled;
    final Color headerBot = _isVip
        ? const Color(0xFF12122A)
        : c.authButtonDisabled;
    final Color accentColor = _isVip
        ? const Color(0xFFFFD700)
        : c.authButtonDisabled;
    final int total = widget.prixUnitaire * widget.nombreDeTicket;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isNavigating) await _nettoyer();
      },
      child: Scaffold(
        backgroundColor: c.homeBackground,
        body: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: headerBot,
              iconTheme: IconThemeData(color: c.homeAccent),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(color: headerTop),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Badge type voyage ──────────────────────────────
                          if (_isVip)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '★ VIP',
                                style: TextStyle(
                                  color: Color(0xFF12122A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          // ── Trajet ─────────────────────────────────────────
                          Row(
                            children: [
                              Text(
                                widget.depart,
                                style: TextStyle(
                                  color: _isVip
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  fontSize: screenW * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: _isVip
                                      ? const Color(0xFFFFD700)
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  widget.destination,
                                  style: TextStyle(
                                    color: _isVip
                                        ? const Color(0xFFFFD700)
                                        : Colors.white,
                                    fontSize: screenW * 0.055,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // ── Date · Heure ───────────────────────────────────
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white.withValues(alpha: 0.65),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.date,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.access_time_outlined,
                                color: Colors.white.withValues(alpha: 0.65),
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${widget.heure} h',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenW * 0.05,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Récapitulatif ─────────────────────────────────────────
                    _sectionLabel('Récapitulatif', c),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.homeCardBackground,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _recapLigne(
                            Icons.person_outline,
                            'Passager',
                            widget.nom,
                            c,
                            isFirst: true,
                          ),
                          _divider(c),
                          _recapLigne(
                            Icons.phone_outlined,
                            'Contact',
                            widget.contact,
                            c,
                          ),
                          _divider(c),
                          _recapLigne(
                            Icons.confirmation_number_outlined,
                            'Ticket(s)',
                            '${widget.nombreDeTicket} ticket${widget.nombreDeTicket > 1 ? 's' : ''}',
                            c,
                          ),
                          _divider(c),
                          _recapLigne(
                            _isVip
                                ? Icons.star_rounded
                                : Icons.airline_seat_recline_normal_outlined,
                            'Classe',
                            _isVip ? '★ VIP' : 'Standard',
                            c,
                            valueColor: _isVip ? const Color(0xFFFFD700) : null,
                          ),
                          _divider(c),
                          // ── Total ──────────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt_outlined,
                                    color: accentColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      color: c.homeTextPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_formatPrix(total)} FCFA',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          margin: EdgeInsets.symmetric(horizontal: screenW * 0.05),
          width: screenW,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : _confirmerReservation,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: Text(
              _isLoading
                  ? 'Confirmation en cours...'
                  : 'Confirmer la réservation',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _isLoading
                  ? accentColor.withValues(alpha: 0.5)
                  : accentColor,
              foregroundColor: _isVip ? const Color(0xFF12122A) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // // ── Siège tile ─────────────────────────────────────────────────────────────
  // Widget _siegeTile(int numero, Color accent, dynamic c) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 8),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //       decoration: BoxDecoration(
  //         color: c.homeCardBackground,
  //         borderRadius: BorderRadius.circular(14),
  //         border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
  //       ),
  //       child: Row(
  //         children: [
  //           Container(
  //             width: 36,
  //             height: 36,
  //             decoration: BoxDecoration(
  //               color: accent.withValues(alpha: 0.1),
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: Icon(Icons.event_seat_outlined, color: accent, size: 18),
  //           ),
  //           const SizedBox(width: 14),
  //           Text(
  //             'Siège $numero',
  //             style: TextStyle(
  //               color: c.homeTextPrimary,
  //               fontWeight: FontWeight.w600,
  //               fontSize: 14,
  //             ),
  //           ),
  //           const Spacer(),
  //           Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  //             decoration: BoxDecoration(
  //               color: accent.withValues(alpha: 0.1),
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: Text(
  //               '${_formatPrix(widget.prixUnitaire)} FCFA',
  //               style: TextStyle(
  //                 color: accent,
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.w600,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // ── Ligne récapitulatif ────────────────────────────────────────────────────
  Widget _recapLigne(
    IconData icon,
    String label,
    String value,
    dynamic c, {
    bool isFirst = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Config.colors.homeButtonPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Config.colors.homeButtonPrimary, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: c.homeTextPrimary.withValues(alpha: 0.45),
            fontSize: 11,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: valueColor ?? c.homeTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _divider(dynamic c) => Divider(
    height: 1,
    thickness: 0.6,
    indent: 68,
    endIndent: 16,
    color: c.homeTextPrimary.withValues(alpha: 0.07),
  );

  Widget _sectionLabel(String text, dynamic c) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: c.homeTextPrimary.withValues(alpha: 0.45),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
    ),
  );

  String _formatPrix(int prix) {
    final f = prix.toString();
    if (f.length <= 3) return f;
    final buf = StringBuffer();
    final mod = f.length % 3;
    if (mod != 0) buf.write(f.substring(0, mod));
    for (int i = mod; i < f.length; i += 3) {
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(f.substring(i, i + 3));
    }
    return buf.toString();
  }
}
