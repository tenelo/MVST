// ignore_for_file: unused_local_variable
import 'package:cloud_firestore/cloud_firestore.dart';

List<int> listeVerifPourSuppression1 = [];
List<int> listeVerifPourSuppression2 = [];
List<int> listeDesNumeros = [];
List<int> listeDeVerification = [];

class FonctionListeDesPlaces {
  static Future<void> recup(String date, String heure) async {
    // Récupérer les documents principaux filtrés par date et heure
    final ticketsSnapshot = await FirebaseFirestore.instance
        .collection('tickets')
        .where('dateDeDepart', isEqualTo: date)
        .where('heureDeDepart', isEqualTo: heure)
        .get();
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
      // Extraire les 'placesChoisies' du document
      final data = ticketsSnapshot.data();
      if (data != null && data['placesChoisies'] != null) {
        List<dynamic> placesChoisies = data['placesChoisies'];
        for (var place in placesChoisies) {
          // Assurer que chaque élément de la liste est du type attendu
          if (place is Map<String, dynamic> && place['place'] != null) {
            listeDesNumeros.add(place['place'] as int);
          }
        }
      }
    } else {
      print("Document with ID $documentId does not exist");
    }
  }

  ////////////////////////////////////
  static Future<void> _getTicketsStream(
      String _depart, String _destination, String _date, String _heure) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Construire l'ID du document à partir des paramètres de date et heure
    String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";

    // Récupérer le document par son ID
    DocumentSnapshot<Map<String, dynamic>> ticketsSnapshot =
        await _firestore.collection('tickets').doc(documentId).get();

    //remplir liste 1
    if (ticketsSnapshot.exists) {
      // Extraire les 'placesChoisies' du document
      final data = ticketsSnapshot.data();
      if (data != null && data['placesChoisies'] != null) {
        List<dynamic> placesChoisies = data['placesChoisies'];
        for (var place in placesChoisies) {
          // Assurer que chaque élément de la liste est du type attendu
          if (place is Map<String, dynamic> && place['place'] != null) {
            listeVerifPourSuppression1.add(place['place'] as int);
          }
        }
      }
    } else {}

    // Vérifier si le document existe pour remplir liste 2
    if (ticketsSnapshot.exists) {
      var subcollectionSnapshot = await ticketsSnapshot.reference
          .collection('sousCollectionTickets')
          .get();

      // Extraire les 'place' de la sous-collection
      for (var subDoc in subcollectionSnapshot.docs) {
        final data = subDoc.data();
        if (data['place'] != null) {
          listeVerifPourSuppression2.add(data['place'] as int);
        }
      }
    } else {}

    //Vérifier si les id de la liste de la sous collection sont present dans la liste de la collection
    for (var elmt in listeVerifPourSuppression1) {
      if (listeVerifPourSuppression2.contains(elmt)) {
      } else {
        listeDeVerification.add(elmt);
      }
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

Future<String> verifierPlace(
    String _id,
    String _depart,
    String _destination,
    String _date,
    String _moisAnnee,
    String _annee,
    String _heure,
    int numeroDePlace) async {
  String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";

  try {
    // Obtenir une référence au document avec l'ID spécifié
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('tickets').doc(documentId);

    // Exécuter une transaction pour vérifier et mettre à jour le document atomiquement
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtenir un instantané du document
      DocumentSnapshot documentSnapshot = await transaction.get(documentRef);

      if (!documentSnapshot.exists) {
        // Si le document n'existe pas, le créer avec les champs initiaux
        await transaction.set(documentRef, {
          'createdAt': FieldValue.serverTimestamp(),
          'dateDeDepart': _date,
          'heureDeDepart': _heure,
          'depart': _depart,
          'destination': _destination,
          'moisAnnee': _moisAnnee,
          'annee': _annee,
          'placesChoisies': [
            {'place': numeroDePlace, 'id': _id}
          ], // Initialiser avec le numeroDePlace
        });
      } else {
        // Le document existe
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        List<dynamic> placesChoisies = data['placesChoisies'] ?? [];

        // Vérifier si numeroDePlace est déjà dans la liste
        bool placeExists =
            placesChoisies.any((place) => place['place'] == numeroDePlace);

        if (placeExists) {
          return 'échec';
        } else {
          // Le numero n'existe pas, ajouter le nouvel élément à la liste
          placesChoisies.add({'id': _id, 'place': numeroDePlace});
          transaction.update(documentRef, {
            'placesChoisies': placesChoisies,
          });
        }
      }
      return 'succès';
    });
  } catch (e) {
    return 'Erreur lors de la vérification';
  }
}

/*
Future<String> supprimerPlaceEnDebut(String _date, int numeroDePlace) async {

  try {
    // Obtenir une référence au document avec l'ID spécifié
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
    .collection('tickets')
    .where('dateDeDepart', isEqualTo: _date)
    .get();

   
      DocumentSnapshot documentSnapshot = await transaction.get(documentRef);

      if (querySnapshot.docs) {
        // Le document existe
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        List<dynamic> placesChoisies = data['placesChoisies'] ?? [];

        // Trouver l'élément à supprimer
        List<dynamic> updatedPlacesChoisies = placesChoisies.where((place) {
          // Conserver les éléments qui ne correspondent pas au numeroDePlace
          return !(place['place'] == numeroDePlace && place['id'] == _id);
        }).toList();

        if (updatedPlacesChoisies.length < placesChoisies.length) {
          // Si la longueur de la liste a changé, cela signifie qu'un élément a été supprimé
          // Mettre à jour le document avec la nouvelle liste
          transaction.update(querySnapshot, {
            'placesChoisies': updatedPlacesChoisies,
          });
          return 'succès';
        } else {
          // Aucun élément à supprimer
          return 'échec';
        }
      } else {
        // Le document n'existe pas
        return 'échec';
      }

  } catch (e) {
    print('Erreur lors de la suppression de la place : $e');
    return 'Erreur lors de la suppression';
  }
}
*/
Future<String> supprimerPlace(String _id, String _depart, String _destination,
    String _date, String _heure, int numeroDePlace) async {
  String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";

  try {
    // Obtenir une référence au document avec l'ID spécifié
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection('tickets').doc(documentId);

    // Exécuter une transaction pour vérifier et mettre à jour le document atomiquement
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Obtenir un instantané du document
      DocumentSnapshot documentSnapshot = await transaction.get(documentRef);

      if (documentSnapshot.exists) {
        // Le document existe
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        List<dynamic> placesChoisies = data['placesChoisies'] ?? [];

        // Trouver l'élément à supprimer
        List<dynamic> updatedPlacesChoisies = placesChoisies.where((place) {
          // Conserver les éléments qui ne correspondent pas au numeroDePlace
          return !(place['place'] == numeroDePlace && place['id'] == _id);
        }).toList();

        if (updatedPlacesChoisies.length < placesChoisies.length) {
          // Si la longueur de la liste a changé, cela signifie qu'un élément a été supprimé
          // Mettre à jour le document avec la nouvelle liste
          transaction.update(documentRef, {
            'placesChoisies': updatedPlacesChoisies,
          });
          return 'succès';
        } else {
          // Aucun élément à supprimer
          return 'échec';
        }
      } else {
        // Le document n'existe pas
        return 'échec';
      }
    });
  } catch (e) {
    print('Erreur lors de la suppression de la place : $e');
    return 'Erreur lors de la suppression';
  }
}

/*

  Future<bool> _netoyageEnCasDeFermeture() async {
    // Cette méthode est appelée quand l'utilisateur essaie de quitter la page.
    for (var place in listeDeVerification) {
      await supprimerPlace(_depart!, _destination!, _date!, _heure!, place);
    }
    return true; // Renvoie true pour permettre à la page de se fermer.
  }

*/

