import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';
import 'package:mvst/paiement/choixPaiement.dart';
import 'package:mvst/paiement/choixPaiement2.dart';
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
      required this.mois,
      required this.heure,
      required this.destination,
      required this.depart,
      required this.prixDuTicket,
      required this.moisAnnee,
      required this.annee});
  final String idDate;
  final String id;
  final int nombreDeTicket;
  final List<int> place;
  final String nom;
  final String contact;
  final String date;
  final String mois;
  final String moisAnnee;
  final String annee;
  final String heure;
  final String destination;
  final String depart;
  final int prixDuTicket;

  @override
  State<Tickets> createState() => _TicketsState();
}

class _TicketsState extends State<Tickets> {
  bool _isLoading = false;
  bool _isNavigating = false;

  @override
  void dispose() {
    // Ne pas nettoyer si l'utilisateur navigue vers une autre page
    if (!_isNavigating) {
      _netoyageEnCasDeFermeture();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();
    return WillPopScope(
      onWillPop: () async {
        if (!_isNavigating) {
          // Si l'utilisateur revient en arrière, lancer la fonction de nettoyage
          await _netoyageEnCasDeFermeture();
        }
        return true;
      },
      child: Scaffold(
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
              DateFormat formatInitiale =
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR');
              DateTime _dateCalcule = formatInitiale.parse(widget.date);
              String _dateformatee =
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(_dateCalcule);
              DateTime dateFormatee = DateTime.parse(_dateformatee).toUtc();

              if (mounted) {
                setState(() {
                  _isLoading = true;
                  _isNavigating = true; // Indique que l'utilisateur avance
                });
              }

              if (widget.nombreDeTicket == 0) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isNavigating = false;
                  });
                }

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
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
                // Navigation vers les pages suivantes
                Widget page = tailleEcran! >= 6
                    ? // Grands écrants
                    ChoixPaiement(
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
                        mois: widget.mois,
                        moisAnnee: widget.moisAnnee,
                        annee: widget.annee,
                        datePourCalcule: dateFormatee,
                      )
                    : // Petits écrants
                    ChoixPaiement2(
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
                        mois: widget.mois,
                        moisAnnee: widget.moisAnnee,
                        annee: widget.annee,
                        datePourCalcule: dateFormatee,
                      );

                await Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => page),
                );
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
      ),
    );
  }

  Widget _buildLeft(String id, String nom, String contact, String date,
      String heure, int? numeroDePlace) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 2,
        top: 8,
        right: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
          )
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

  Future<bool> _netoyageEnCasDeFermeture() async {
    if (listeDeVerification.isNotEmpty) {
      await supprimerPlaces(
        widget.depart,
        widget.destination,
        widget.idDate,
        widget.id,
        widget.mois,
        widget.moisAnnee,
        widget.annee,
        widget.heure,
        listeDeVerification,
      );
    }
    listeDeVerification.clear();
    return true;
  }
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}
