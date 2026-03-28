import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/detailsTickets.dart';

class TableauDeTickets extends StatefulWidget {
  const TableauDeTickets({Key? key, required this.idUtilisateur})
    : super(key: key);
  final String idUtilisateur;

  @override
  State<TableauDeTickets> createState() => _TableauDeTicketsState();
}

class _TableauDeTicketsState extends State<TableauDeTickets> {
  int _rowsPerPage = 20;
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

  @override
  void dispose() {
    _rechercheParDate.dispose();
    _rechercheParDestination.dispose();
    super.dispose();
  }

  Future<void> recuperationDeMesTickets() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(
          'https://mvst.tenelo.cloud/recuperation_mes_tickets_tableau.php',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"idUtilisateur": widget.idUtilisateur}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final liste = List<Map<String, dynamic>>.from(data['tickets']);
          if (mounted)
            setState(() {
              donnees = liste;
              _filtre = liste;
            });
        }
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filtrer() {
    final date = _rechercheParDate.text.toLowerCase();
    final dest = _rechercheParDestination.text.toLowerCase();
    setState(() {
      donnees = _filtre
          .where(
            (t) =>
                t['date'].toString().toLowerCase().contains(date) &&
                t['destination'].toString().toLowerCase().contains(dest),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildSearchField(
                    controller: _rechercheParDate,
                    hint: 'Recherche par date',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),

                Expanded(
                  child: _buildSearchField(
                    controller: _rechercheParDestination,
                    hint: 'Par destination',
                    icon: Icons.location_on_outlined,
                  ),
                ),
              ],
            ),

            // ── Tableau ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: c.homeButtonPrimary,
                      ),
                    )
                  : donnees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            color: c.homeButtonPrimary.withOpacity(0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun ticket',
                            style: TextStyle(
                              color: c.homeTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            cardColor: c.homeCardBackground,
                            dividerColor: c.homeBordurePetiteCarte,
                            dataTableTheme: DataTableThemeData(
                              headingTextStyle: TextStyle(
                                color: c.homeButtonPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              dataTextStyle: TextStyle(
                                color: c.homeTextPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          child: PaginatedDataTable(
                            header: Text(
                              textAlign: TextAlign.center,
                              'Nombre total de tickets : ${donnees.length}',
                              style: TextStyle(
                                color: c.homeButtonPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),

                            horizontalMargin: 10,
                            columnSpacing: 16,
                            showFirstLastButtons: true,
                            columns: [
                              DataColumn(
                                label: Text(
                                  'Date',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Heure',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Départ',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Destination',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Place',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Tarif',
                                  style: TextStyle(
                                    color: c.homeButtonPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            rowsPerPage: _rowsPerPage,
                            availableRowsPerPage: const [5, 10, 20],
                            onRowsPerPageChanged: (int? value) {
                              if (value != null) {
                                setState(() => _rowsPerPage = value);
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 4.0,
        bottom: 8.0,
        right: 4.0,
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => _filtrer(),
        style: TextStyle(
          //color: Config.colors.homeTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Config.colors.homeTextPrimary.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Config.colors.homeButtonPrimary,
            size: 16,
          ),
          filled: true,
          //fillColor: Config.colors.homeGrandeCarte,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: 2,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
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
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').parse(dateStr);
  }

  @override
  DataRow? getRow(int index) {
    if (index >= tickets.length) return null;
    final ticket = tickets[index];
    final String id = ticket['documentId'];
    final String typeVoyage = ticket['typeVoyage']?.toString() ?? 'standard';
    final bool isVip = typeVoyage == 'vip';

    DateTime date = parseDate(ticket['date'].toString());
    String formattedDate = DateFormat('dd MMM yyyy', 'fr_FR').format(date);

    final TextStyle style = TextStyle(
      fontSize: 13,
      color: isVip ? const Color(0xFFB8860B) : null,
      fontWeight: isVip ? FontWeight.bold : FontWeight.normal,
    );

    return DataRow.byIndex(
      index: index,
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (isVip) return const Color(0xFFFFFDE7);
        return index.isEven ? Colors.white : const Color(0xFFF8FBFF);
      }),
      cells: [
        DataCell(
          Text(formattedDate, style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
        DataCell(
          Text('${ticket['heure']} h', style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
        DataCell(
          Text(ticket['depart'], style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
        DataCell(
          Text(ticket['destination'], style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
        DataCell(
          Text(ticket['place'].toString(), style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
        DataCell(
          Text('${ticket['prixDuTicket']} f', style: style),
          onTap: () => _onTapRow(ticket, id, typeVoyage),
        ),
      ],
    );
  }

  void _onTapRow(Map<String, dynamic> ticket, String id, String typeVoyage) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsTickets(
          idTicket: id,
          idUtilisateur: ticket['idUtilisateur'].toString(),
          nom: ticket['nom'].toString(),
          contact: ticket['telephone'].toString(),
          date: ConvertirHeure.formatDate(ticket['date'].toString()),
          heure: ticket['heure'].toString(),
          depart: ticket['depart'].toString(),
          destination: ticket['destination'].toString(),
          place: ticket['place'],
          etatScann: ticket['etatScanne'].toString(),
          statut: ticket['statut'].toString(),
          prixTicket: ticket['prixDuTicket'].toString(),
          typeVoyage: typeVoyage,
          datePourCalcule: ticket['datePourCalcule'] != null
              ? DateTime.parse(ticket['datePourCalcule'])
              : DateTime.now(),
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
