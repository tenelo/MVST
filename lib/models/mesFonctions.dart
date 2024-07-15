import 'package:cloud_firestore/cloud_firestore.dart';

List<int> listeDesNumeros = [];

class FonctionListeDesPlaces {
  static Future<void> recup(String date, String heure) async {
    // Récupérer les documents principaux filtrés par date et heure
    final ticketsSnapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('dateDeDepart', isEqualTo: date)
        .where('heureDeDepart', isEqualTo: heure)
        .get();
    // listeDesNumeros.clear();
    // Parcourir chaque document trouvé
    for (var ticketDoc in ticketsSnapshot.docs) {
      // Récupérer la sous-collection 'sousCollectionTickets' pour chaque document
      var sousCollectionSnapshot =
          await ticketDoc.reference.collection('sousCollectionTickets').get();

      sousCollectionSnapshot.docs.forEach((doc) {
        listeDesNumeros.add(doc['place'] as int);
      });
    }
  }
}

class ClasseListeDesPlaces {
  static Future<void> getTicketsStream(
      String _depart, String _destination, String _date, String _heure) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Construire l'ID du document à partir des paramètres de date et heure
    String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";

    // Récupérer le document par son ID
    DocumentSnapshot<Map<String, dynamic>> ticketsSnapshot =
        await _firestore.collection('tickets').doc(documentId).get();

    // Vider la liste avant de la remplir
    listeDesNumeros.clear();

    // Vérifier si le document existe
    if (ticketsSnapshot.exists) {
      var subcollectionSnapshot = await ticketsSnapshot.reference
          .collection('sousCollectionTickets')
          .get();

      // Extraire les 'place' de la sous-collection
      for (var subDoc in subcollectionSnapshot.docs) {
        final data = subDoc.data();
        if (data['place'] != null) {
          listeDesNumeros.add(data['place'] as int);
        }
      }
    } else {
      print("Document with ID $documentId does not exist");
    }
  }
}

// fonction stream pour écouter la collection 'tickets' et lancer la fonction de récupration des places
void listenForTicketChanges(String _dateDeTri, String _heureTri) {
  final collectionRef = FirebaseFirestore.instance.collection('tickets');

  // Écoute tous les changements dans la collection 'tickets'
  final subscription = collectionRef.snapshots().listen((snapshot) {
    snapshot.docChanges.forEach((change) {
      ClasseListeDesPlaces.getTicketsStream;
    });
  });

  // Pour arrêter l'écoute lorsque nécessaire
  // subscription.cancel();
}

/*
class ListeDesPlaces {
  static List<int> listeNummeros = [];
}
*/

/*
  static Future<void> getTicketsStream(String _date, String _heure) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    QuerySnapshot<Map<String, dynamic>> ticketsSnapshot = await _firestore
        .collection('tickets')
        .where('dateDeDepart', isEqualTo: _date)
        .where('heureDeDepart', isEqualTo: _heure)
        .get();

    listeDesNumeros.clear();
    for (var ticketDoc in ticketsSnapshot.docs) {
      var subcollectionSnapshot =
          await ticketDoc.reference.collection('sousCollectionTickets').get();

      // Extraire les 'place' de la sous-collection
      for (var subDoc in subcollectionSnapshot.docs) {
        final data = subDoc.data();
        if (data['place'] != null) {
          await Future.delayed(Duration(milliseconds: 1));
          listeDesNumeros.add(data['place'] as int);
        }
      }
    }
  }*/