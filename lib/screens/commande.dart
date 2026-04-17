// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/choixPlace.dart';
import 'package:mvst/screens/home.dart';
import 'package:mvst/screens/choixPlaceVip.dart';

String? dateFormatee, idMois, idMoisAnnee, idAnnee;

class Commande extends StatefulWidget {
  const Commande({
    super.key,
    required this.idUtilisateur,
    required this.nom,
    required this.prenoms,
    required this.telephone,
    required this.prixDuBillet,
    required this.depart,
    required this.destination,
    this.typeVoyage = 'standard',
    this.ongletOrigine = 0,
  });

  final String? idUtilisateur;
  final String? nom;
  final String? prenoms;
  final String? telephone;
  final String depart;
  final String destination;
  final int prixDuBillet;
  final String typeVoyage;
  final int ongletOrigine;

  @override
  _CommandeState createState() => _CommandeState();
}

class _CommandeState extends State<Commande> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? dateChoisie;
  late DateTime dateDemain;
  late DateTime dateApresDemain;
  String? heureDeDepart;
  List<String> listeHeures = [];
  bool _isLoading = false;
  final formKey = GlobalKey<FormState>();

  bool get _isVip => widget.typeVoyage == 'vip';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afficherConfirmation();
    });
    _initialiserForm();
    _recupHeuresDeDeparts();
  }

  void _initialiserForm() {
    final now = DateTime.now();
    dateDemain = DateTime.utc(now.year, now.month, now.day + 1);
    dateApresDemain = DateTime.utc(now.year, now.month, now.day + 2);
    nomController.text = "${widget.nom!} ${widget.prenoms!}";
    contactController.text = widget.telephone!;
    listeDeVerification.clear();
    listeDesPlacesOccupees.clear();
  }

  // ── Dialog de confirmation ─────────────────────────────────────────────────
  void _afficherConfirmation() {
    final c = Config.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: c.homeCardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: c.homeBordurePetiteCarte.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.homeAccent.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: c.homeAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirmez votre trajet',
                  style: TextStyle(
                    color: c.homeTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.my_location, 'Départ', widget.depart, c),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.location_on,
                  'Destination',
                  widget.destination,
                  c,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.confirmation_number,
                  'Tarif',
                  '${widget.prixDuBillet} FCFA',
                  c,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          Future.delayed(const Duration(milliseconds: 200), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    Home(ongletInitial: widget.ongletOrigine),
                              ),
                            );
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: c.homeBackground,
                          side: BorderSide(color: c.homeBordurePetiteCarte),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Annuler',
                          style: TextStyle(
                            color: c.homeBordurePetiteCarte,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.homeAccent,
                          foregroundColor: c.homeBackground,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Confirmer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, dynamic c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.homeBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.homeAccent, size: 18),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: c.homeTextPrimary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: c.homeTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _selectionDate(BuildContext context) async {
    final c = Config.colors;
    try {
      DateTime? choixDeDate = await showDatePicker(
        context: context,
        firstDate: dateDemain,
        lastDate: dateApresDemain,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: _isVip
                  ? const ColorScheme.dark(
                      primary: Color(0xFFFFD700),
                      onPrimary: Color(0xFF1A1A2E),
                      surface: Color(0xFF16213E),
                      onSurface: Color(0xFFFFD700),
                    )
                  : ColorScheme.light(
                      primary: c.homeButtonPrimary,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: _isVip
                      ? const Color(0xFFFFD700)
                      : c.homeButtonPrimary,
                ),
              ),
              dialogTheme: DialogThemeData(
                backgroundColor: _isVip
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(0.80)),
              child: child!,
            ),
          );
        },
      );
      if (choixDeDate != null) {
        setState(() {
          _dateController.text = DateFormat(
            'EEEE d MMMM y',
            'fr_FR',
          ).format(choixDeDate);
          dateFormatee = DateFormat(
            'EEEE_d_MMMM_y',
            'fr_FR',
          ).format(choixDeDate);
          idMois = DateFormat('MMMM', 'fr_FR').format(choixDeDate);
          idMoisAnnee = DateFormat('MMMM_y', 'fr_FR').format(choixDeDate);
          idAnnee = DateFormat('y', 'fr_FR').format(choixDeDate);
        });
      }
    } catch (error) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final counterBloc = BlocProvider.of<BlocCompteur>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final Color accentColor = _isVip ? const Color(0xFFFFD700) : Colors.white;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        onPopInvokedWithResult: (didPop, result) =>
            FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: c.homeBackground,

          // ── AppBar ──────────────────────────────────────────────────────
          appBar: AppBar(
            backgroundColor: c.authButtonDisabled,
            iconTheme: IconThemeData(color: c.homeAccent),
            centerTitle: true,
            title: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.depart,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: screenWidth * 0.040,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.airport_shuttle_sharp,
                      color: c.homeAccent,
                      size: 14,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      widget.destination,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: screenWidth * 0.040,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.prixDuBillet} f',
                      style: TextStyle(
                        color: c.homeAccent,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Résumé trajet ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _isVip
                          ? const Color(0xFF12122A)
                          : c.homeGrandeCarte,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isVip
                            ? const Color(0xFFFFD700)
                            : c.homeBordurePetiteCarte,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              widget.depart,
                              style: TextStyle(
                                color: _isVip
                                    ? const Color(0xFFFFD700)
                                    : c.homeButtonPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                            Text(
                              'Départ',
                              style: TextStyle(
                                color: _isVip
                                    ? Colors.white54
                                    : c.homeTextPrimary.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: _isVip
                              ? const Color(0xFFFFD700)
                              : c.homeButtonPrimary,
                          size: 18,
                        ),
                        Column(
                          children: [
                            Text(
                              widget.destination,
                              style: TextStyle(
                                color: _isVip
                                    ? const Color(0xFFFFD700)
                                    : c.homeButtonPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                            Text(
                              'Destination',
                              style: TextStyle(
                                color: _isVip
                                    ? Colors.white54
                                    : c.homeTextPrimary.withValues(alpha: 0.5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Label section ─────────────────────────────────────────
                  Text(
                    'Informations du passager',
                    style: TextStyle(
                      color: _isVip
                          ? const Color(0xFFB8860B)
                          : c.homeButtonPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.040,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildChamp(
                    controller: nomController,
                    label: 'Nom et Prénoms',
                    icone: Icons.person_outline,
                    c: c,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre nom';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildChamp(
                    controller: contactController,
                    label: 'Contact',
                    icone: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    c: c,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre contact';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildChampDate(c),

                  const SizedBox(height: 10),

                  _buildDropdownHeure(c),

                  const SizedBox(height: 20),

                  // ── Bouton choisir place ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.055,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                counterBloc.add(EventInitialise());
                                listeDesPlacesChoisies.clear();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => _isVip
                                        ? ChoixPlacesVip(
                                            idDate: dateFormatee!,
                                            id: widget.idUtilisateur!,
                                            depart: widget.depart,
                                            destination: widget.destination,
                                            nom: nomController.text,
                                            contact: contactController.text,
                                            date: _dateController.text,
                                            heure: heureDeDepart!,
                                            prixDuBillet: widget.prixDuBillet,
                                            mois: idMois!,
                                            moisAnnee: idMoisAnnee!,
                                            annee: idAnnee!,
                                          )
                                        : ChoixPlaces(
                                            idDate: dateFormatee!,
                                            id: widget.idUtilisateur!,
                                            depart: widget.depart,
                                            destination: widget.destination,
                                            nom: nomController.text,
                                            contact: contactController.text,
                                            date: _dateController.text,
                                            heure: heureDeDepart!,
                                            prixDuBillet: widget.prixDuBillet,
                                            mois: idMois!,
                                            moisAnnee: idMoisAnnee!,
                                            annee: idAnnee!,
                                          ),
                                  ),
                                ).then(
                                  (_) => setState(() => _isLoading = false),
                                );
                              }
                            },
                      icon: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: c.homeAccent,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.event_seat_outlined,
                              color: c.homeAccent,
                              size: 18,
                            ),
                      label: Text(
                        _isLoading ? 'Chargement...' : 'Choisir une place',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isVip
                            ? _isLoading
                                  ? const Color(0xFFB8860B)
                                  : const Color(0xFFFFD700)
                            : _isLoading
                            ? c.authButtonDisabled.withValues(alpha: 0.5)
                            : c.authButtonDisabled,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    required dynamic c,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
      style: TextStyle(color: c.homeTextPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: c.homeTextPrimary.withValues(alpha: 0.8),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icone,
          color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
          size: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        filled: true,
        fillColor: _isVip ? const Color(0xFF1A1A2E) : c.homeGrandeCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: c.homeBordurePetiteCarte.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : c.homeBordurePetiteCarte.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
            width: 1.5,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildChampDate(dynamic c) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      cursorColor: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
      style: TextStyle(color: c.homeTextPrimary, fontSize: 15),
      onTap: () => _selectionDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Veuillez choisir une date';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Date de départ',
        labelStyle: TextStyle(
          color: c.homeTextPrimary.withValues(alpha: 0.8),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.calendar_month_outlined,
          color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
          size: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        filled: true,
        fillColor: _isVip ? const Color(0xFF1A1A2E) : c.homeGrandeCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: c.homeBordurePetiteCarte.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : c.homeBordurePetiteCarte.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownHeure(dynamic c) {
    return DropdownButtonFormField<String>(
      initialValue: heureDeDepart,
      dropdownColor: _isVip ? const Color(0xFF1A1A2E) : c.homeCardBackground,
      iconEnabledColor: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
      style: TextStyle(color: c.homeTextPrimary, fontSize: 15),
      onChanged: (value) => setState(() => heureDeDepart = value),
      validator: (value) {
        if (value == null) return 'Veuillez choisir une heure de départ';
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Heure de départ',
        labelStyle: TextStyle(
          color: c.homeTextPrimary.withValues(alpha: 0.8),
          fontSize: 13,
        ),
        prefixIcon: Icon(
          Icons.access_time_outlined,
          color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
          size: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        filled: true,
        fillColor: _isVip ? const Color(0xFF1A1A2E) : c.homeGrandeCarte,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: c.homeBordurePetiteCarte.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip
                ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                : c.homeBordurePetiteCarte.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: _isVip ? const Color(0xFFFFD700) : c.homeButtonPrimary,
            width: 1.5,
          ),
        ),
      ),
      items: listeHeures.map((String h) {
        return DropdownMenuItem<String>(
          value: h,
          child: Text(
            h,
            style: TextStyle(
              color: _isVip ? const Color(0xFFFFD700) : c.homeTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _recupHeuresDeDeparts() async {
    try {
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/recuperationHeure.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'type': widget.typeVoyage}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<String> heures = List<String>.from(
            data['heures'].map((heure) => heure['heure']),
          );
          setState(() => listeHeures = heures);
        }
      }
    } catch (e) {
      afficherErreur(context, e);
    }
  }
}
