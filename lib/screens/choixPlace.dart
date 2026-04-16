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

  // ── Helper pour construire un widget Places avec la liste à jour ──────────
  Widget _place(int numero) {
    return Places(
      key: ValueKey(
        'place_${numero}_${listeDesPlacesOccupees.contains(numero)}',
      ),
      numero: numero,
      clicable: "true",
      placesOccupees: List<int>.from(listeDesPlacesOccupees),
    );
  }

  Widget _placeReservee(int numero) {
    return PlacesReservees(numero: numero);
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        iconTheme: IconThemeData(color: c.homeAccent),
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
        backgroundColor: c.authButtonDisabled,
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
                                  const SizedBox(width: 35),
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
      floatingActionButton: BlocSelector<BlocCompteur, CompteurState, int>(
        selector: (state) => state.tickets,
        builder: (context, ticketCount) {
          return badges.Badge(
            badgeStyle: const badges.BadgeStyle(
              badgeColor: Color.fromARGB(255, 182, 214, 251),
              padding: EdgeInsets.all(6),
            ),
            badgeAnimation: const badges.BadgeAnimation.fade(),
            position: badges.BadgePosition.topEnd(top: -6, end: -6),
            badgeContent: Text(
              '$ticketCount',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            child: FloatingActionButton(
              onPressed: () {
                if (listeDesPlacesChoisies.isNotEmpty) {
                  final state = BlocProvider.of<BlocCompteur>(context).state;
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
              tooltip: 'Voir les tickets',
              child: const Icon(Icons.receipt_outlined),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class Places extends StatefulWidget {
  const Places({
    super.key,
    required this.numero,
    required this.clicable,
    required this.placesOccupees, // ← AJOUT
  });
  final int numero;
  final String clicable;
  final List<int> placesOccupees; // ← AJOUT

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
    if (widget.placesOccupees.contains(widget.numero)) {
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

    // ── Couleur dynamique selon placesOccupees passé par le parent ───────────
    final bool estOccupee = widget.placesOccupees.contains(widget.numero);
    final Color couleurAffichee = selection[widget.numero % 62]
        ? couleurSelection
        : estOccupee
        ? couleurSelection
        : couleurInitiale;

    if (estOccupee && etat == "cliquable") {
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
                  color: couleurAffichee, // ← utilise la couleur dynamique
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
