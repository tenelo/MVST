import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/screens/detailsTickets.dart';

class TableauDeTickets extends StatefulWidget {
  const TableauDeTickets({Key? key, required this.idUtilisateur})
      : super(key: key);
  final String idUtilisateur;
  @override
  State<TableauDeTickets> createState() => _TableauDeTicketsState();
}

class _TableauDeTicketsState extends State<TableauDeTickets> {
  int _rowsPerPage = 8;
  bool _isLoading = true;
  List<DocumentSnapshot> donnees = [];
  List<DocumentSnapshot> _filtre = [];
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _getDonnees();
  }

  void _getDonnees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les documents de la collection 'tickets' avec filtrage et tri
      QuerySnapshot<Map<String, dynamic>> ticketsSnapshot =
          await FirebaseFirestore.instance
              .collection('tickets')
              .where('idUtilisateur', arrayContains: widget.idUtilisateur)
              .orderBy('createdAt', descending: true)
              .get();

      // Récupérer les sous-collections pour chaque document
      List<DocumentSnapshot<Map<String, dynamic>>> allDocuments = [];
      for (var ticketDoc in ticketsSnapshot.docs) {
        var subcollectionSnapshot = await ticketDoc.reference
            .collection('sousCollectionTickets')
            .where('idUtilisateur', isEqualTo: widget.idUtilisateur)
            .orderBy('dateDeCreation', descending: true)
            .get();
        allDocuments.addAll(subcollectionSnapshot.docs);
      }

      setState(() {
        donnees = allDocuments;
        _filtre = allDocuments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Erreur lors de la récupération des tickets : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        donnees = _filtre
                            .where((data) => data['date']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase()))
                            .toList();
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
                            horizontalMargin: 5,
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
                            availableRowsPerPage: const [5, 8, 10],
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
  final List<DocumentSnapshot> tickets;
  final BuildContext context;

  TicketDataSource(this.tickets, this.context);

  DateTime parseDate(String dateStr) {
    DateFormat format = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    return format.parse(dateStr);
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticketSnapshot = tickets[index];
    final ticket = tickets[index].data() as Map<String, dynamic>;
    final String idDuTicket = ticketSnapshot.id;
    DateTime date = parseDate(ticket['date']);
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsTickets(
          idTicket: id,
          idUtilisateur: ticket['idUtilisateur'],
          nom: ticket['nom'],
          contact: ticket['telephone'],
          date: ticket['date'],
          heure: ticket['heure'],
          depart: ticket['depart'],
          destination: ticket['destination'],
          place: ticket['place'],
          etatScann: ticket['etatScanne'],
          statut: ticket['statut'],
          prixTicket: ticket['prixDuTicket'].toString(),
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => tickets.length;

  @override
  int get selectedRowCount => 0;
}
