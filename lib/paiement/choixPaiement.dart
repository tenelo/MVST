import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';

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

  @override
  State<ChoixPaiement> createState() => _ChoixPaiementState();
}

class _ChoixPaiementState extends State<ChoixPaiement> {
  bool _isLoading = false;
  bool _isNavigating = false;
  @override
  void dispose() {
    if (!_isNavigating) {
      _netoyageEnCasDeFermeture();
    }
    super.dispose();
  }

  Future<void> _ajouterTicketsMySQL() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final conn = await Connexion.connexionDB();
    String documentId =
        "${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h";

    try {
      // Démarrer une transaction
      await conn.query('BEGIN');

      // Vérifier l'existence du document et l'insérer si nécessaire
      var result = await conn.query(
          'SELECT COUNT(*) FROM Departs WHERE documentId = ?', [documentId]);

      if (result.first[0] == 0) {
        await conn.query(
            '''INSERT INTO Departs (documentId, dateDeDepart, heureDeDepart, depart, destination, mois, moisAnnee, annee, placesChoisies, dateDeCreation) 
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())''',
            [
              documentId,
              widget.idDate,
              widget.heure,
              widget.depart,
              widget.destination,
              widget.mois,
              widget.moisAnnee,
              widget.annee,
              '[]',
            ]);
      }

      // Créer la table 'Tickets' si elle n'existe pas (à déplacer hors de la boucle si possible)
      await conn.query('''
      CREATE TABLE IF NOT EXISTS Tickets (
        id INT AUTO_INCREMENT PRIMARY KEY,
        idUtilisateur VARCHAR(255),
        nom VARCHAR(255),
        telephone VARCHAR(255),
        date VARCHAR(100),
        heure VARCHAR(255),
        depart VARCHAR(255),
        destination VARCHAR(255),
        prixDuTicket INT,
        place INT,
        etatScanne VARCHAR(255),
        statut VARCHAR(255),
        scanneDate VARCHAR(50),
        datePourCalcule DATE,
        dateDeCreation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (documentId) REFERENCES Departs(documentId)
      )
    ''');

// Insérer les tickets dans la table 'Tickets' en une seule transaction
      for (var _place in widget.place) {
        await conn.query(
            '''INSERT INTO Tickets (documentId, idUtilisateur, nom, telephone, date, heure, depart, destination, prixDuTicket, place, etatScanne, statut, datePourCalcule, scanneDate, dateDeCreation) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'nonScanné', 'valide', ?, '', NOW())''',
            [
              documentId,
              widget.id,
              widget.nom,
              widget.contact,
              widget.date,
              widget.heure,
              widget.depart,
              widget.destination,
              widget.prixUnitaire,
              _place,
              widget.datePourCalcule,
            ]);
      }
      // Finaliser la transaction
      await conn.query('COMMIT');

      // Nettoyer et afficher un message en cas de succès
      listeDeVerification.clear();
      messageEnCasDeSucces(context);
    } catch (e) {
      // Annuler la transaction en cas d'erreur
      await conn.query('ROLLBACK');
      messageEnCasDecheque(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
      await conn.close();
    }
  }

  void messageEnCasDeSucces(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: Duration(seconds: 2), // Durée du SnackBar
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
        duration: Duration(seconds: 2), // Durée du SnackBar
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

    return WillPopScope(
      onWillPop: () async {
        if (!_isNavigating) {
          // Si l'utilisateur revient en arrière, lancer la fonction de nettoyage
          await _netoyageEnCasDeFermeture();
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              color: const Color.fromARGB(199, 252, 246, 229),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 35,
                  top: 22,
                  right: 35,
                  bottom: 22,
                ),
                child: Card(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Image carte de paiement
                      Padding(
                        padding: const EdgeInsets.only(top: 14.0),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * .22,
                          width: double.infinity,
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Container(
                              height: double.infinity,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/credAA.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      //Boite des informations
                      SizedBox(
                        width: double.infinity,
                        height: 68,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1.0),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "2% un ticket de 8.000 coûtera 8.160",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "2.5% un ticket de 8.000 coûtera 8.200",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Choix des paiements
                      SizedBox(
                        height: MediaQuery.of(context).size.height * .4,
                        width: double.infinity,
                        child: Card(
                          color: Colors.white70,
                          child: Column(
                            children: [
                              //WAVE
                              GestureDetector(
                                child: Card(
                                  shadowColor: Colors.lightBlueAccent,
                                  elevation: 4,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Card(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            'assets/images/wave.png',
                                            width: 70,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "frais 2%",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  var prixAvecPorcentage = widget.prixUnitaire +
                                      (widget.prixUnitaire * (2 / 100)).toInt();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Paiement par WAVE'),
                                        content: Text(
                                            'Vous avez commandé ${widget.nombreDeTicket} ticket(s)\nmontant total à payer : ${prixAvecPorcentage * widget.nombreDeTicket} fcfa'),
                                        actions: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _ajouterTicketsMySQL();
                                                  initialiseBloc
                                                      .add(EventInitialise());
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Valider'),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              // MTN
                              GestureDetector(
                                child: Card(
                                  shadowColor: Colors.yellowAccent,
                                  elevation: 4,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Card(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            'assets/images/mtn.png',
                                            width: 70,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "frais 2.5%",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  var prixAvecPorcentage = widget.prixUnitaire +
                                      (widget.prixUnitaire * (2.5 / 100))
                                          .toInt();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Paiement par MTN'),
                                        content: Text(
                                            'Vous avez commandé ${widget.nombreDeTicket} ticket(s)\nmontant total à payer : ${prixAvecPorcentage * widget.nombreDeTicket} fcfa'),
                                        actions: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _ajouterTicketsMySQL();
                                                  initialiseBloc
                                                      .add(EventInitialise());
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Valider'),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              // ORANGE
                              GestureDetector(
                                child: Card(
                                  shadowColor: Colors.deepOrangeAccent,
                                  elevation: 4,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Card(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            'assets/images/orange.png',
                                            width: 70,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "frais 2.5%",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  var prixAvecPorcentage = widget.prixUnitaire +
                                      (widget.prixUnitaire * (2.5 / 100))
                                          .toInt();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title:
                                            const Text('Paiement par Orange'),
                                        content: Text(
                                            'Vous avez commandé ${widget.nombreDeTicket} ticket(s)\nmontant total à payer : ${prixAvecPorcentage * widget.nombreDeTicket} fcfa'),
                                        actions: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _ajouterTicketsMySQL();
                                                  initialiseBloc
                                                      .add(EventInitialise());
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Valider'),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              // MOOV
                              GestureDetector(
                                child: Card(
                                  shadowColor:
                                      const Color.fromARGB(255, 12, 92, 196),
                                  elevation: 4,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Card(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.asset(
                                            'assets/images/moov.png',
                                            width: 70,
                                            height: 60,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          "frais 2.5%",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  var prixAvecPorcentage = widget.prixUnitaire +
                                      (widget.prixUnitaire * (2.5 / 100))
                                          .toInt();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Paiement par MooV'),
                                        content: Text(
                                            'Vous avez commandé ${widget.nombreDeTicket} ticket(s)\nmontant total à payer : ${prixAvecPorcentage * widget.nombreDeTicket} fcfa'),
                                        actions: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  await _ajouterTicketsMySQL();
                                                  initialiseBloc
                                                      .add(EventInitialise());
                                                  Navigator.popUntil(context,
                                                      (route) => route.isFirst);
                                                },
                                                child: const Text('Valider'),
                                              ),
                                            ],
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
