import 'package:flutter/material.dart';
import 'package:flutter_ticket/flutter_ticket.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';

class InformationPrix extends StatelessWidget {
  Future<List<InfosTarifs>> recupererPrixDesTickets() async {
    final conn = await Connexion.connexionDB();

    try {
      // Exécution de la requête pour récupérer les données
      var resultat = await conn.query('SELECT axe, prix FROM PrixDesTickets');

      // Transformation des résultats en une liste d'objets InfosTarifs
      Map<String, InfosTarifs> axesUniques = {};

      for (var row in resultat) {
        // Découper le champ 'axe' en départ et destination
        List<String> axeSplit = (row['axe'] as String).split(' ');
        if (axeSplit.length < 2) continue; // Passer les axes invalides

        // Trier le départ et la destination pour normaliser l'axe
        String depart = axeSplit[0];
        String destination = axeSplit[1];
        List<String> tridAxe = [depart, destination]..sort();
        String axeTrie = tridAxe.join('-');

        // Ajouter l'axe unique avec son prix
        if (!axesUniques.containsKey(axeTrie)) {
          axesUniques[axeTrie] =
              InfosTarifs(depart, destination, row['prix'] as int);
        }
      }

      return axesUniques.values
          .toList(); // Retourner une liste des axes uniques
    } catch (e) {
      return [];
    } finally {
      await conn.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 166, 223, 248),
      body: FutureBuilder<List<InfosTarifs>>(
        future: recupererPrixDesTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              color: Config.colors.bleuFonce2,
            ));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Vérifiez la connexion',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Config.colors.bleuFonce2),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Aucun tarif trouvé.',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Config.colors.bleuFonce2),
              ),
            );
          } else {
            // Afficher les données récupérées
            final tarifs = snapshot.data!;
            return ListView.builder(
              itemCount: tarifs.length,
              itemBuilder: (context, index) {
                final tarif = tarifs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 2.0, vertical: 8.0),
                  child: Ticket(
                    innerRadius: BorderRadius.only(
                        topLeft: Radius.circular(10.0),
                        topRight: Radius.circular(10.0)),
                    outerRadius: BorderRadius.all(Radius.circular(10.0)),
                    child: Container(
                      color: Colors.amber[50],
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'MVST',
                                  style: TextStyle(
                                    letterSpacing: 8,
                                    fontSize: 18.0,
                                    fontFamily: 'Lobster',
                                    color: const Color.fromARGB(
                                        255, 160, 196, 226),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 0.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0, vertical: 14),
                                child: Text(
                                  tarif.depart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.sync_alt_outlined,
                                color: const Color.fromARGB(255, 160, 196, 226),
                                size: 16,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0, vertical: 14),
                                child: Text(
                                  tarif.destination,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0, vertical: 14),
                                child: Text(
                                  tarif.destination,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.sync_alt_outlined,
                                color: const Color.fromARGB(255, 160, 196, 226),
                                size: 16,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0, vertical: 14),
                                child: Text(
                                  tarif.depart,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 0.0),
                          // CONTAINER PRIX
                          Container(
                            width: double.infinity,
                            color: Colors.amber[50],
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Text(
                                '${tarif.prix} f',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
