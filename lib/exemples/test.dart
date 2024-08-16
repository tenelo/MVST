import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AjouterTicketsPage extends StatefulWidget {
  const AjouterTicketsPage({Key? key}) : super(key: key);

  @override
  _AjouterTicketsPageState createState() => _AjouterTicketsPageState();
}

class _AjouterTicketsPageState extends State<AjouterTicketsPage> {
  bool _isLoading = false;

  // Fonction pour ajouter des tickets à Firestore
  Future<void> _ajouterTicketsFirestore() async {
    List<String> listeDepart = ['Ferké', 'Bouaké', 'Abidjan'];
    List<String> listeDestination = [
      'Tafiré',
      'Katiola',
      'Niakara',
      'Yamoussoukro',
      'Toumodi',
      'Bouaké',
      'Ferké',
      'Abidjan',
    ];

    DateTime dateActuelle = DateTime.now();
    DateTime dateDemain = DateTime.utc(
        dateActuelle.year, dateActuelle.month, dateActuelle.day + 4);

    // Simuler des données pour l'exemple
    String depart = 'Bouaké';
    String destination = 'Abidjan';
    String heure = '20:00';

    String id = '3jrm893xn3ZkPzPtjV7xw1NQInS2';
    String nom = 'Ouattara Tenelo Etienne';
    String contact = '0707788481';
    double prixUnitaire = 8000;

    // Construire l'ID du document à partir des paramètres de date et heure
    String idDateFormatted =
        DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(dateDemain);

    String _moisAnnee = DateFormat('MMMM_y', 'fr_FR').format(dateDemain);
    String _annee = DateFormat('y', 'fr_FR').format(dateDemain);

    String documentId = "${depart}-Abidjan_${idDateFormatted}_${heure}_h";

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference dateDocRef =
        firestore.collection('tickets').doc(documentId);

    // Vérifier si le document parent existe
    DocumentSnapshot dateDocSnapshot = await dateDocRef.get();

    if (!dateDocSnapshot.exists) {
      // Si aucun document n'existe, créer un nouveau document
      await dateDocRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'dateDeDepart': idDateFormatted,
        'heureDeDepart': heure,
        'depart': depart,
        'destination': destination,
        'moisAnnee': _moisAnnee,
        'annee': _annee,
        'placesChoisies': [],
      });
    }

    // Référence de la sous-collection 'sousCollectionTickets' du document 'date'
    CollectionReference sousCollectionTickets =
        dateDocRef.collection('sousCollectionTickets');

    WriteBatch batch = firestore.batch();
    List<Map<String, dynamic>> placesChoisies = [];

    for (var i = 1; i <= 1712; i++) {
      placesChoisies.add({'place': i, 'id': id});

      DocumentReference docRef = sousCollectionTickets.doc();
      batch.set(docRef, {
        'idUtilisateur': id,
        'nom': nom,
        'telephone': contact,
        'date': dateDemain,
        'heure': heure,
        'depart': depart,
        'destination': destination,
        'prixDuTicket': prixUnitaire,
        'place': i,
        'etatScanne': 'non',
        'statut': 'valide',
        'heureDeScanne': '',
        'dateDeCreation': FieldValue.serverTimestamp(),
      });
    }

    try {
      await batch.commit();

      // Ajouter les numéros de places dans le document parent
      await dateDocRef.update({
        'placesChoisies': FieldValue.arrayUnion(placesChoisies),
      });
    } catch (error) {
      // Gérer les erreurs ici
      print("Erreur lors de l'ajout des tickets : $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter Tickets'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _ajouterTicketsFirestore();
                  setState(() {
                    _isLoading = false;
                  });
                },
                child: const Text('Ajouter Tickets'),
              ),
      ),
    );
  }
}
