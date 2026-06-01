import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/main.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/screens/detailsTickets.dart';
import 'package:ticket_material/ticket_material.dart';

class MesTickets extends StatefulWidget {
  const MesTickets({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  State<MesTickets> createState() => _MesTicketsState();
}

class _MesTicketsState extends State<MesTickets> with RouteAware {
  static const int _pas = 20;

  List<Map<String, dynamic>> _tickets = [];
  bool _chargement = false;
  bool _chargementPlus = false;
  bool _erreurReseau = false;
  int _total = 0;
  bool _toutCharge = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initDates();
    _chargerPremierePage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {}

  void _initDates() {}

  Future<void> _chargerPremierePage() async {
    if (!mounted) return;
    setState(() {
      _chargement = true;
      _erreurReseau = false;
      _tickets.clear();
      _total = 0;
      _toutCharge = false;
    });

    await _chargerPage(0);
  }

  Future<void> _chargerPage(int offset) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/recuperation_mes_tickets.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idUtilisateur': widget.idUtilisateur,
              'offset': offset,
              'limit': _pas,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final nouveaux = List<Map<String, dynamic>>.from(data['tickets']);
          if (mounted) {
            setState(() {
              if (offset == 0) {
                _tickets = nouveaux;
              } else {
                _tickets.addAll(nouveaux);
              }
              _total = data['total'] ?? _tickets.length;
              _toutCharge = _tickets.length >= _total;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreurReseau = true);
        afficherErreur(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _chargement = false;
          _chargementPlus = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_chargementPlus || _toutCharge) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      setState(() => _chargementPlus = true);
      _chargerPage(_tickets.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;

    if (_chargement && _tickets.isEmpty) {
      return Scaffold(
        backgroundColor: c.homeBackground,
        body: Center(
          child: CircularProgressIndicator(color: c.homeButtonPrimary),
        ),
      );
    }

    if (_erreurReseau && _tickets.isEmpty) {
      return Scaffold(
        backgroundColor: c.homeBackground,
        body: Center(
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
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _chargerPremierePage,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Scaffold(
        backgroundColor: c.homeBackground,
        body: RefreshIndicator(
          color: c.homeButtonPrimary,
          onRefresh: _chargerPremierePage,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.3),
              Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: c.homeButtonPrimary.withValues(alpha: 0.4),
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
                      color: c.homeTextPrimary.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: SafeArea(
        child: RefreshIndicator(
          color: c.homeButtonPrimary,
          onRefresh: _chargerPremierePage,
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: 12),
            itemCount: _tickets.length + (_toutCharge ? 0 : 1),
            itemBuilder: (context, index) {
              if (index == _tickets.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: _chargementPlus
                        ? CircularProgressIndicator(color: c.homeButtonPrimary)
                        : Text(
                            '${_total - _tickets.length} ticket(s) de plus...',
                            style: TextStyle(
                              color: c.homeTextPrimary.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                  ),
                );
              }

              final ticket = _tickets[index];
              final typeVoyage = ticket['typeVoyage'] ?? 'standard';
              final isVip = typeVoyage == 'vip';
              final isActif = !_isTicketDatePassed(ticket['date']);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTicketCard(
                  context,
                  ticket: ticket,
                  isVip: isVip,
                  isActif: isActif,
                  typeVoyage: typeVoyage,
                  screenWidth: sw,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context, {
    required Map<String, dynamic> ticket,
    required bool isVip,
    required bool isActif,
    required String typeVoyage,
    required double screenWidth,
  }) {
    final c = Config.colors;
    final bool isDatePassed = _isTicketDatePassed(ticket['date']);
    final Color vertVip = isDatePassed
        ? Color.fromARGB(255, 168, 241, 211)
        : const Color(0xFF00D87E);
    final Color couleurBadgeVip = isDatePassed ? Colors.grey[400]! : vertVip;

    final Color cardBg = isDatePassed
        ? Colors.grey[300]!
        : c.homeBandeauBackground;
    final Color accentColor = isDatePassed
        ? Colors.grey[400]!
        : (isActif
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
      height: screenWidth * 0.28,
      colorBackground: cardBg,
      radiusBorder: 14,
      flexLefSize: 72,
      flexMaskSize: 6,
      flexRightSize: 22,
      colorShadow: isVip ? vertVip : accentColor,
      shadowSize: 3,
      tapHandler: ouvrirDetails,
      leftChild: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.036,
          vertical: screenWidth * 0.026,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
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
                      color: couleurBadgeVip,
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
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: accentColor.withValues(alpha: 0.7),
                  size: 12,
                ),
                const SizedBox(width: 5),
                Text(
                  '${formaterHeure(ticket['heure'])} h',
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
      rightChild: GestureDetector(
        onTap: ouvrirDetails,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MVST',
              style: TextStyle(
                color: accentColor,
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

bool _isTicketDatePassed(String dateString) {
  try {
    final date = DateFormat('EEEE d MMMM y', 'fr_FR').parse(dateString);
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    return date.isBefore(today);
  } catch (_) {
    return false;
  }
}
