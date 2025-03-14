// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// reuperer la liste des places dejà occupée dans la liste listeDesPlacesOccupees
List<int> listeDesPlacesOccupees = [];
List<int> listeDeVerification = [];
String? idDocPourNetoyage;

class ClasseListeDesPlaces {
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

Future<void> suppressionPlacesTemporaires() async {
  const String apiUrl =
      'https://tenelodata-tech.com/mvst/process_places_temporaires.php';
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
