import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';
import 'package:mvst/screens/detailsTickets.dart';
import 'package:mvst/screens/petitsEcrans/detailsTickets2.dart';

int? tailleEcran;

class TableauDeTickets extends StatefulWidget {
  const TableauDeTickets({Key? key, required this.idUtilisateur})
      : super(key: key);
  final String idUtilisateur;

  @override
  State<TableauDeTickets> createState() => _TableauDeTicketsState();
}

class _TableauDeTicketsState extends State<TableauDeTickets> {
  int _rowsPerPage = 10;
  bool _isLoading = true;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    recuperationDeMesTickets();
  }

  Future<List<Map<String, dynamic>>> recuperationDeMesTickets() async {
    final conn = await Connexion.connexionDB();
    setState(() {
      _isLoading = true;
    });
    try {
      var resultat = await conn.query(
          'SELECT * FROM Tickets WHERE idUtilisateur = ? ORDER BY dateDeCreation DESC LIMIT 150',
          [widget.idUtilisateur]);

      List<Map<String, dynamic>> listeDesTickets = [];
      for (var row in resultat) {
        listeDesTickets.add({
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
          'datePourCalcule': row['datePourCalcule'],
          'dateDeCreation': row['dateDeCreation'],
        });
      }
      setState(() {
        donnees = listeDesTickets;
        _filtre = listeDesTickets;
        _isLoading = false;
      });
      return listeDesTickets;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erreur lors de la récupération des ticket ");
      return [];
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height * 1,
        padding: const EdgeInsets.all(4.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(143, 228, 227, 227),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 170,
                  height: 40,
                  child: TextField(
                    controller: _rechercheParDate,
                    decoration: const InputDecoration(
                      hintText: 'Recherche par date',
                      hintStyle: TextStyle(fontSize: 11),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        donnees = _filtre.where((data) {
                          final date = data['date'].toString().toLowerCase();
                          final jourMois = DateFormat('dd MMMM yyyy', 'fr_FR')
                              .format(DateTime.parse(data['date']));
                          return date.contains(value.toLowerCase()) ||
                              jourMois.contains(value.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 198,
                  height: 40,
                  child: TextField(
                    controller: _rechercheParDestination,
                    decoration: const InputDecoration(
                      hintText: 'Recherche par destination',
                      hintStyle: TextStyle(fontSize: 11),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12.0)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        donnees = _filtre
                            .where((data) => data['destination']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Theme(
                          data: ThemeData.light().copyWith(
                              cardColor: Theme.of(context).canvasColor),
                          child: PaginatedDataTable(
                            header: Center(
                              child: Text(
                                "NOMBRE TOTAL DE TICKETS : ${donnees.length}",
                                style: TextStyle(
                                    color: Config.colors.bleuFonce2,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ),
                            horizontalMargin: 10,
                            columnSpacing: 20,
                            showFirstLastButtons: true,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Date',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Heure',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Départ',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Destination',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Place',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Tarif',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 15, 123),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rowsPerPage: _rowsPerPage,
                            availableRowsPerPage: const [5, 10, 20],
                            onRowsPerPageChanged: (int? value) {
                              if (value != null) {
                                setState(() {
                                  _rowsPerPage = value;
                                });
                              }
                            },
                            source: TicketDataSource(donnees, context),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketDataSource extends DataTableSource {
  final List<Map<String, dynamic>> tickets;
  final BuildContext context;

  TicketDataSource(this.tickets, this.context);

  DateTime parseDate(String dateStr) {
    DateFormat dateFormatFr = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    DateTime dateTime = dateFormatFr.parse(dateStr);
    return dateTime;
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticketSnapshot = tickets[index];
    final ticket = ticketSnapshot;
    var idDuTicket = ticket['documentId'];
    DateTime date = parseDate(ticket['date'].toString());
    String formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(formattedDate, style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text("${ticket['heure']} h", style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text(ticket['depart'], style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(Text(ticket['destination'], style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(
            Text(ticket['place'].toString(), style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
        DataCell(
            Text(ticket['prixDuTicket'].toString(),
                style: TextStyle(fontSize: 13)),
            onTap: () => _onTapRow(ticket, idDuTicket)),
      ],
    );
  }

  void _onTapRow(Map<String, dynamic> ticket, String id) {
    if (tailleEcran! >= 6) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsTickets(
            idTicket: id,
            idUtilisateur: ticket['idUtilisateur'].toString(),
            nom: ticket['nom'].toString(),
            contact: ticket['telephone'].toString(),
            date: ConvertirHeure.formatDate((ticket['date'].toString())),
            heure: ticket['heure'].toString(),
            depart: ticket['depart'].toString(),
            destination: ticket['destination'].toString(),
            place: ticket['place'],
            etatScann: ticket['etatScanne'].toString(),
            statut: ticket['statut'].toString(),
            prixTicket: ticket['prixDuTicket'].toString(),
            datePourCalcule: ticket['datePourCalcule'],
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsTickets2(
            idTicket: id,
            idUtilisateur: ticket['idUtilisateur'].toString(),
            nom: ticket['nom'].toString(),
            contact: ticket['telephone'].toString(),
            date: ConvertirHeure.formatDate((ticket['date'].toString())),
            heure: ticket['heure'].toString(),
            depart: ticket['depart'].toString(),
            destination: ticket['destination'].toString(),
            place: ticket['place'],
            etatScann: ticket['etatScanne'].toString(),
            statut: ticket['statut'].toString(),
            prixTicket: ticket['prixDuTicket'].toString(),
            datePourCalcule: ticket['datePourCalcule'],
          ),
        ),
      );
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
}
