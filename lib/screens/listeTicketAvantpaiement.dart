import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';
import 'package:mvst/paiement/choixPaiement.dart';
import 'package:mvst/screens/petitsEcrans/choixPaiement2.dart';
import 'package:ticket_material/ticket_material.dart';

int? tailleEcran;

class Tickets extends StatefulWidget {
  const Tickets(
      {super.key,
      required this.idDate,
      required this.nombreDeTicket,
      required this.place,
      required this.id,
      required this.nom,
      required this.contact,
      required this.date,
      required this.heure,
      required this.destination,
      required this.depart,
      required this.prixDuTicket});
  final String idDate;
  final String id;
  final int nombreDeTicket;
  final List<int> place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String destination;
  final String depart;
  final int prixDuTicket;

  @override
  State<Tickets> createState() => _TicketsState();
}

class _TicketsState extends State<Tickets> {
  bool _isLoading = false;
  bool _isNavigating = false; // Variable d'état pour la navigation

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();
    return Scaffold(
      backgroundColor: Config.colors.bleuFonce,
      appBar: AppBar(
        toolbarHeight: 40,
        centerTitle: true,
        title: const Text(
          'Ticket(s) commandé(s)',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Config.colors.bleuFonce,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: widget.nombreDeTicket,
            itemBuilder: (BuildContext context, int index) {
              int numDePlace = widget.place[index];
              listeDeVerification
                  .add(numDePlace); // Ajoute les places à vérifier
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TicketMaterial(
                  height: 100,
                  colorBackground: const Color.fromARGB(210, 48, 196, 222),
                  colorShadow: Colors.white,
                  shadowSize: 2,
                  radiusBorder: 8,
                  leftChild: _buildLeft(
                    widget.id,
                    widget.nom,
                    widget.contact,
                    widget.date,
                    widget.heure,
                    numDePlace,
                  ),
                  rightChild: _buildRight(),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20.0),
        width: MediaQuery.of(context).size.width * 0.55,
        child: ElevatedButton(
          onPressed: () async {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _isNavigating = true; // Indiquer que la navigation est en cours
              });
            }

            if (widget.nombreDeTicket == 0) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _isNavigating = false; // Réinitialiser l'état
                });
              }

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text(''),
                    content: const Text('Aucun ticket en cours'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            } else {
              if (tailleEcran! >= 6) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoixPaiement(
                      idDate: widget.idDate,
                      nombreDeTicket: widget.nombreDeTicket,
                      prixUnitaire: widget.prixDuTicket,
                      id: widget.id,
                      place: widget.place,
                      nom: widget.nom,
                      contact: widget.contact,
                      date: widget.date,
                      heure: widget.heure,
                      destination: widget.destination,
                      depart: widget.depart,
                    ),
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoixPaiement2(
                      idDate: widget.idDate,
                      nombreDeTicket: widget.nombreDeTicket,
                      prixUnitaire: widget.prixDuTicket,
                      id: widget.id,
                      place: widget.place,
                      nom: widget.nom,
                      contact: widget.contact,
                      date: widget.date,
                      heure: widget.heure,
                      destination: widget.destination,
                      depart: widget.depart,
                    ),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Config.colors.jauneBlanc,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Text(
                  "Passer au paiement",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLeft(String id, String nom, String contact, String date,
      String heure, int? numeroDePlace) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        top: 8,
        right: 2,
        bottom: 2,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Départ du : ",
                style: TextStyle(
                    decorationColor: Colors.white,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 100, 99, 99)),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Heure de départ : ",
                style: TextStyle(
                    decorationColor: Colors.white,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 100, 99, 99)),
              ),
              Text(
                heure,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Siège : ",
                style: TextStyle(
                    fontSize: 16,
                    decorationColor: Colors.white,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 100, 99, 99)),
              ),
              Text(
                "N° $numeroDePlace",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRight() {
    return Center(
      child: Text(
        "MVST",
        style: TextStyle(
          decorationColor: Colors.white,
          color: Config.colors.vertB,
          fontFamily: 'Lobster',
          shadows: const [
            Shadow(
              color: Colors.white,
              offset: Offset(1, 1),
              blurRadius: 1,
            ),
            Shadow(
              color: Colors.white,
              offset: Offset(-1, -1),
              blurRadius: 1,
            ),
            Shadow(
              color: Colors.white,
              offset: Offset(1, -1),
              blurRadius: 1,
            ),
            Shadow(
              color: Colors.white,
              offset: Offset(-1, 1),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}
// ::::::::::::::::::::::::::::::::::::::::::::::::::::::

/*
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
    if (ListeDesPlaces.listeNummeros.contains(widget.index)) {
      couleurInitiale = couleurSelection;
      control = "false";
    }
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
              ClasseListeDesPlaces.getTicketsStream();
              verification();
              listeDesPlacesChoisies.add(widget.index);
            } else {
              counterBloc.add(EventDecrement());
              ClasseListeDesPlaces.getTicketsStream();
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

class PlacesVide extends StatefulWidget {
  const PlacesVide({
    super.key,
  });

  @override
  State<PlacesVide> createState() => _PlacesVideState();
}

class _PlacesVideState extends State<PlacesVide> {
  Color couleurSelection = const Color.fromARGB(255, 182, 214, 251);

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

class PlacesChauffeur extends StatefulWidget {
  const PlacesChauffeur({
    super.key,
  });

  @override
  State<PlacesChauffeur> createState() => _PlacesChauffeurState();
}

class _PlacesChauffeurState extends State<PlacesChauffeur> {
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

*/