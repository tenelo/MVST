import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/detailsTickets.dart';
import 'package:mvst/screens/petitsEcrans/detailsTickets2.dart';
import 'package:ticket_material/ticket_material.dart';

int? tailleEcran;

Color? couleurTicket;
DateTime? dateActuelle = DateTime.now();
DateTime? dateDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 1);
DateTime? dateApresDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 2);
DateTime? dateAujourdhui =
    DateTime.utc(dateActuelle!.year, dateActuelle!.month, dateActuelle!.day);

String? dateDAujourdhui;
String? dateDeDemain;
String? dateDapresDemain;

class MesTickets extends StatefulWidget {
  const MesTickets({
    super.key,
    required this.idUtilisateur,
  });
  final String idUtilisateur;
  @override
  State<MesTickets> createState() => _MesTicketsState();
}

class _MesTicketsState extends State<MesTickets> {
  @override
  void initState() {
    super.initState();
    dateActuelle = DateTime.now();
    dateDAujourdhui =
        DateFormat('EEEE d MMMM y', 'fr_FR').format(dateAujourdhui!);
    dateDeDemain = DateFormat('EEEE d MMMM y', 'fr_FR').format(dateDemain!);
    dateDapresDemain =
        DateFormat('EEEE d MMMM y', 'fr_FR').format(dateApresDemain!);
  }

  Stream<List<Map<String, dynamic>>> recuperationDeMesTickets() async* {
    final conn = await Connexion.connexionDB();
    try {
      var results = await conn.query(
          'SELECT * FROM Tickets WHERE idUtilisateur = ? ORDER BY dateDeCreation DESC LIMIT 30',
          [widget.idUtilisateur]);

      List<Map<String, dynamic>> tickets = [];
      for (var row in results) {
        tickets.add({
          'id': row['id'],
          'documentId': row['documentId'],
          'idUtilisateur': row['idUtilisateur'],
          'nom': row['nom'],
          'telephone': row['telephone'],
          'date': row['date'],
          'heure': row['heure'],
          'depart': row['depart'],
          'destination': row['destination'],
          'prixDuTicket': row['prixDuTicket'],
          'place': row['place'],
          'etatScanne': row['etatScanne'],
          'statut': row['statut'],
          'dateDeCreation': row['dateDeCreation'],
          'datePourCalcule': row['datePourCalcule'],
          'scanneDate': row['scanneDate'],
        });
      }

      yield tickets; // émettre les tickets à chaque requête
    } catch (error) {
      yield [];
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: recuperationDeMesTickets(),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Problème de connexion',
                    style: TextStyle(
                        color: Config.colors.bleuFonce2,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == null || snapshot.data!.isEmpty) {
                return Center(
                    child: Text(
                  "Vous n'avez aucun ticket",
                  style: TextStyle(
                      color: Config.colors.bleuFonce2,
                      fontWeight: FontWeight.bold),
                ));
              }

              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> ticket = snapshot.data![index];
                  var idTicket = ticket['documentId'];
                  var verifDate = ticket['date'];

                  if (verifDate == dateDAujourdhui ||
                      verifDate == dateDeDemain ||
                      verifDate == dateDapresDemain) {
                    couleurTicket = const Color.fromARGB(210, 48, 196, 222);
                  } else {
                    couleurTicket = const Color.fromARGB(132, 5, 82, 121);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: TicketMaterial(
                      height: 115,
                      colorBackground: couleurTicket!,
                      colorShadow: Colors.white,
                      shadowSize: 2,
                      radiusBorder: 8,
                      leftChild: _buildLeft(
                        context,
                        idTicket,
                        ticket['idUtilisateur'],
                        ticket['nom'],
                        ticket['telephone'],
                        ticket['date'],
                        ticket['heure'],
                        ticket['depart'],
                        ticket['destination'],
                        ticket['place'],
                        ticket['etatScanne'],
                        ticket['prixDuTicket'].toString(),
                        ticket['statut'],
                        ticket['datePourCalcule'],
                      ),
                      rightChild: _buildRight(),
                      tapHandler: () {},
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLeft(
      BuildContext context,
      String idTicket,
      String idUtilisateur,
      String nom,
      String contact,
      String date,
      String heure,
      String depart,
      String destination,
      int numeroDePlace,
      String etatScann,
      String prixTicket,
      String statut,
      DateTime dateCalcule) {
    return GestureDetector(
      onTap: () {
        if (tailleEcran! >= 6) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
                datePourCalcule: dateCalcule,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsTickets2(
                idTicket: idTicket,
                idUtilisateur: idUtilisateur,
                nom: nom,
                contact: contact,
                date: date,
                heure: heure,
                depart: depart,
                destination: destination,
                place: numeroDePlace,
                etatScann: etatScann,
                statut: statut,
                prixTicket: prixTicket,
                datePourCalcule: dateCalcule,
              ),
            ),
          );
        }
      },
      child: Padding(
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
                        ),
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
                        ),
                      ),
                      Text(
                        heure,
                        style: const TextStyle(
                          fontSize: 16,
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
                          decorationColor: Colors.white,
                        ),
                      ),
                      Text(
                        "N° $numeroDePlace",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: Center(
                child: SizedBox(
                  height: 32,
                  child: TextButton(
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          side: const BorderSide(
                              color: Color.fromARGB(255, 248, 244, 208),
                              width: 2.0),
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (tailleEcran! >= 6) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                              datePourCalcule: dateCalcule,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsTickets2(
                              idTicket: idTicket,
                              idUtilisateur: idUtilisateur,
                              nom: nom,
                              contact: contact,
                              date: date,
                              heure: heure,
                              depart: depart,
                              destination: destination,
                              place: numeroDePlace,
                              etatScann: etatScann,
                              statut: statut,
                              prixTicket: prixTicket,
                              datePourCalcule: dateCalcule,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      " Détails du ticket ",
                      style: TextStyle(
                        color: Color.fromARGB(255, 248, 244, 208),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRight() {
    return Center(
        child: Text(
      "MVST",
      style: TextStyle(
        color: Config.colors.bleuFonce,
        fontFamily: 'Lobster',
        shadows: const [
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(1, 1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(-1, -1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(1, -1),
            blurRadius: 1,
          ),
          Shadow(
            color: Color.fromARGB(255, 248, 244, 208),
            offset: Offset(-1, 1),
            blurRadius: 1,
          ),
        ],
      ),
    ));
  }
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}
