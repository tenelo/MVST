// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ChoixPaiement extends StatefulWidget {
  const ChoixPaiement({
    super.key,
    required this.idDate,
    required this.nombreDeTicket,
    required this.prixUnitaire,
    required this.id,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.datePourCalcule,
    required this.mois,
    required this.moisAnnee,
    required this.annee,
    required this.heure,
    required this.destination,
    required this.depart,
    this.typeVoyage = 'standard',
  });
  final String idDate;
  final int nombreDeTicket;
  final int prixUnitaire;
  final String id;
  final List<int> place;
  final String nom;
  final String contact;
  final String date;
  final DateTime datePourCalcule;
  final String heure;
  final String destination;
  final String depart;
  final String mois;
  final String moisAnnee;
  final String annee;
  final String typeVoyage;

  @override
  State<ChoixPaiement> createState() => _ChoixPaiementState();
}

class _ChoixPaiementState extends State<ChoixPaiement> {
  bool _isLoading = false;
  bool _isNavigating = false;

  // ── Socket.IO ─────
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    _connecterSocket();
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    if (!_isNavigating) {
      _netoyageEnCasDeFermeture();
    }
    super.dispose();
  }

  void _connecterSocket() {
    socket = io.io(
      kBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket.connect();
  }

  Future<void> _ajouterTickets() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Construire le payload pour l'envoi des données
      final payload = {
        "documentId":
            "${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h",
        "idUtilisateur": widget.id,
        "nom": widget.nom,
        "telephone": widget.contact,
        "date": widget.date,
        "heure": widget.heure,
        "depart": widget.depart,
        "destination": widget.destination,
        "prixDuTicket": widget.prixUnitaire,
        "places": widget.place,
        "statut": "valide",
        "etatScanne": "nonScanné",
        "datePourCalcule": widget.datePourCalcule.toIso8601String(),
        "typeVoyage": widget.typeVoyage,
      };

      // Envoyer la requête POST
      final response = await ApiClient.instance.post(
        'ajouterTickets.php',
        body: payload,
        timeout: const Duration(seconds: 10),
      );
      // Vérifier la réponse du serveur
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Nettoyer et afficher un message en cas de succès
          listeDeVerification.clear();
          messageEnCasDeSucces(context);
        } else {
          // Gérer les cas où l'insertion échoue côté serveur
          messageEnCasDecheque(context);
        }
      } else {
        // Gérer les erreurs réseau
        messageEnCasDecheque(context);
      }
    } catch (e) {
      // Gérer les exceptions
      messageEnCasDecheque(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void messageEnCasDeSucces(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 5), // Durée du SnackBar
        backgroundColor: Config.colors.bleuFonce2,
        content: Text(
          'Le paiement a été effectué avec succès',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void messageEnCasDecheque(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 5), // Durée du SnackBar
        backgroundColor: Color.fromARGB(255, 249, 54, 6),
        content: const Text(
          'Le paiement n\'a pas pu être effectué',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BlocCompteur initialiseBloc = BlocProvider.of<BlocCompteur>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && !_isNavigating) await _netoyageEnCasDeFermeture();
      },
      child: Scaffold(
        body: SafeArea(
          child: petitEcran
              ? SingleChildScrollView(
                  child: Container(
                    color: Config.colors.homeBandeauBorder,
                    constraints: BoxConstraints(minHeight: screenHeight),
                    width: screenWidth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.050,
                      ),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.001),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Image carte de paiement ──────────────────────
                              SizedBox(
                                height: screenHeight * 0.24,
                                width: double.infinity,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/credAA.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.030),
                              // ── Boîte des informations ───────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "2% — un ticket de 8.000 coûtera 8.160",
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                              255,
                                              119,
                                              118,
                                              118,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.030,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.004),
                                        Text(
                                          "2.5% — un ticket de 8.000 coûtera 8.200",
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                              255,
                                              119,
                                              118,
                                              118,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.030,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.045),

                              // ── Choix des paiements ──────────────────────────
                              Card(
                                color: Colors.white70,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/wave.png',
                                      label: 'frais 2%',
                                      titre: 'Paiement par WAVE',
                                      pourcentage: 2 / 100,
                                      shadowColor: Colors.lightBlueAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/mtn.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par MTN',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: Colors.yellowAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/orange.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par Orange',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: Colors.deepOrangeAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/moov.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par MooV',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: const Color.fromARGB(
                                        255,
                                        12,
                                        92,
                                        196,
                                      ),
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                  ],
                                ),
                              ),

                              if (_isLoading) ...[
                                SizedBox(height: screenHeight * 0.000),
                                Center(
                                  child: CircularProgressIndicator(
                                    color: Config.colors.couleurDfond,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Container(
                    color: const Color.fromARGB(197, 177, 241, 249),
                    constraints: BoxConstraints(minHeight: screenHeight),
                    width: screenWidth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.06,
                        vertical: screenHeight * 0.050,
                      ),
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.001),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Image carte de paiement ──────────────────────
                              SizedBox(
                                height: screenHeight * 0.24,
                                width: double.infinity,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/credAA.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.030),
                              // ── Boîte des informations ───────────────────────
                              SizedBox(
                                width: double.infinity,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.03,
                                      vertical: screenHeight * 0.015,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "2% — un ticket de 8.000 coûtera 8.160",
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                              255,
                                              119,
                                              118,
                                              118,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.030,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.004),
                                        Text(
                                          "2.5% — un ticket de 8.000 coûtera 8.200",
                                          style: TextStyle(
                                            color: const Color.fromARGB(
                                              255,
                                              119,
                                              118,
                                              118,
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.030,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.045),

                              // ── Choix des paiements ──────────────────────────
                              Card(
                                color: Colors.white70,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/wave.png',
                                      label: 'frais 2%',
                                      titre: 'Paiement par WAVE',
                                      pourcentage: 2 / 100,
                                      shadowColor: Colors.lightBlueAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/mtn.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par MTN',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: Colors.yellowAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/orange.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par Orange',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: Colors.deepOrangeAccent,
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                    _buildOperateur(
                                      context,
                                      initialiseBloc,
                                      image: 'assets/images/moov.png',
                                      label: 'frais 2.5%',
                                      titre: 'Paiement par MooV',
                                      pourcentage: 2.5 / 100,
                                      shadowColor: const Color.fromARGB(
                                        255,
                                        12,
                                        92,
                                        196,
                                      ),
                                      screenWidth: screenWidth,
                                      screenHeight: screenHeight,
                                    ),
                                  ],
                                ),
                              ),

                              if (_isLoading) ...[
                                SizedBox(height: screenHeight * 0.010),
                                Center(
                                  child: CircularProgressIndicator(
                                    color: Config.colors.couleurDfond,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Widget opérateur réutilisable ──────────────────────────────────────────
  Widget _buildOperateur(
    BuildContext context,
    BlocCompteur initialiseBloc, {
    required String image,
    required String label,
    required String titre,
    required double pourcentage,
    required Color shadowColor,
    required double screenWidth,
    required double screenHeight,
  }) {
    return GestureDetector(
      onTap: () async {
        final int prixAvecPorcentage =
            widget.prixUnitaire + (widget.prixUnitaire * pourcentage).toInt();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(titre),
              content: Text(
                'Vous avez commandé ${widget.nombreDeTicket} ticket(s)\n'
                'montant total à payer : ${prixAvecPorcentage * widget.nombreDeTicket} fcfa',
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (route) => route.isFirst),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _ajouterTickets();
                        initialiseBloc.add(EventInitialise());
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: const Text('Valider'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
      child: Card(
        shadowColor: shadowColor,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  image,
                  width: screenWidth * 0.17,
                  height: screenHeight * 0.08,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.02),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.034,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _netoyageEnCasDeFermeture() async {
    if (listeDeVerification.isNotEmpty) {
      // ── Libérer les places via Socket.IO ──────────────────────────────
      final documentId =
          '${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h';
      socket.emit('liberer_places', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': widget.idDate,
        'heure': widget.heure,
        'numerosDePlace': listeDeVerification,
      });
    }
    listeDeVerification.clear();
    return true;
  }
}
