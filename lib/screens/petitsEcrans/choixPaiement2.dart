import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/petitsEcrans/home2.dart';

class ChoixPaiement2 extends StatefulWidget {
  const ChoixPaiement2({
    super.key,
    required this.idDate,
    required this.nombreDeTicket,
    required this.prixUnitaire,
    required this.id,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
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
  final String heure;
  final String destination;
  final String depart;

  @override
  State<ChoixPaiement2> createState() => _ChoixPaiement2State();
}

class _ChoixPaiement2State extends State<ChoixPaiement2> {
  bool _isLoading = false;

  Future<void> _ajouterTicketsFirestore() async {
    // Désactiver le bouton ou la fonctionnalité pendant l'exécution
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    // Référence du document 'date' dans la collection 'tickets'
    DocumentReference dateDocRef = firestore.collection('tickets').doc(
        "${widget.depart}-${widget.destination}_${widget.idDate}_${widget.heure}_h");

    // Vérifier si le document parent existe
    DocumentSnapshot dateDocSnapshot = await dateDocRef.get();

    // Cast les données du document en Map<String, dynamic>
    // ignore: unused_local_variable
    Map<String, dynamic>? dateData =
        dateDocSnapshot.data() as Map<String, dynamic>?;

    if (!dateDocSnapshot.exists) {
      // Si aucun document avec pour id widget.idDate n'existe dans la collection 'tickets'
      // Créer un nouveau document avec ces trois champs ('createdAt', 'dateDeDepart', 'heureDeDepart')
      await dateDocRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'dateDeDepart': widget.idDate,
        'heureDeDepart': widget.heure,
        'placesDejaChoisies': [],
      });
    } else {}

    // Référence de la sous-collection 'sousCollectionTickets' du document 'date'
    CollectionReference sousCollectionTickets =
        dateDocRef.collection('sousCollectionTickets');

    WriteBatch batch = firestore.batch();

    // Éliminer les doublons dans la liste 'place'
    List<int> placesSansDoublons = widget.place.toSet().toList();

    for (int place in placesSansDoublons) {
      await dateDocRef.update({
        'placesDejaChoisies': FieldValue.arrayUnion([place]),
      });
      DocumentReference docRef = sousCollectionTickets.doc();
      batch.set(docRef, {
        'idUtilisateur': widget.id,
        'nom': widget.nom,
        'telephone': widget.contact,
        'date': widget.date,
        'heure': widget.heure,
        'depart': widget.depart,
        'destination': widget.destination,
        'prixDuTicket': widget.prixUnitaire,
        'place': place,
        'etatScanne': 'non',
        'statut': 'valide',
        'achat': '',
        'dateDeCreation': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();
      messageEnCasDeSucces(context);
    } catch (error) {
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
    return Scaffold(
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
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
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
                    SizedBox(
                      width: double.infinity,
                      height: 70,
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .5,
                      width: double.infinity,
                      child: Card(
                        color: Colors.white70,
                        child: Column(
                          children: [
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
                                                await _ajouterTicketsFirestore();
                                                Navigator.of(context).pop();
                                                initialiseBloc
                                                    .add(EventInitialise());
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Home2(),
                                                  ),
                                                );
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
                                    (widget.prixUnitaire * (2.5 / 100)).toInt();
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
                                                await _ajouterTicketsFirestore();
                                                Navigator.of(context).pop();
                                                initialiseBloc
                                                    .add(EventInitialise());
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Home2(),
                                                  ),
                                                );
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
                                    (widget.prixUnitaire * (2.5 / 100)).toInt();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Paiement par Orange'),
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
                                                await _ajouterTicketsFirestore();
                                                Navigator.of(context).pop();
                                                initialiseBloc
                                                    .add(EventInitialise());
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Home2(),
                                                  ),
                                                );
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
                                    (widget.prixUnitaire * (2.5 / 100)).toInt();
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
                                                await _ajouterTicketsFirestore();
                                                Navigator.of(context).pop();
                                                initialiseBloc
                                                    .add(EventInitialise());
                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Home2(),
                                                  ),
                                                );
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
    );
  }
}
