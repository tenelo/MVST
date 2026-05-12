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
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> donnees = [];
  List<Map<String, dynamic>> _filtre = [];
  int _total = 0;
  bool _toutCharge = false;
  final TextEditingController _rechercheParDate = TextEditingController();
  final TextEditingController _rechercheParDestination =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chargerPremierePage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _rechercheParDate.dispose();
    _rechercheParDestination.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerPremierePage() async {
    if (mounted) setState(() => _isLoading = true);
    await _chargerPage(0);
  }

  Future<void> _chargerPage(int offset) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/recuperation_mes_tickets_tableau.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              "idUtilisateur": widget.idUtilisateur,
              "offset": offset,
              "limit": 150,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final nouveaux = List<Map<String, dynamic>>.from(data['tickets']);
          if (mounted) {
            setState(() {
              if (offset == 0) {
                donnees = nouveaux;
              } else {
                donnees.addAll(nouveaux);
              }
              _total = data['total'] ?? donnees.length;
              _toutCharge = donnees.length >= _total;
              _filtre = donnees;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    if (_isLoadingMore || _toutCharge) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() => _isLoadingMore = true);
      _chargerPage(donnees.length);
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
    final double w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSearchField(
                    controller: _rechercheParDate,
                    hint: 'Recherche par date',
                    icon: Icons.calendar_today_outlined,
                    w: w,
                  ),
                ),
                Expanded(
                  child: _buildSearchField(
                    controller: _rechercheParDestination,
                    hint: 'Par destination',
                    icon: Icons.location_on_outlined,
                    w: w,
                  ),
                ),
              ],
            ),
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
                            color: c.homeButtonPrimary.withValues(alpha: 0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun ticket',
                            style: TextStyle(
                              color: c.homeTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: w * 0.041,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      controller: _scrollController,
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
                                fontSize: w * 0.033,
                              ),
                              dataTextStyle: TextStyle(
                                color: c.homeTextPrimary,
                                fontSize: w * 0.033,
                              ),
                            ),
                          ),
                          child: PaginatedDataTable(
                            header: Text(
                              textAlign: TextAlign.center,
                              'Nombre total de tickets : $_total',
                              style: TextStyle(
                                color: c.homeButtonPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: w * 0.038,
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
                            availableRowsPerPage: const [5, 10, 20, 50, 100],
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
    required double w,
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
        style: TextStyle(fontSize: w * 0.031, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Config.colors.homeTextPrimary.withValues(alpha: 0.4),
            fontSize: w * 0.031,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Config.colors.homeButtonPrimary,
            size: 16,
          ),
          filled: true,
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
