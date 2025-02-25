// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// reuperer la liste des places dejà occupée dans la liste listeDesPlacesOccupees
List<int> listeDesPlacesOccupees = [];
List<int> listeDeVerification = [];
String? idDocPourNetoyage;

class ClasseListeDesPlaces {
// récupérer la liste des places dejà occupées

/*
  static Future<void> _verifierEtRecupererPlaces(
      String _depart,
      String _destination,
      String _date,
      String _heure,
      String _mois,
      String _moisAnnee,
      String _annee) async {
    final conn = await Connexion.connexionDB();
    final String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";
    final String idDesDepartsParLigne = "${_depart}_${_date}_${_heure}";

    try {
      // pour tous les lieux de départ sauf Bouaké
      if (_depart != 'Bouaké') {
        var countResult = await conn.query(
            'SELECT COUNT(*) FROM Departs WHERE documentId = ?', [documentId]);

        if (countResult.first[0] == 0) {
          await conn.query(
              'INSERT INTO Departs (documentId, dateDeDepart, heureDeDepart, depart, destination, mois, moisAnnee, annee, placesChoisies, idDesDepartsParLigne, dateDeCreation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())',
              [
                documentId,
                _date,
                _heure,
                _depart,
                _destination,
                _mois,
                _moisAnnee,
                _annee,
                '[]',
                idDesDepartsParLigne
              ]);
        } else {
          var placesResult = await conn.query(
              'SELECT placesChoisies FROM Departs WHERE idDesDepartsParLigne = ?',
              [idDesDepartsParLigne]);

          if (placesResult.isNotEmpty) {
            List<int> allPlacesChoisies = [];

            // Extraire et concaténer les places choisies en entiers
            for (var row in placesResult) {
              String placesJsonString = row['placesChoisies'].toString();
              if (placesJsonString.isNotEmpty) {
                List<dynamic> placesDynamic = jsonDecode(placesJsonString);
                List<int> placesList =
                    placesDynamic.map((place) => place as int).toList();
                allPlacesChoisies.addAll(placesList);
              }
            }

            // Supprimer les doublons si nécessaire
            allPlacesChoisies = allPlacesChoisies.toSet().toList();

            // Réinitialiser la liste listeDesPlacesOccupees avant chaque ajout
            listeDesPlacesOccupees = allPlacesChoisies;
          }
        }
      } else {
        // Pour les gares de Bouaké
        var countResult = await conn.query(
            'SELECT COUNT(*) FROM Departs WHERE documentId = ?', [documentId]);
        if (countResult.first[0] == 0) {
          await conn.query(
              'INSERT INTO Departs (documentId, dateDeDepart, heureDeDepart, depart, destination, mois, moisAnnee, annee, placesChoisies, idDesDepartsParLigne, dateDeCreation) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())',
              [
                documentId,
                _date,
                _heure,
                _depart,
                _destination,
                _mois,
                _moisAnnee,
                _annee,
                '[]',
                idDesDepartsParLigne
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
      }
    } catch (error) {
    } finally {
      await conn.close();
    }
  }

*/
  // Récupérer la liste des places déjà occupées via un appel API PHP
  static Future<void> verifierEtRecupererPlaces(
      String _depart,
      String _destination,
      String _date,
      String _heure,
      String _mois,
      String _moisAnnee,
      String _annee) async {
    final String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";
    final String idDesDepartsParLigne = "${_depart}_${_date}_${_heure}";

    final url = Uri.parse(
        'https://tenelodata-tech.com/mvst/verifierEtRecupererPlaces.php');

    try {
      // Effectuer l'appel HTTP pour récupérer les places occupées
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Si les places occupées sont récupérées
          if (data.containsKey('placesOccupees')) {
            List<int> allPlacesChoisies =
                List<int>.from(data['placesOccupees']);

            // Réinitialiser la liste des places occupées avant chaque ajout
            listeDesPlacesOccupees = allPlacesChoisies.toSet().toList();
          }
        } else {
          // En cas d'échec de l'API, afficher un message d'erreur
        }
      } else {
        // Si l'appel HTTP échoue
      }
    } catch (error) {
      // Gestion des erreurs réseau
    }
  }
}

//vérifier si une place est occupée ou non, si non occupée ajouter
//à la liste des places occupées si oui retourné 'échèc'

/*
Future<String> verifierEtAjouterPlace(
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
  final String documentId = "${_depart}-${_destination}_${_date}_${_heure}_h";
  final String idDesDepartsParLigne = "${_depart}_${_date}_${_heure}";
  try {
    // Commencer une transaction
    await conn.query('START TRANSACTION');

    // pour tous les lieux de départ sauf Bouaké
    if (_depart != 'Bouaké') {
      // Récupérer les places choisies
      var placesResult = await conn.query(
          'SELECT placesChoisies FROM Departs WHERE idDesDepartsParLigne = ? FOR UPDATE',
          [
            idDesDepartsParLigne
          ]); // Utilisation de FOR UPDATE pour verrouiller la ligne

      if (placesResult.isNotEmpty) {
        List<int> allPlacesChoisies = [];

        // Extraire et concaténer les places choisies en entiers
        for (var row in placesResult) {
          String placesJsonString = row['placesChoisies'].toString();
          if (placesJsonString.isNotEmpty) {
            List<dynamic> placesDynamic = jsonDecode(placesJsonString);
            List<int> placesList =
                placesDynamic.map((place) => place as int).toList();
            allPlacesChoisies.addAll(placesList);
          }
        }
        // Supprimer les doublons si nécessaire
        allPlacesChoisies = allPlacesChoisies.toSet().toList();

        // Réinitialiser la liste listeDesPlacesOccupees avant chaque ajout
        listeDesPlacesOccupees = allPlacesChoisies;

        // Vérifier si la place existe déjà dans la liste
        bool placeExists = listeDesPlacesOccupees.contains(numeroDePlace);

        if (placeExists) {
          await conn.query('ROLLBACK'); // Annuler la transaction
          return 'échec'; // La place est déjà réservée
        } else {
          // Ajouter la place choisie
          idDocPourNetoyage = documentId;
          await conn.query(
              'UPDATE Departs SET placesChoisies = JSON_ARRAY_APPEND(placesChoisies, ?, ?) WHERE documentId = ?',
              ['\$', numeroDePlace, documentId]);

          // Ajouter l'enregistrement dans PlacesTemporaires
          await conn.query(
            'INSERT INTO PlacesTemporaires (documentId, places, dateDeCreation) VALUES (?, ?, NOW())',
            [documentId, numeroDePlace],
          );

          // Valider la transaction
          await conn.query('COMMIT');
          return 'succès';
        }
      } else {
        // Si aucune ligne n'est trouvée, rollback et signaler une erreur
        await conn.query('ROLLBACK');
        return 'Erreur : Document non trouvé';
      }
    } else {
      // Pour les gares de Bouaké

      // Récupérer les places choisies
      var placesResult = await conn.query(
          'SELECT placesChoisies FROM Departs WHERE documentId = ? FOR UPDATE',
          [documentId]); // Utilisation de FOR UPDATE pour verrouiller la ligne

      if (placesResult.isNotEmpty) {
        var placesBlob = placesResult.first[0];
        var placesJsonString = placesBlob.toString();
        if (placesJsonString.isNotEmpty) {
          List<dynamic> placesDynamic = jsonDecode(placesJsonString);
          Set<int> placesSet =
              placesDynamic.map((place) => place as int).toSet();
          listeDesPlacesOccupees = placesSet.toList();

          // Vérifier si la place existe déjà dans la liste
          bool placeExists = listeDesPlacesOccupees.contains(numeroDePlace);

          if (placeExists) {
            await conn.query('ROLLBACK'); // Annuler la transaction
            return 'échec'; // La place est déjà réservée
          } else {
            // Ajouter la place choisie
            idDocPourNetoyage = documentId;
            await conn.query(
                'UPDATE Departs SET placesChoisies = JSON_ARRAY_APPEND(placesChoisies, ?, ?) WHERE documentId = ?',
                ['\$', numeroDePlace, documentId]);

            // Ajouter l'enregistrement dans PlacesTemporaires
            await conn.query(
              'INSERT INTO PlacesTemporaires (documentId, places, dateDeCreation) VALUES (?, ?, NOW())',
              [documentId, numeroDePlace],
            );

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
    }
  } catch (error) {
    await conn.query('ROLLBACK'); // Annuler la transaction en cas d'erreur
    return 'Erreur inattendue';
  } finally {
    await conn.close(); // Toujours fermer la connexion
  }
  return 'Erreur inattendue';
}


*/
Future<String> verifierEtAjouterPlace(
    String _depart,
    String _destination,
    String _date,
    String _id,
    String _mois,
    String _moisAnnee,
    String _annee,
    String _heure,
    int numeroDePlace) async {
  final url = Uri.parse(
      'https://tenelodata-tech.com/mvst/verifier_et_ajouter_place.php');
  final response = await http.post(
    url,
    body: {
      'depart': _depart,
      'destination': _destination,
      'date': _date,
      'id': _id,
      'mois': _mois,
      'moisAnnee': _moisAnnee,
      'annee': _annee,
      'heure': _heure,
      'numeroDePlace': numeroDePlace.toString(),
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['message'];
  } else {
    throw Exception('Erreur de connexion au serveur');
  }
}

// supprimer une place desélectionnée

/*
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
*/
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
  const String apiUrl = "https://tenelodata-tech.com/mvst/supprimer_places.php";

  try {
    // Préparer le corps de la requête
    final Map<String, dynamic> body = {
      "depart": _depart,
      "destination": _destination,
      "date": _date,
      "heure": _heure,
      "numerosDePlace": numerosDePlace,
    };

    // Envoyer la requête POST
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    // Vérifier le statut de la réponse
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['message']; // Message de succès
      } else {
        return data['message']; // Message d'erreur
      }
    } else {
      return "Erreur serveur : ${response.statusCode}";
    }
  } catch (e) {
    return "Erreur : $e";
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

/*Cette fonction permet de supprimer au lencement da l'application,les places choisies
pour lequels l'utilisateur n'est allé au terme du procecus
cela crée des places occupée dans la table 'Departs' pourtant n'appartenant à aucun
utilisateur.  
*/

Future<void> processPlacesTemporaires() async {
  const String apiUrl =
      'https://tenelodata-tech.com/mvst/process_places_temporaires.php'; // Remplacez par l'URL de votre script PHP

  try {
    // Envoyer une requête GET au script PHP
    final response = await http.get(Uri.parse(apiUrl));

    // Vérifier le statut de la réponse
    if (response.statusCode == 200) {
      // Décoder la réponse JSON
      final data = json.decode(response.body);

      // Afficher un message selon la réponse
      if (data["success"]) {
      } else {}
    } else {
      // Gestion des erreurs HTTP
    }
  } catch (e) {
    // Gérer les exceptions
  }
}





/*
Future<void> processPlacesTemporaires() async {
  final conn = await Connexion.connexionDB();

  try {
    final checkOperation = await conn.query(
      'SELECT operation_en_cours FROM EtatOperations WHERE nom_operation = ?',
      ['processPlacesTemporaires'],
    );

    if (checkOperation.isNotEmpty &&
        checkOperation.first['operation_en_cours'] == 1) {
      return;
    }

    await conn.query(
      'UPDATE EtatOperations SET operation_en_cours = 1 WHERE nom_operation = ?',
      ['processPlacesTemporaires'],
    );

    final results = await conn.query(
      'SELECT id, documentId, places FROM PlacesTemporaires',
    );

    if (results.isNotEmpty) {
      for (var row in results) {
        final int id = row['id'] as int;
        final String idDocument = row['documentId'] is Blob
            ? String.fromCharCodes((row['documentId'] as Blob).toBytes())
            : row['documentId'] as String;
        final int place = row['places'] as int;

        final matchingTickets = await conn.query(
          'SELECT * FROM Tickets WHERE documentId = ? AND place = ?',
          [idDocument, place],
        );

        if (matchingTickets.isNotEmpty) {
          await conn.query('DELETE FROM PlacesTemporaires WHERE id = ?', [id]);
        } else {
          final matchingDeparts = await conn.query(
            'SELECT placesChoisies FROM Departs WHERE documentId = ?',
            [idDocument],
          );

          if (matchingDeparts.isNotEmpty) {
            String placesChoisies = matchingDeparts.first['placesChoisies']
                    is Blob
                ? String.fromCharCodes(
                    (matchingDeparts.first['placesChoisies'] as Blob).toBytes())
                : matchingDeparts.first['placesChoisies'] as String;

            final List<String> placesList = placesChoisies.split(',');
            placesList.remove(place.toString());

            final updatedPlaces = placesList.join(',');
            await conn.query(
              'UPDATE Departs SET placesChoisies = ? WHERE documentId = ?',
              [updatedPlaces, idDocument],
            );

            await conn
                .query('DELETE FROM PlacesTemporaires WHERE id = ?', [id]);
          }
        }
      }
    }
  } catch (e) {
  } finally {
    await conn.query(
      'UPDATE EtatOperations SET operation_en_cours = 0 WHERE nom_operation = ?',
      ['processPlacesTemporaires'],
    );
  }
}
*/
