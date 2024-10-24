// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';

List<int> listeDesPlacesOccupees = [];
List<int> listeDeVerification = [];
List<int> listeDeRecherche = [];

class ClasseListeDesPlaces {
// récupérer la liste des places dejà occupées
  static Future<void> verifierEtRecupererPlaces(
      String _depart,
      String _destination,
      String _date,
      String _heure,
      String _mois,
      String _moisAnnee,
      String _annee) async {
    final conn = await Connexion.connexionDB();
    String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";
    try {
      var countResult = await conn.query(
          'SELECT COUNT(*) FROM Departs WHERE documentId = ?', [documentId]);
      if (countResult.first[0] == 0) {
        await conn.query(
            'INSERT INTO Departs (documentId, dateDeDepart, heureDeDepart, depart, destination, mois, moisAnnee, annee, placesChoisies, dateDeCreation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())',
            [
              documentId,
              _date,
              _heure,
              _depart,
              _destination,
              _mois,
              _moisAnnee,
              _annee,
              '[]'
            ]);
      } else {
        var placesResult = await conn.query(
            'SELECT placesChoisies FROM Departs WHERE documentId = ?',
            [documentId]);
        if (placesResult.isNotEmpty) {
          var placesBlob = placesResult.first[0];
          var placesJsonString = placesBlob.toString();
          if (placesJsonString.isNotEmpty) {
            List<dynamic> placesDynamic = jsonDecode(placesJsonString);
            // Utiliser un Set temporaire pour éviter les doublons
            Set<int> placesSet =
                placesDynamic.map((place) => place as int).toSet();

            // Réinitialiser la liste listeDesPlacesOccupees avant chaque ajout
            listeDesPlacesOccupees = placesSet.toList();
          }
        }
      }
    } catch (error) {
    } finally {
      await conn.close();
    }
  }
}

//vérifier si une place est occupée ou non, si non occupée ajouter
//à la liste des places occupées

Future<String> verifierPlace(
    String _depart,
    String _destination,
    String _date,
    String _id,
    String _mois,
    String _moisAnnee,
    String _annee,
    String _heure,
    int numeroDePlace) async {
  final conn = await Connexion.connexionDB();
  String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";
  try {
    // Commencer une transaction
    await conn.query('START TRANSACTION');

    // Récupérer les places choisies
    var placesResult = await conn.query(
        'SELECT placesChoisies FROM Departs WHERE documentId = ? FOR UPDATE',
        [documentId]); // Utilisation de FOR UPDATE pour verrouiller la ligne

    if (placesResult.isNotEmpty) {
      var placesBlob = placesResult.first[0];
      var placesJsonString = placesBlob.toString();
      if (placesJsonString.isNotEmpty) {
        List<dynamic> placesDynamic = jsonDecode(placesJsonString);
        Set<int> placesSet = placesDynamic.map((place) => place as int).toSet();
        listeDesPlacesOccupees = placesSet.toList();

        // Vérifier si la place existe déjà dans la liste
        bool placeExists = listeDesPlacesOccupees.contains(numeroDePlace);

        if (placeExists) {
          await conn.query('ROLLBACK'); // Annuler la transaction
          return 'échec'; // La place est déjà réservée
        } else {
          // Ajouter la place choisie
          await conn.query(
              'UPDATE Departs SET placesChoisies = JSON_ARRAY_APPEND(placesChoisies, ?, ?) WHERE documentId = ?',
              ['\$', numeroDePlace, documentId]);

          // Valider la transaction
          await conn.query('COMMIT');
          return 'succès';
        }
      }
    } else {
      // Si aucune ligne n'est trouvée, rollback et signaler une erreur
      await conn.query('ROLLBACK');
      return 'Erreur : Document non trouvé';
    }
  } catch (error) {
    await conn.query('ROLLBACK'); // Annuler la transaction en cas d'erreur
    print('Erreur : $error');
    return 'Erreur inattendue';
  } finally {
    await conn.close(); // Toujours fermer la connexion
  }
  return '';
}

// supprimer une place desélectionnée
Future<String> supprimerPlaces(
    String _depart,
    String _destination,
    String _date,
    String _id,
    String _mois,
    String _moisAnnee,
    String _annee,
    String _heure,
    List<int> numerosDePlace) async {
  // Connexion à la base de données
  final conn = await Connexion.connexionDB();

  // Création du documentId basé sur les paramètres fournis
  String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";

  try {
    // Récupérer l'enregistrement correspondant à documentId
    var result = await conn.query(
        'SELECT placesChoisies FROM Departs WHERE documentId = ?',
        [documentId]);

    // Si aucun enregistrement n'est trouvé, retourner une erreur
    if (result.isEmpty) {
      return 'Erreur: document introuvable';
    }

    // Récupérer la valeur JSON du champ `placesChoisies`
    var placesBlob = result.first[0];
    var placesJsonString = placesBlob.toString();

    // Si la liste est vide ou n'existe pas, retourner une erreur
    if (placesJsonString.isEmpty) {
      return 'Erreur: aucune place enregistrée';
    }

    // Convertir la chaîne JSON en une liste dynamique de numéros de places
    List<dynamic> placesDynamic = jsonDecode(placesJsonString);

    // Boucle pour supprimer chaque numéro de place de la liste
    for (int numeroDePlace in numerosDePlace) {
      // Vérifier si le numéro de place à supprimer existe dans la liste
      bool placeExists = placesDynamic.contains(numeroDePlace);
      if (placeExists) {
        // Supprimer le numéro de place de la liste
        placesDynamic.remove(numeroDePlace);
      } else {
        return 'Erreur: la place n\'existe pas';
      }
    }

    // Mettre à jour la base de données après suppression
    if (placesDynamic.isEmpty) {
      await conn.query(
          'UPDATE Departs SET placesChoisies = ? WHERE documentId = ?',
          [jsonEncode([]), documentId]);
    } else {
      String placesJsonUpdated = jsonEncode(placesDynamic);
      await conn.query(
          'UPDATE Departs SET placesChoisies = ? WHERE documentId = ?',
          [placesJsonUpdated, documentId]);
    }

    // Retourner succès après suppression
    return 'succès';
  } catch (error) {
    // En cas d'erreur, afficher l'erreur et retourner un message d'erreur
    return 'Erreur lors de la suppression';
  } finally {
    // Fermer la connexion à la base de données
    await conn.close();
  }
}

class ConvertirHeure {
  static String formatDate(String date) {
    DateTime parsedDate;

    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    parsedDate = inputFormat.parse(date);

    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate);
  }

  static String formatDatePourCalcule(String date) {
    DateTime parsedDate;

    DateFormat inputFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    parsedDate = inputFormat.parse(date);

    return DateFormat('yyyy-MM-dd', 'fr_FR').format(parsedDate);
  }
}
