// ignore_for_file: unused_field, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/choixPlace.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/bloc/state.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/listeTicketAvantpaiement.dart';

// ignore: unused_element
String? _id, _depart, _destination, _date, _mois, _moisAnnee, _annee, _heure;
IO.Socket? _socket;
// ── Couleurs VIP ───────────────────────────────────────────────────────────────
const Color _vipOr = Color(0xFFFFD700);
const Color _vipFond = Color(0xFF1A1A2E);
const Color _vipSiege = Color(0xFF2C2C54);
const Color _vipSiegeSelectionne = Color(0xFFFFD700);
const Color _vipSiegeOccupe = Color(0xFF8B6914);

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

  @override
  State<ChoixPlacesVip> createState() => _ChoixPlacesVipState();
}

class _ChoixPlacesVipState extends State<ChoixPlacesVip> {
  int _seconds = 90;
  late Timer _timer;
  bool _isLoading = true;
  late IO.Socket socket;
  bool _socketConnecte = false;

  @override
  void initState() {
    super.initState();
    _id = widget.id;
    _date = widget.idDate;
    _mois = widget.mois;
    _moisAnnee = widget.moisAnnee;
    _annee = widget.annee;
    _heure = widget.heure;
    _depart = widget.depart;
    _destination = widget.destination;

    listeDesPlacesChoisies.clear();
    listeDeVerification.clear();
    listeDesPlacesOccupees.clear();
    _chargerPlacesViaHttp();
    _connecterSocket();
    startCountdown();
  }

  @override
  void dispose() {
    listeDesPlacesOccupees.clear();
    if (listeDeVerification.isNotEmpty && socket.connected) {
      socket.emit('liberer_places', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'numerosDePlace': listeDeVerification,
      });
    }
    listeDesPlacesChoisies.clear();
    listeDeVerification.clear();
    socket.off('places_chargees');
    socket.off('place_prise');
    socket.off('place_liberee');
    socket.off('connect');
    socket.offAny();
    socket.disconnect();
    socket.dispose();
    _timer.cancel();
    super.dispose();
  }

  void stopCountdown() {
    _timer.cancel();
    listeDesPlacesOccupees.clear();
    socket.off('places_chargees');
    socket.off('place_prise');
    socket.off('place_liberee');
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
          _timer.cancel();
          socket.off('places_chargees');
          socket.off('place_prise');
          socket.off('place_liberee');
          socket.offAny();
          socket.disconnect();
          Navigator.pop(context);
        }
      });
    });
  }

  // ── Chargement initial via HTTP ───────────────────────────────────────────
  Future<void> _chargerPlacesViaHttp() async {
    try {
      final documentId =
          '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h';
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/placesAssises.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'documentId': documentId}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            listeDesPlacesOccupees = List<int>.from(
              (data['places'] ?? []).map((p) => p['place']),
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
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
        _socket = socket;
    socket.connect();

    socket.onConnect((_) {
      if (!mounted) return;
      _socket = socket;
      setState(() => _socketConnecte = true);

      final documentId =
          '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h';

      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'mois': widget.mois,
        'moisAnnee': widget.moisAnnee,
        'annee': widget.annee,
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          socket.emit('charger_places', {'documentId': documentId});
        }
      });
    });

    socket.on('places_chargees', (data) {
      if (!mounted) return;
      setState(() {
        listeDesPlacesOccupees = List<int>.from(data['placesOccupees'] ?? []);
        _isLoading = false;
      });
    });

    socket.on('place_prise', (data) {
      if (!mounted) return;
      final int numeroDePlace = data['numeroDePlace'];
      setState(() {
        if (!listeDesPlacesOccupees.contains(numeroDePlace)) {
          listeDesPlacesOccupees.add(numeroDePlace);
        }
      });
    });

    socket.on('place_liberee', (data) {
      if (!mounted) return;
      final List<dynamic> numerosDePlace = data['numerosDePlace'];
      setState(() {
        for (var place in numerosDePlace) {
          listeDesPlacesOccupees.remove(place);
        }
      });
    });

    socket.onDisconnect((_) {
      if (!mounted) return;
      setState(() => _socketConnecte = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _vipFond,
      appBar: AppBar(
        toolbarHeight: screenHeight * 0.06,
        iconTheme: const IconThemeData(color: _vipOr),
        backgroundColor: const Color(0xFF0D0D1A),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: _vipOr, size: 16),
            const SizedBox(width: 6),
            Text(
              "${widget.depart} → ${widget.destination}  ${widget.heure} h",
              style: TextStyle(
                color: _vipOr,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.038,
              ),
            ),
          ],
        ),
        actions: [
          // ── Chrono ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.02),
            child: Center(
              child: Text(
                '$_seconds s',
                style: TextStyle(
                  color: _seconds <= 10 ? Colors.red : _vipOr,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.035,
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
              color: _vipFond,
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: petitEcran
                        ? MediaQuery.of(context).size.height * 0.95
                        : MediaQuery.of(context).size.height * 0.90,
                    width: petitEcran
                        ? MediaQuery.of(context).size.width * 0.80
                        : MediaQuery.of(context).size.width * 0.75,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: _vipOr, width: 1.5),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(50),
                          ),
                          color: const Color(0xFF16213E),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              // ── DERNIÈRE RANGÉE ──────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PlacesVipReservees(numero: 50),
                                  PlacesVipReservees(numero: 49),
                                  const SizedBox(width: 35),
                                  PlacesVipReservees(numero: 48),
                                  PlacesVipReservees(numero: 47),
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
                                      // Porte arrière gauche
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
                                      // Porte avant gauche
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
                                  const SizedBox(width: 35),

                                  // ── RANGÉE DROITE ─────────────────────────
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      _rangee2([45, 46]),
                                      _rangee2([43, 44]),
                                      _rangee2([39, 40]),
                                      _rangee2([35, 36]),
                                      _rangee2([31, 32]),
                                      SizedBox(height: 4),
                                      // Espace porte arrière
                                      //const SizedBox(height: 47),
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
                                      // Volant droite
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Container(
                                          height: 40,
                                          width: 50,
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
          return GestureDetector(
            onTap: () => _naviguerVersTickets(context, state),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                SizedBox(
                  height: 55,
                  width: 50,
                  child: FloatingActionButton(
                    backgroundColor: _vipOr,
                    onPressed: () => _naviguerVersTickets(context, state),
                    child: const Icon(Icons.receipt_outlined, color: _vipFond),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _vipFond,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    child: Text(
                      "${state.tickets}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _vipOr,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helper rangée de 2 places ──────────────────────────────────────────────
  Widget _rangee2(List<int> numeros) {
    return Row(children: numeros.map((n) => PlacesVip(numero: n)).toList());
  }

  // ── Navigation vers tickets ────────────────────────────────────────────────
  void _naviguerVersTickets(BuildContext context, CompteurState state) {
    if (listeDesPlacesChoisies.isNotEmpty) {
      stopCountdown();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Tickets(
            idDate: widget.idDate,
            nombreDeTicket: state.tickets,
            place: listeDesPlacesChoisies.toList(),
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
            typeVoyage: 'vip',
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: _vipFond,
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
              style: TextStyle(color: Colors.white70),
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
}

// ── Place VIP cliquable ────────────────────────────────────────────────────────
class PlacesVip extends StatefulWidget {
  const PlacesVip({super.key, required this.numero});
  final int numero;

  @override
  State<PlacesVip> createState() => _PlacesVipState();
}

class _PlacesVipState extends State<PlacesVip> {
  bool _selectionne = false;
  bool _isLoading = false;
  bool _occupe = false;

  @override
  void initState() {
    super.initState();
    _occupe = listeDesPlacesOccupees.contains(widget.numero);
  }

  @override
  void dispose() {
    if (listeDeVerification.contains(widget.numero) && _socket != null) {
      _socket!.emit('liberer_places', {
        'depart': _depart,
        'destination': _destination,
        'date': _date,
        'heure': _heure,
        'numerosDePlace': [widget.numero],
      });
      listeDeVerification.remove(widget.numero);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double siegeSize = petitEcran
        ? screenWidth * 0.085
        : screenWidth * 0.090;
    final BlocCompteur counterBloc = BlocProvider.of<BlocCompteur>(context);

    // Mise à jour temps réel
    if (listeDesPlacesOccupees.contains(widget.numero) && !_occupe) {
      _occupe = true;
      _selectionne = false;
    }

    final Color couleur = _occupe
        ? _vipSiegeOccupe
        : _selectionne
        ? _vipSiegeSelectionne
        : _vipSiege;

    final Color textColor = _selectionne ? _vipFond : _vipOr;

    return GestureDetector(
      onTap: () async {
        if (_occupe) return;
        setState(() {
          _isLoading = true;
          _selectionne = !_selectionne;
        });

        try {
          if (_selectionne) {
            _socket?.emit('choisir_place', {
              'depart': _depart,
              'destination': _destination,
              'date': _date,
              'heure': _heure,
              'mois': _mois,
              'moisAnnee': _moisAnnee,
              'annee': _annee,
              'numeroDePlace': widget.numero,
            });

            _socket?.once('place_confirmee', (data) {
              if (data['numeroDePlace'] == widget.numero) {
                if (mounted) setState(() => _isLoading = false);
                counterBloc.add(EventIcrement());
                listeDesPlacesChoisies.add(widget.numero);
                listeDeVerification.add(widget.numero);
              }
            });

            _socket?.once('place_echec', (data) {
              if (data['numeroDePlace'] == widget.numero) {
                if (mounted) {
                  setState(() {
                    _selectionne = false;
                    _isLoading = false;
                    _occupe = true;
                  });
                }
                showAlertDialog(context);
              }
            });
          } else {
            _socket?.emit('liberer_places', {
              'depart': _depart,
              'destination': _destination,
              'date': _date,
              'heure': _heure,
              'numerosDePlace': [widget.numero],
            });
            counterBloc.add(EventDecrement());
            listeDesPlacesChoisies.remove(widget.numero);
            listeDeVerification.remove(widget.numero);
            setState(() => _isLoading = false);
          }
        } catch (e) {
          setState(() => _isLoading = false);
        }
      },
      child: Container(
        margin: EdgeInsets.all(screenWidth * 0.003),
        padding: EdgeInsets.all(screenWidth * 0.002),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isLoading)
              SizedBox(
                height: siegeSize,
                width: siegeSize,
                child: const CircularProgressIndicator(
                  color: _vipOr,
                  strokeWidth: 2,
                ),
              )
            else
              // ── Siège principal ──────────────────────────────────────
              Card(
                color: couleur,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _occupe
                        ? Colors.transparent
                        : _vipOr.withOpacity(0.5),
                    width: 0.5,
                  ),
                ),
                child: SizedBox(
                  height: siegeSize,
                  width: siegeSize,
                  child: Center(
                    child: Text(
                      widget.numero.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                  ),
                ),
              ),
            // ── Accoudoir gauche ─────────────────────────────────────
            Positioned(
              left: -screenWidth * 0.005,
              child: Card(
                color: _vipOr.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: siegeSize * 0.5,
                  width: screenWidth * 0.015,
                ),
              ),
            ),
            // ── Accoudoir droit ──────────────────────────────────────
            Positioned(
              right: -screenWidth * 0.005,
              child: Card(
                color: _vipOr.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SizedBox(
                  height: siegeSize * 0.5,
                  width: screenWidth * 0.015,
                ),
              ),
            ),
            // ── Appuie-tête ──────────────────────────────────────────
            Positioned(
              top: -screenWidth * 0.008,
              child: Card(
                color: _vipOr.withOpacity(0.6),
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
        : screenWidth * 0.090;

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.003),
      padding: EdgeInsets.all(screenWidth * 0.002),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Card(
            color: _vipSiegeOccupe,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: siegeSize,
              width: siegeSize,
              child: Center(
                child: Text(
                  numero.toString(),
                  style: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.028,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: -screenWidth * 0.005,
            child: Card(
              color: _vipOr.withOpacity(0.3),
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
              color: _vipOr.withOpacity(0.3),
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
              color: _vipOr.withOpacity(0.3),
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
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(height: siegeSize, width: siegeSize),
          ),
          Positioned(
            left: -screenWidth * 0.005,
            child: Card(
              color: _vipOr.withOpacity(0.6),
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
              color: _vipOr.withOpacity(0.6),
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
              color: _vipOr.withOpacity(0.6),
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
