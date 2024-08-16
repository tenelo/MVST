/* import 'package:flutter/material.dart';

  import 'package:cloud_firestore/cloud_firestore.dart';


    for (int i == 1; i < 31; i++) {

    for (int e = 1; e < 101; e++) {
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

    }
  }

 */