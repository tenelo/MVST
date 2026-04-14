// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mvst/models/mesFonctions.dart';
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

List<int> listeDesPlacesChoisies = [];
String? _depart, _destination, _date, _mois, _moisAnnee, _annee, _heure;
IO.Socket? _socket;

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
  State<ChoixPlaces> createState() => _ChoixPlacesState();
}

class _ChoixPlacesState extends State<ChoixPlaces> {
  int _seconds = 50;
  late Timer _timer;
  bool _isLoading = true;
  late IO.Socket socket;
  @override
  void initState() {
    super.initState();
    _socket = null;
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

  // ── Socket.IO pour mises à jour temps réel uniquement ────────────────────
  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;
    socket.connect();

    socket.onConnect((_) {
      if (!mounted) return;
      _socket = socket;

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

    socket.onDisconnect((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.colors.homeBackground,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${widget.heure} h",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: MediaQuery.of(context).size.width * 0.045,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Config.colors.homeDrawerBackground,
        actions: [
          BlocBuilder<BlocCompteur, CompteurState>(
            builder: (context, state) {
              return GestureDetector(
                onTap: () {
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
                        ),
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text(''),
                          content: const Text(
                            'Vous n\'avez choisi aucune place.',
                          ),
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
                },
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
                color: Config.colors.couleurDfond,
              ),
            )
          : Container(
              color: const Color.fromARGB(69, 191, 217, 248),
              child: Center(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: petitEcran
                        ? MediaQuery.of(context).size.height * 0.90
                        : MediaQuery.of(context).size.height * 0.85,
                    width: petitEcran
                        ? MediaQuery.of(context).size.width * 0.82
                        : MediaQuery.of(context).size.width * 0.76,
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
                              // DERNIERE RANGEE
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  PlacesReservees(numero: 61),
                                  PlacesReservees(numero: 60),
                                  PlacesReservees(numero: 59),
                                  PlacesReservees(numero: 58),
                                  PlacesReservees(numero: 57),
                                  PlacesReservees(numero: 56),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Places(numero: 55, clicable: "true"),
                                          Places(numero: 54, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 50, clicable: "true"),
                                          Places(numero: 49, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 45, clicable: "true"),
                                          Places(numero: 44, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 40, clicable: "true"),
                                          Places(numero: 39, clicable: "true"),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: porte(),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          Places(numero: 35, clicable: "true"),
                                          Places(numero: 34, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 30, clicable: "true"),
                                          Places(numero: 29, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 25, clicable: "true"),
                                          Places(numero: 24, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 20, clicable: "true"),
                                          Places(numero: 19, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 15, clicable: "true"),
                                          Places(numero: 14, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 10, clicable: "true"),
                                          Places(numero: 9, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          PlacesReservees(numero: 5),
                                          PlacesReservees(numero: 4),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 35),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Places(numero: 53, clicable: "true"),
                                          Places(numero: 52, clicable: "true"),
                                          Places(numero: 51, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 48, clicable: "true"),
                                          Places(numero: 47, clicable: "true"),
                                          Places(numero: 46, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 43, clicable: "true"),
                                          Places(numero: 42, clicable: "true"),
                                          Places(numero: 41, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 38, clicable: "true"),
                                          Places(numero: 37, clicable: "true"),
                                          Places(numero: 36, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 33, clicable: "true"),
                                          Places(numero: 32, clicable: "true"),
                                          Places(numero: 31, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 28, clicable: "true"),
                                          Places(numero: 27, clicable: "true"),
                                          Places(numero: 26, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 23, clicable: "true"),
                                          Places(numero: 22, clicable: "true"),
                                          Places(numero: 21, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 18, clicable: "true"),
                                          Places(numero: 17, clicable: "true"),
                                          Places(numero: 16, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 13, clicable: "true"),
                                          Places(numero: 12, clicable: "true"),
                                          Places(numero: 11, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Places(numero: 8, clicable: "true"),
                                          Places(numero: 7, clicable: "true"),
                                          Places(numero: 6, clicable: "true"),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          PlacesReservees(numero: 3),
                                          PlacesReservees(numero: 2),
                                          PlacesReservees(numero: 1),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 60),
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
                                  const SizedBox(width: 150),
                                  Column(
                                    children: [
                                      Container(
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
          return Stack(
            alignment: Alignment.topRight,
            children: [
              SizedBox(
                height: 55,
                width: 50,
                child: FloatingActionButton(
                  onPressed: () {
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
                          ),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text(''),
                            content: const Text(
                              'Vous n\'avez choisi aucune place.',
                            ),
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
                  },
                  tooltip: 'Incrémenter',
                  child: const Icon(Icons.receipt_outlined),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 182, 214, 251),
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
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class Places extends StatefulWidget {
  const Places({super.key, required this.numero, required this.clicable});
  final int numero;
  final String clicable;

  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  Color couleurSelection = const Color.fromARGB(255, 182, 214, 251);
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);
  String etat = "cliquable";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    verification();
  }

  @override
  void dispose() {
    _netoyageEnCasDeFermeture();
    super.dispose();
  }

  void verification() {
    if (listeDesPlacesOccupees.contains(widget.numero)) {
      couleurInitiale = couleurSelection;
      etat = "nonCliquable";
    }
  }

  Future<bool> _netoyageEnCasDeFermeture() async {
    if (listeDeVerification.isNotEmpty && _socket != null) {
      _socket!.emit('liberer_places', {
        'depart': _depart,
        'destination': _destination,
        'date': _date,
        'heure': _heure,
        'numerosDePlace': listeDeVerification,
      });
    }
    listeDeVerification.clear();
    return true;
  }

  List<bool> selection = List.filled(62, false);

  @override
  Widget build(BuildContext context) {
    final BlocCompteur counterBloc = BlocProvider.of<BlocCompteur>(context);

    if (listeDesPlacesOccupees.contains(widget.numero) && etat == "cliquable") {
      couleurInitiale = couleurSelection;
      etat = "nonCliquable";
    }

    return WillPopScope(
      onWillPop: _netoyageEnCasDeFermeture,
      child: GestureDetector(
        onTap: () async {
          if (etat == "cliquable") {
            setState(() {
              isLoading = true;
              selection[widget.numero] = !selection[widget.numero];
            });

            try {
              if (selection[widget.numero]) {
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
                    if (mounted) setState(() => isLoading = false);
                    counterBloc.add(EventIcrement());
                    listeDesPlacesChoisies.add(widget.numero);
                    listeDeVerification.add(widget.numero);
                  }
                });

                _socket?.once('place_echec', (data) {
                  if (data['numeroDePlace'] == widget.numero) {
                    if (mounted) {
                      setState(() {
                        selection[widget.numero] = false;
                        isLoading = false;
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
                setState(() => isLoading = false);
              }
            } catch (error) {
              setState(() => isLoading = false);
            }
          }
        },
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
                  color: selection[widget.numero % 62]
                      ? couleurSelection
                      : couleurInitiale,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    height: petitEcran ? 33 : 38,
                    width: petitEcran ? 33 : 38,
                    child: Center(
                      child: Text(
                        widget.numero.toString(),
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
                  child: SizedBox(
                    height: petitEcran ? 19 : 21,
                    width: petitEcran ? 5 : 6,
                  ),
                ),
              ),
              Positioned(
                right: -3,
                child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    height: petitEcran ? 19 : 21,
                    width: petitEcran ? 5 : 6,
                  ),
                ),
              ),
              Positioned(
                top: -4,
                child: Card(
                  color: const Color.fromARGB(255, 182, 214, 251),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const SizedBox(height: 6, width: 26),
                ),
              ),
            ],
          ),
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
        title: Text('Place occupée à l\'instant'),
        content: Text('La place vient d\'être prise par quelqu\'un d\'autre'),
        actions: [
          TextButton(
            child: Text('OK'),
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
  Color couleurSelection = Color.fromARGB(166, 249, 195, 115);

  @override
  Widget build(BuildContext context) {
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
              height: petitEcran ? 33 : 38,
              width: petitEcran ? 33 : 38,
              child: Center(
                child: Text(
                  numero.toString(),
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
              child: SizedBox(
                height: petitEcran ? 19 : 21,
                width: petitEcran ? 5 : 6,
              ),
            ),
          ),
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: petitEcran ? 19 : 21,
                width: petitEcran ? 5 : 6,
              ),
            ),
          ),
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(height: 6, width: 26),
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
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);

  @override
  Widget build(BuildContext context) {
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
              height: petitEcran ? 33 : 38,
              width: petitEcran ? 33 : 38,
              child: Center(
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
              child: SizedBox(
                height: petitEcran ? 19 : 21,
                width: petitEcran ? 5 : 6,
              ),
            ),
          ),
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: petitEcran ? 19 : 21,
                width: petitEcran ? 5 : 6,
              ),
            ),
          ),
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(height: 6, width: 26),
            ),
          ),
        ],
      ),
    );
  }
}
