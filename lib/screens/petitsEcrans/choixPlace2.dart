// ignore_for_file: unused_local_variable

import 'dart:async';

import 'package:badges/badges.dart' as badges;
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
String? _id, _depart, _destination, _date, _mois, _moisAnnee, _annee, _heure;

class ChoixPlaces2 extends StatefulWidget {
  const ChoixPlaces2(
      {super.key,
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
      required this.prixDuBillet});
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
  State<ChoixPlaces2> createState() => _ChoixPlaces2State();
}

class _ChoixPlaces2State extends State<ChoixPlaces2> {
  int _seconds = 30;
  late Timer _timer;

  bool _isLoading = true;
  String? _errorMessage;

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
    _loadData();
    startCountdown();
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
      await ClasseListeDesPlaces.verifierEtRecupererPlaces(
          widget.depart,
          widget.destination,
          widget.idDate,
          widget.heure,
          widget.mois,
          widget.moisAnnee,
          widget.annee);
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
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.95,
                        width: MediaQuery.of(context).size.width * 0.70,
                        child: Padding(
                          padding: const EdgeInsets.all(1.5),
                          child: Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: Config.colors.jauneBlanc),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(50),
                              ),
                              color: const Color.fromARGB(168, 191, 217, 248),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
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
                                                numero: 55,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 54,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 50,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 49,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 45,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 44,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 40,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 39,
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
                                                numero: 35,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 34,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 30,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 29,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 25,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 24,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 20,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 19,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 15,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 14,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          const Row(
                                            children: [
                                              Places(
                                                numero: 10,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 9,
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
                                                numero: 53,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 52,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 51,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 48,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 47,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 46,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 43,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 42,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 41,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 38,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 37,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 36,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 33,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 32,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 31,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 28,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 27,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 26,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 23,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 22,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 21,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 18,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 17,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 16,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 13,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 12,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 11,
                                                clicable: "true",
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Places(
                                                numero: 8,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 7,
                                                clicable: "true",
                                              ),
                                              Places(
                                                numero: 6,
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
    if (listeDeVerification.isNotEmpty) {
      await supprimerPlaces(
        _depart!,
        _destination!,
        _date!,
        _id!,
        _mois!,
        _moisAnnee!,
        _annee!,
        _heure!,
        listeDeVerification,
      );
    }
    listeDeVerification.clear();
    return true;
  }

  // La liste de booléens qui représente la sélection de chaque carte
  // On crée une liste de 62 booléens
  List<bool> selection = List.filled(62, false);

  @override
  Widget build(BuildContext context) {
    final BlocCompteur counterBloc = BlocProvider.of<BlocCompteur>(context);
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
                var resultat = await verifierPlace(
                  _depart!,
                  _destination!,
                  _date!,
                  _id!,
                  _mois!,
                  _moisAnnee!,
                  _annee!,
                  _heure!,
                  widget.numero,
                );

                if (resultat == 'succès') {
                  counterBloc.add(EventIcrement());
                  listeDesPlacesChoisies.add(widget.numero);
                  listeDeVerification.add(widget.numero);
                } else {
                  setState(() {
                    selection[widget.numero] = false;
                  });
                  showAlertDialog(context);
                }
              } else {
                await supprimerPlaces(
                  _depart!,
                  _destination!,
                  _date!,
                  _id!,
                  _mois!,
                  _moisAnnee!,
                  _annee!,
                  _heure!,
                  [widget.numero],
                );
                counterBloc.add(EventDecrement());
                listeDesPlacesChoisies.remove(widget.numero);
                listeDeVerification.remove(widget.numero);
              }
            } catch (error) {
            } finally {
              setState(() {
                isLoading = false;
              });
            }
          }
        },
        child: Container(
          // Espaces entre les sièges
          margin: const EdgeInsets.all(0.5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                // CARTE PRINCIPALE
                Card(
                  color: selection[widget.numero % 62]
                      ? couleurSelection
                      : couleurInitiale,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox(
                    height: 35,
                    width: 35,
                    child: Center(
                      child: Text(
                        widget.numero.toString(),
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
              ),
              // CARTE DROITE
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
              // CARTE DU HAUT
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
            onPressed: () {
              Navigator.of(context).pop(); // Ferme l'alerte
            },
          ),
        ],
      );
    },
  );
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
