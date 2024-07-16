import 'dart:async';

import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/bloc/state.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/listeTicketAvantpaiement.dart';

DateTime? dateActuelle = DateTime.now();
DateTime? dateDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 1);

List<int> listeDesPlacesChoisies = [];
String? _depart, _destination, _date, _heure;

class ChoixPlaces extends StatefulWidget {
  const ChoixPlaces(
      {super.key,
      required this.idDate,
      required this.id,
      required this.depart,
      required this.destination,
      required this.nom,
      required this.contact,
      required this.date,
      required this.heure,
      required this.prixDuBillet});
  final String idDate;
  final String id;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final int prixDuBillet;

  @override
  State<ChoixPlaces> createState() => _ChoixPlacesState();
}

class _ChoixPlacesState extends State<ChoixPlaces> {
  int _seconds = 30;
  late Timer _timer;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _date = widget.idDate;
    _heure = widget.heure;
    _depart = widget.depart;
    _destination = widget.destination;
    _loadData();
    startCountdown();
    listeDesPlacesChoisies.clear();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void stopCountdown() {
    _timer.cancel();
  }

  void startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _timer.cancel();
          Navigator.pop(context);
        }
      });
    });
  }

  Future<void> _loadData() async {
    try {
      await ClasseListeDesPlaces.getTicketsStream;
      setState(() {
        _isLoading = false; // Les données sont chargées
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(93, 12, 134, 195),
      appBar: AppBar(
        toolbarHeight: 40,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: Center(
          child: Text(
            "${widget.depart} -> ${widget.destination}  ${widget.heure} h",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(132, 5, 82, 121),
        actions: [
          BlocBuilder<BlocCompteur, CompteurState>(
            builder: (context, state) {
              return IconButton(
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
                          content:
                              const Text('Vous n\'avez choisi aucune place.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                icon: badges.Badge(
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Color.fromARGB(255, 153, 228, 255),
                  ),
                  badgeAnimation: const badges.BadgeAnimation.fade(),
                  position: badges.BadgePosition.topEnd(top: -12, end: -10),
                  badgeContent: Text(
                    "${state.tickets}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Erreur: $_errorMessage'))
              : Container(
                  color: const Color.fromARGB(69, 191, 217, 248),
                  child: Center(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.80,
                      width: MediaQuery.of(context).size.width * 0.70,
                      child: Padding(
                        padding: const EdgeInsets.all(1.5),
                        child: Container(
                          height: double.infinity,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Config.colors.jauneBlanc),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(50),
                            ),
                            color: const Color.fromARGB(168, 191, 217, 248),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                // DERNIERE RANGEE
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PlacesReservees(
                                      index: 61,
                                    ),
                                    PlacesReservees(
                                      index: 60,
                                    ),
                                    PlacesReservees(
                                      index: 59,
                                    ),
                                    PlacesReservees(
                                      index: 58,
                                    ),
                                    PlacesReservees(
                                      index: 57,
                                    ),
                                    PlacesReservees(
                                      index: 56,
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // RANGE DE 2 SIEGES
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        //col1
                                        const Row(
                                          children: [
                                            Places(
                                              index: 55,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 54,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 50,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 49,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 45,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 44,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 40,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 39,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        //PORTE ARRIERE
                                        porte(),
                                        const SizedBox(
                                          height: 1,
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 35,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 34,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 30,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 29,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 25,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 24,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 20,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 19,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 15,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 14,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Places(
                                              index: 10,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 9,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            PlacesReservees(
                                              index: 5,
                                            ),
                                            PlacesReservees(
                                              index: 4,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // ESPACE DU MILEIU
                                    const SizedBox(
                                      width: 35,
                                    ),
                                    // RANGE DE 3 SIEGES
                                    Column(
                                      children: [
                                        Row(
                                          children: [
                                            Places(
                                              index: 53,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 52,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 51,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 48,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 47,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 46,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 43,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 42,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 41,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 38,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 37,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 36,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 33,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 32,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 31,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 28,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 27,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 26,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 23,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 22,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 21,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 18,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 17,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 16,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 13,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 12,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 11,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Places(
                                              index: 8,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 7,
                                              clicable: "true",
                                            ),
                                            Places(
                                              index: 6,
                                              clicable: "true",
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            PlacesReservees(
                                              index: 3,
                                            ),
                                            PlacesReservees(
                                              index: 2,
                                            ),
                                            PlacesReservees(
                                              index: 1,
                                            ),
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
                                // COLONNE DE 2
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // PORTE AVANT
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        porte(),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 150,
                                    ),
                                    // Colonne pour le volant
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
      floatingActionButton: BlocBuilder<BlocCompteur, CompteurState>(
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
                      content: const Text('Vous n\'avez choisi aucune place.'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Stack(
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
                                  'Vous n\'avez choisi aucune place.'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
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
            ),
          );
        },
      ),
    );
  }
}

class Places extends StatefulWidget {
  const Places({super.key, required this.index, required this.clicable});
  final int index;
  final String clicable;
  @override
  State<Places> createState() => _PlacesState();
}

class _PlacesState extends State<Places> {
  Color couleurSelection = const Color.fromARGB(255, 182, 214, 251);
  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);
  String control = "true";
  @override
  void initState() {
    super.initState();
    verification();
  }

  void verification() {
    if (listeDesNumeros.contains(widget.index)) {
      couleurInitiale = couleurSelection;
      control = "false";
    }
  }

  void rafraichissement() {
    final collectionRef = FirebaseFirestore.instance.collection('tickets');
    // ignore: unused_local_variable
    final subscription = collectionRef.snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        setState(() {});
      });
    });
  }

  // La liste de booléens qui représente la sélection de chaque carte
  // On crée une liste de 62 booléens
  List<bool> selection = List.filled(62, false);
  @override
  Widget build(BuildContext context) {
    final BlocCompteur counterBloc = BlocProvider.of<BlocCompteur>(context);
    return GestureDetector(
      onTap: () {
        if (control == "true") {
          setState(() {
            selection[widget.index] = !selection[widget.index];
            if (selection[widget.index]) {
              counterBloc.add(EventIcrement());
              ClasseListeDesPlaces.getTicketsStream(
                  _depart!, _destination!, _date!, _heure!);
              verification();
              listeDesPlacesChoisies.add(widget.index);
            } else {
              counterBloc.add(EventDecrement());
              ClasseListeDesPlaces.getTicketsStream(
                  _depart!, _destination!, _date!, _heure!);
              verification();
              listeDesPlacesChoisies.remove(widget.index);
            }
          });
        } else {}
      },
      child: Container(
        // Espaces entre les sièges
        margin: const EdgeInsets.all(0.5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // CARTE PRINCIPALE
            Card(
              color: selection[
                      widget.index % 62] // On utilise l'index modulo 25
                  ? couleurSelection
                  : couleurInitiale, // On utilise la couleur selon la sélection
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: SizedBox(
                height: 35,
                width: 35,
                child: Center(
                  child: Text(
                    (widget.index)
                        .toString(), // On convertit l'index en chaîne de caractères
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            // CARTE GAUCHE
            Positioned(
              left: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 19,
                  width: 6,
                ),
              ),
            ), // CARTE DROITE
            Positioned(
              right: -3,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 19,
                  width: 6,
                ),
              ),
            ),
            //CARTE DU HAUT
            Positioned(
              top: -4,
              child: Card(
                color: const Color.fromARGB(255, 182, 214, 251),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const SizedBox(
                  height: 6,
                  width: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class PlacesReservees extends StatelessWidget {
  PlacesReservees({super.key, required this.index});
  final int index;
  Color couleurSelection = Color.fromARGB(166, 249, 195, 115);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Espaces entre les sièges
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CARTE PRINCIPALE
          Card(
            color: couleurSelection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              height: 35,
              width: 35,
              child: Center(
                child: Text(
                  index.toString(),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // CARTE GAUCHE
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ), // CARTE DROITE
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ),
          //CARTE DU HAUT
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 6,
                width: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class PlacesChauffeur extends StatelessWidget {
  PlacesChauffeur({
    super.key,
  });

  Color couleurInitiale = const Color.fromARGB(226, 10, 41, 66);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Espaces entre les sièges
      margin: const EdgeInsets.all(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CARTE PRINCIPALE
          Card(
            color: Config.colors.vertB,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const SizedBox(
              height: 35,
              width: 35,
              child: Center(
                child: Text(
                  (""), // On convertit l'index en chaîne de caractères
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // CARTE GAUCHE
          Positioned(
            left: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ), // CARTE DROITE
          Positioned(
            right: -3,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 19,
                width: 6,
              ),
            ),
          ),
          //CARTE DU HAUT
          Positioned(
            top: -4,
            child: Card(
              color: const Color.fromARGB(255, 182, 214, 251),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: const SizedBox(
                height: 6,
                width: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
