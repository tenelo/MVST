// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:mvst/mes_services/mesFonctions.dart';
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

class ChoixPlaces extends StatefulWidget {
  const ChoixPlaces({
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
  State<ChoixPlaces> createState() => _ChoixPlacesState();
}

class _ChoixPlacesState extends State<ChoixPlaces> {
  int _seconds = 60;
  late Timer _timer;
  bool _isLoading = true;
  late io.Socket socket;

  // ── État centralisé (remplace les globaux listeDesPlacesOccupees / listeDeVerification) ──
  final Set<int> _selectedSeats =
      {}; // confirmées par le serveur (= mes places)
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

    // ── Mises à jour temps réel des autres voyageurs ──────────────────────────
    socket.on('place_prise', (data) {
      if (!mounted) return;
      final int place = data['numeroDePlace'];
      // Ne pas marquer ses propres places comme occupées par un autre
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

    socket.onDisconnect((_) {});

    socket.connect();
  }

  // ── Logique de sélection centralisée ─────────────────────────────────────────
  void _onSeatTap(int numero) {
    // Ignorer si occupée ou en cours de traitement
    if (_occupiedSeats.contains(numero) || _loadingSeats.contains(numero)) {
      return;
    }

    if (_selectedSeats.contains(numero)) {
      // Désélectionner : immédiat, aucune attente serveur
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
      // Sélectionner : attendre confirmation serveur avant d'incrémenter
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

  void _naviguerVersTickets(BuildContext context, int ticketCount) {
    if (_selectedSeats.isNotEmpty) {
      // Le socket reste connecté pendant la navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Tickets(
            idDate: widget.idDate,
            nombreDeTicket: ticketCount,
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
            title: const Text(''),
            content: const Text('Vous n\'avez choisi aucune place.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _place(int numero) {
    return Places(
      key: ValueKey(numero),
      numero: numero,
      isSelected: _selectedSeats.contains(numero),
      isLoading: _loadingSeats.contains(numero),
      isOccupied: _occupiedSeats.contains(numero),
      onTap: () => _onSeatTap(numero),
    );
  }

  Widget _placeReservee(int numero) => PlacesReservees(numero: numero);

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final largeurEcran = MediaQuery.of(context).size.width;
    final hauteurEcran = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: c.homeBackground,
      appBar: AppBar(
        toolbarHeight: hauteurEcran * 0.06,
        iconTheme: IconThemeData(color: c.homeAccent),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${formaterHeure(widget.heure)} h",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: largeurEcran * 0.040,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: c.authButtonDisabled,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: largeurEcran * 0.02),
            child: Center(
              child: Text(
                '$_seconds s',
                style: TextStyle(
                  color: _seconds <= 10 ? Colors.red : c.homeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: largeurEcran * 0.040,
                ),
              ),
            ),
          ),
          BlocBuilder<BlocCompteur, CompteurState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: () => _naviguerVersTickets(context, state.tickets),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: badges.Badge(
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Color.fromARGB(255, 153, 228, 255),
                    ),
                    badgeAnimation: const badges.BadgeAnimation.fade(),
                    position: badges.BadgePosition.topEnd(top: -12, end: -10),
                    badgeContent: Text(
                      "${state.tickets}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Icon(
                      Icons.receipt_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: c.homeAccent,
                strokeWidth: 3,
              ),
            )
          : Container(
              color: const Color.fromARGB(69, 191, 217, 248),
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: petitEcran
                        ? hauteurEcran * 0.90
                        : hauteurEcran * 0.85,
                    width: petitEcran
                        ? largeurEcran * 0.82
                        : largeurEcran * 0.76,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Config.colors.jauneBlanc),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: const Color.fromARGB(168, 191, 217, 248),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _placeReservee(61),
                                  _placeReservee(60),
                                  _placeReservee(59),
                                  _placeReservee(58),
                                  _placeReservee(57),
                                  _placeReservee(56),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [_place(55), _place(54)]),
                                      Row(children: [_place(50), _place(49)]),
                                      Row(children: [_place(45), _place(44)]),
                                      Row(children: [_place(40), _place(39)]),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: porte(),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(children: [_place(35), _place(34)]),
                                      Row(children: [_place(30), _place(29)]),
                                      Row(children: [_place(25), _place(24)]),
                                      Row(children: [_place(20), _place(19)]),
                                      Row(children: [_place(15), _place(14)]),
                                      Row(children: [_place(10), _place(9)]),
                                      Row(
                                        children: [
                                          _placeReservee(5),
                                          _placeReservee(4),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: largeurEcran * 0.09),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          _place(53),
                                          _place(52),
                                          _place(51),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(48),
                                          _place(47),
                                          _place(46),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(43),
                                          _place(42),
                                          _place(41),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(38),
                                          _place(37),
                                          _place(36),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(33),
                                          _place(32),
                                          _place(31),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(28),
                                          _place(27),
                                          _place(26),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(23),
                                          _place(22),
                                          _place(21),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(18),
                                          _place(17),
                                          _place(16),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(13),
                                          _place(12),
                                          _place(11),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _place(8),
                                          _place(7),
                                          _place(6),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _placeReservee(3),
                                          _placeReservee(2),
                                          _placeReservee(1),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: largeurEcran * 0.155),
                                          PlacesChauffeur(),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [porte()],
                                  ),
                                  SizedBox(width: largeurEcran * 0.385),
                                  Column(
                                    children: [
                                      Container(
                                        height: largeurEcran * 0.10,
                                        width: largeurEcran * 0.13,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                              'assets/images/volant4_sf.png',
                                            ),
                                            fit: BoxFit.contain,
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
      floatingActionButton: BlocSelector<BlocCompteur, CompteurState, int>(
        selector: (state) => state.tickets,
        builder: (context, ticketCount) {
          return badges.Badge(
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Color.fromARGB(255, 182, 214, 251),
              padding: EdgeInsets.all(6),
            ),
            badgeAnimation: const badges.BadgeAnimation.fade(),
            position: badges.BadgePosition.topEnd(top: -10, end: -6),
            badgeContent: Text(
              '$ticketCount',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: FloatingActionButton(
              backgroundColor: c.authAccent,
              onPressed: () => _naviguerVersTickets(context, ticketCount),
              tooltip: 'Valider',
              child: Text(
                'Valider',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: largeurEcran * 0.035,
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

// ── Place cliquable (stateless : tout l'état vient du parent) ─────────────────
class Places extends StatelessWidget {
  const Places({
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

  static const Color _couleurDispo = Color.fromARGB(226, 10, 41, 66);
  static const Color _couleurPrise = Color.fromARGB(255, 182, 214, 251);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final Color couleurSiege = (isSelected || isOccupied)
        ? _couleurPrise
        : _couleurDispo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(petitEcran ? 0.5 : 1.0),
        padding: EdgeInsets.all(petitEcran ? 0.5 : 0.8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(color: Config.colors.couleurDfond)
            else
              Card(
                color: couleurSiege,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: w * 0.092,
                  width: w * 0.092,
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
              left: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.053, width: w * 0.014),
              ),
            ),
            Positioned(
              right: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.053, width: w * 0.014),
              ),
            ),
            Positioned(
              top: -4,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(height: w * 0.016, width: w * 0.067),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showAlertDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Place occupée à l\'instant'),
        content: const Text(
          'La place vient d\'être prise par quelqu\'un d\'autre',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

// ignore: must_be_immutable
class PlacesReservees extends StatelessWidget {
  PlacesReservees({super.key, required this.numero});
  final int numero;
  Color couleurSelection = const Color.fromARGB(166, 249, 195, 115);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.all(petitEcran ? 0.5 : 1.0),
      padding: EdgeInsets.all(petitEcran ? 0.5 : 0.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: couleurSelection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: w * 0.092,
              width: w * 0.092,
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
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.016, width: w * 0.067),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class PlacesChauffeur extends StatelessWidget {
  PlacesChauffeur({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.all(0.5),
      padding: const EdgeInsets.all(0.8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: w * 0.092,
              width: w * 0.092,
              child: const Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.053, width: w * 0.014),
            ),
          ),
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(height: w * 0.016, width: w * 0.067),
            ),
          ),
        ],
      ),
    );
  }
}
