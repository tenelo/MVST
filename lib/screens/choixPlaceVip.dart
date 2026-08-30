// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/screens/choixPlace.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/bloc/state.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/listeTicketAvantpaiement.dart';
import 'package:mvst/services/api_client.dart';

// ── Couleurs VIP (palette Émeraude Lumière) ───────────────────────────────────
const Color _vipOr = Color(0xFF00D87E);
const Color _vipFond = Color.fromARGB(255, 255, 255, 255);
const Color _vipSiege = Color.fromARGB(255, 227, 246, 237);
const Color _vipSiegeSelectionne = Color(0xFF00D87E);
const Color _vipSiegeReserve = Color.fromARGB(255, 198, 197, 197);

class ChoixPlacesVip extends StatefulWidget {
  const ChoixPlacesVip({
    super.key,
    required this.idDate,
    required this.id,
    required this.depart,
    required this.destination,
    required this.nom,
    required this.contact,
    required this.date,
    required this.mois,
    required this.moisAnnee,
    required this.annee,
    required this.heure,
    required this.prixDuBillet,
    required this.typeVoyage,
  });

  final String idDate;
  final String id;
  final String nom;
  final String contact;
  final String date;
  final String mois;
  final String moisAnnee;
  final String annee;
  final String heure;
  final String depart;
  final String destination;
  final int prixDuBillet;
  final String typeVoyage;
  @override
  State<ChoixPlacesVip> createState() => _ChoixPlacesVipState();
}

class _ChoixPlacesVipState extends State<ChoixPlacesVip> {
  int _seconds = 90;
  late Timer _timer;
  bool _isLoading = true;
  late io.Socket socket;

  // ── État centralisé ───────────────────────────────────────────────────────
  final Set<int> _selectedSeats = {}; // confirmées par le serveur
  final Set<int> _loadingSeats = {}; // en attente de réponse serveur
  Set<int> _occupiedSeats = {}; // occupées par d'autres voyageurs

  @override
  void initState() {
    super.initState();
    _chargerPlacesEtConnecterSocket();
    startCountdown();
  }

  @override
  void dispose() {
    if (_selectedSeats.isNotEmpty && socket.connected) {
      socket.emit('liberer_places', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'numerosDePlace': _selectedSeats.toList(),
      });
    }
    // Si le socket est deja deconnecte a ce stade, le serveur a deja
    // libere les places via gererDeconnexion au moment de la
    // deconnexion (voir mvst-socket/handlers/places.js) — plus besoin
    // d'appel de secours ici.
    socket.off('places_chargees');
    socket.off('place_prise');
    socket.off('place_liberee');
    socket.off('place_confirmee');
    socket.off('place_echec');
    socket.off('connect');
    socket.offAny();
    socket.disconnect();
    socket.dispose();
    _timer.cancel();
    super.dispose();
  }

  // Appelé uniquement quand le timer atteint zéro (expiration de session)
  void stopCountdown() {
    _timer.cancel();
    if (_selectedSeats.isNotEmpty && socket.connected) {
      socket.emit('liberer_places', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'numerosDePlace': _selectedSeats.toList(),
      });
    }
    socket.off('places_chargees');
    socket.off('place_prise');
    socket.off('place_liberee');
    socket.off('place_confirmee');
    socket.off('place_echec');
    socket.offAny();
    socket.disconnect();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          stopCountdown();
          Navigator.pop(context);
        }
      });
    });
  }

  Future<void> _chargerPlacesEtConnecterSocket() async {
    await _chargerPlacesViaHttp();
    if (mounted) _connecterSocket();
  }

  Future<void> _chargerPlacesViaHttp() async {
    try {
      final documentId =
          '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h';
      final response = await ApiClient.instance.post(
        'placesAssises.php',
        body: {'documentId': documentId},
        timeout: const Duration(seconds: 10),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _occupiedSeats = Set<int>.from(
              (data['places'] ?? []).map((p) => p['place'] as int),
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      if (!mounted) return;

      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'mois': widget.mois,
        'moisAnnee': widget.moisAnnee,
        'annee': widget.annee,
      });
    });

    // ── Mises à jour temps réel des autres voyageurs ──────────────────────────
    socket.on('place_prise', (data) {
      if (!mounted) return;
      final int place = data['numeroDePlace'];
      if (_selectedSeats.contains(place) || _loadingSeats.contains(place))
        return;
      setState(() => _occupiedSeats.add(place));
    });

    socket.on('place_liberee', (data) {
      if (!mounted) return;
      final List<dynamic> places = data['numerosDePlace'];
      setState(() {
        for (final p in places) {
          _occupiedSeats.remove(p as int);
        }
      });
    });

    // ── Réponses aux demandes de sélection de CE voyageur ────────────────────
    socket.on('place_confirmee', (data) {
      if (!mounted) return;
      final int place = data['numeroDePlace'];
      if (!_loadingSeats.contains(place)) return;
      setState(() {
        _loadingSeats.remove(place);
        _selectedSeats.add(place);
      });
      BlocProvider.of<BlocCompteur>(context).add(EventIcrement());
    });

    socket.on('place_echec', (data) {
      if (!mounted) return;
      final int place = data['numeroDePlace'];
      setState(() {
        _loadingSeats.remove(place);
        _occupiedSeats.add(place);
      });
      showAlertDialog(context);
    });

    socket.onConnectError((err) {});
    socket.onError((err) {});

    socket.onReconnect((_) {
      if (!mounted) return;
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'mois': widget.mois,
        'moisAnnee': widget.moisAnnee,
        'annee': widget.annee,
      });
    });

    socket.onDisconnect((_) {});

    socket.connect();
  }

  // ── Logique de sélection centralisée ─────────────────────────────────────────
  void _onSeatTap(int numero) {
    if (_occupiedSeats.contains(numero) || _loadingSeats.contains(numero)) {
      return;
    }

    if (_selectedSeats.contains(numero)) {
      setState(() => _selectedSeats.remove(numero));
      socket.emit('liberer_places', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'numerosDePlace': [numero],
      });
      BlocProvider.of<BlocCompteur>(context).add(EventDecrement());
    } else {
      setState(() => _loadingSeats.add(numero));
      socket.emit('choisir_place', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'mois': widget.mois,
        'moisAnnee': widget.moisAnnee,
        'annee': widget.annee,
        'numeroDePlace': numero,
        'typeVoyage': widget.typeVoyage,
      });
    }
  }

  void _naviguerVersTickets(BuildContext context, CompteurState state) {
    if (_selectedSeats.isNotEmpty) {
      // Le socket reste connecté pendant la navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Tickets(
            idDate: widget.idDate,
            nombreDeTicket: state.tickets,
            place: _selectedSeats.toList(),
            id: widget.id,
            nom: widget.nom,
            contact: widget.contact,
            date: widget.date,
            mois: widget.mois,
            moisAnnee: widget.moisAnnee,
            annee: widget.annee,
            heure: widget.heure,
            depart: widget.depart,
            destination: widget.destination,
            prixDuTicket: widget.prixDuBillet,
            typeVoyage: widget.typeVoyage,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Center(
              child: Text(
                'Aucune place',
                style: TextStyle(color: _vipOr, fontWeight: FontWeight.bold),
              ),
            ),
            content: const Text(
              'Vous n\'avez choisi aucune place.',
              style: TextStyle(color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: _vipOr, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _rangee2(List<int> numeros) {
    return Row(
      children: numeros
          .map(
            (n) => PlacesVip(
              key: ValueKey(n),
              numero: n,
              isSelected: _selectedSeats.contains(n),
              isLoading: _loadingSeats.contains(n),
              isOccupied: _occupiedSeats.contains(n),
              onTap: () => _onSeatTap(n),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _vipFond,
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.06,
        iconTheme: IconThemeData(color: c.homeAccent),
        backgroundColor: c.vertB,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: _vipOr, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "${widget.depart} → ${widget.destination}  ${widget.heure} h",
                style: TextStyle(
                  color: _vipOr,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.038,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.02),
            child: Center(
              child: Text(
                '$_seconds s',
                style: TextStyle(
                  color: _seconds <= 10 ? Colors.red : c.homeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.040,
                ),
              ),
            ),
          ),
          BlocBuilder<BlocCompteur, CompteurState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () => _naviguerVersTickets(context, state),
                icon: badges.Badge(
                  badgeStyle: const badges.BadgeStyle(badgeColor: _vipOr),
                  badgeAnimation: const badges.BadgeAnimation.fade(),
                  position: badges.BadgePosition.topEnd(top: -12, end: -10),
                  badgeContent: Text(
                    "${state.tickets}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _vipFond,
                    ),
                  ),
                  child: const Icon(Icons.receipt_outlined, color: _vipOr),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _vipOr))
          : Container(
              color: const Color(0xFFF0FBF5),
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: petitEcran ? screenWidth * 0.72 : screenWidth * 0.76,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _vipOr, width: 1.5),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: const Color.fromARGB(255, 227, 252, 237),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              // ── DERNIÈRE RANGÉE ──────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _rangee2([50, 49]),
                                  SizedBox(width: screenWidth * 0.09),
                                  _rangee2([48, 47]),
                                ],
                              ),

                              // ── CORPS DU BUS 2+2 ─────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── RANGÉE GAUCHE ─────────────────────────
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _rangee2([41, 42]),
                                      _rangee2([37, 38]),
                                      _rangee2([33, 34]),
                                      _rangee2([29, 30]),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                          bottom: 8.0,
                                          left: 8.0,
                                        ),
                                        child: porte(),
                                      ),
                                      _rangee2([25, 26]),
                                      _rangee2([21, 22]),
                                      _rangee2([17, 18]),
                                      _rangee2([13, 14]),
                                      _rangee2([9, 10]),
                                      _rangee2([5, 6]),
                                      Row(
                                        children: [
                                          PlacesVipReservees(numero: 1),
                                          PlacesVipReservees(numero: 2),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          top: 10.0,
                                        ),
                                        child: porte(),
                                      ),
                                    ],
                                  ),

                                  // ── COULOIR ───────────────────────────────
                                  SizedBox(width: screenWidth * 0.09),

                                  // ── RANGÉE DROITE ─────────────────────────
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _rangee2([45, 46]),
                                      _rangee2([43, 44]),
                                      _rangee2([39, 40]),
                                      _rangee2([35, 36]),
                                      _rangee2([31, 32]),
                                      const SizedBox(height: 4),
                                      _rangee2([27, 28]),
                                      _rangee2([23, 24]),
                                      _rangee2([19, 20]),
                                      _rangee2([15, 16]),
                                      _rangee2([11, 12]),
                                      _rangee2([7, 8]),
                                      Row(
                                        children: [
                                          PlacesVipReservees(numero: 3),
                                          PlacesVipReservees(numero: 4),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const SizedBox(width: 10),
                                          PlacesVipChauffeur(),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Container(
                                          height: screenWidth * 0.10,
                                          width: screenWidth * 0.13,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                'assets/images/volant4_sf.png',
                                              ),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),
            ),
      floatingActionButton: BlocBuilder<BlocCompteur, CompteurState>(
        builder: (context, state) {
          return badges.Badge(
            badgeStyle: const badges.BadgeStyle(
              badgeColor: _vipFond,
              padding: EdgeInsets.all(6),
            ),
            badgeAnimation: const badges.BadgeAnimation.fade(),
            position: badges.BadgePosition.topEnd(top: -10, end: -6),
            badgeContent: Text(
              '${state.tickets}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _vipOr,
              ),
            ),
            child: FloatingActionButton(
              backgroundColor: _vipOr,
              onPressed: () => _naviguerVersTickets(context, state),
              child: Text(
                'Valider',
                style: TextStyle(
                  color: _vipFond,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Place VIP cliquable (stateless : tout l'état vient du parent) ─────────────
class PlacesVip extends StatelessWidget {
  const PlacesVip({
    super.key,
    required this.numero,
    required this.isSelected,
    required this.isLoading,
    required this.isOccupied,
    required this.onTap,
  });
  final int numero;
  final bool isSelected;
  final bool isLoading;
  final bool isOccupied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double siegeSize = petitEcran
        ? screenWidth * 0.090
        : screenWidth * 0.093;

    final Color couleur = isOccupied
        ? _vipSiegeSelectionne
        : isSelected
        ? _vipSiegeSelectionne
        : _vipSiege;

    final Color textColor = isSelected
        ? Colors.white
        : isOccupied
        ? Colors.white
        : const Color(0xFF006B3C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.003),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              SizedBox(
                height: siegeSize,
                width: siegeSize,
                child: const CircularProgressIndicator(
                  color: _vipOr,
                  strokeWidth: 2,
                ),
              )
            else
              Card(
                color: couleur,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isOccupied ? Colors.transparent : _vipOr,
                    width: 0.5,
                  ),
                ),
                child: SizedBox(
                  height: siegeSize,
                  width: siegeSize,
                  child: Center(
                    child: Text(
                      numero.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.030,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: -screenWidth * 0.005,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: siegeSize * 0.5,
                  width: screenWidth * 0.015,
                ),
              ),
            ),
            Positioned(
              right: -screenWidth * 0.005,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: siegeSize * 0.5,
                  width: screenWidth * 0.015,
                ),
              ),
            ),
            Positioned(
              top: -screenWidth * 0.008,
              child: Card(
                color: _vipOr,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: screenWidth * 0.015,
                  width: siegeSize * 0.65,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Place VIP occupée ──────────────────────────────────────────────────────────
class PlacesVipReservees extends StatelessWidget {
  const PlacesVipReservees({super.key, required this.numero});
  final int numero;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double siegeSize = petitEcran
        ? screenWidth * 0.085
        : screenWidth * 0.095;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.003),
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: _vipSiegeReserve,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: siegeSize,
              width: siegeSize,
              child: Center(
                child: Text(
                  numero.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -screenWidth * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: siegeSize * 0.5,
                width: screenWidth * 0.015,
              ),
            ),
          ),
          Positioned(
            right: -screenWidth * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: siegeSize * 0.5,
                width: screenWidth * 0.015,
              ),
            ),
          ),
          Positioned(
            top: -screenWidth * 0.008,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: screenWidth * 0.015,
                width: siegeSize * 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Place chauffeur VIP ────────────────────────────────────────────────────────
class PlacesVipChauffeur extends StatelessWidget {
  const PlacesVipChauffeur({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double siegeSize = petitEcran
        ? screenWidth * 0.085
        : screenWidth * 0.090;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.003),
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: c.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(height: siegeSize, width: siegeSize),
          ),
          Positioned(
            left: -screenWidth * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: siegeSize * 0.5,
                width: screenWidth * 0.015,
              ),
            ),
          ),
          Positioned(
            right: -screenWidth * 0.005,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: siegeSize * 0.5,
                width: screenWidth * 0.015,
              ),
            ),
          ),
          Positioned(
            top: -screenWidth * 0.008,
            child: Card(
              color: _vipOr,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: screenWidth * 0.015,
                width: siegeSize * 0.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
