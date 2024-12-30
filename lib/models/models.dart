import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/screens/detailsImages.dart';
import 'package:mysql1/mysql1.dart';

class Carousel extends StatefulWidget {
  const Carousel({Key? key}) : super(key: key);

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  bool isLoading = false;
  List<ImageModel> images = [];
  MySqlConnection? conn;
  final String baseUrl = 'https://tenelodata-tech.com/mvst/';

  @override
  void initState() {
    super.initState();
    _connectToDatabase();
    _recupImages();
  }

  Future<void> _connectToDatabase() async {
    conn = await Connexion.connexionDB();
  }

  Future<void> _recupImages() async {
    setState(() {
      isLoading = true;
    });

    try {
      conn ??= await Connexion.connexionDB();
      final results =
          await conn!.query("SELECT * FROM Images WHERE statut = 'Actif'");

      setState(() {
        images = results.map((row) {
          return ImageModel.fromJson({
            'id': row['id'],
            'titre': row['titre'].toString(),
            'description': row['description'].toString(),
            'statut': row['statut'].toString(),
            'lien_image': row['lien_image'].toString(),
          });
        }).toList();
      });
    } catch (e) {
      conn = await Connexion.connexionDB();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : images.isEmpty
            ? Center(
                child: Text(
                  'Aucune image disponible',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )
            : SizedBox(
                width: double.infinity,
                height: 300,
                child: CarouselSlider.builder(
                  itemCount: images.length,
                  itemBuilder:
                      (BuildContext context, int index, int realIndex) {
                    final String url = baseUrl + images[index].lien_image;
                    final String titre = images[index].titre;
                    final String description = images[index].description;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsImages(
                              imageUrl: url,
                              titre: titre,
                              description: description,
                            ),
                          ),
                        );
                      },
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            'Problème de connexion, images non chargées',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                  options: CarouselOptions(
                    autoPlay: true,
                    pauseAutoPlayOnTouch: true,
                    viewportFraction: 1.0,
                    aspectRatio: 16 / 9,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 940),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              );
  }
}

////////////////////////////

Widget carte(String pointDeDepart, String destinationA, String destinationB) {
  return Card(
    color: const Color.fromARGB(145, 143, 208, 231),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    elevation: 2,
    clipBehavior:
        Clip.antiAlias, // Pour éviter le débordement du contenu de la carte
    child: SizedBox(
      height: 110,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PetitesCartes(
              depart: pointDeDepart,
              destination: destinationA,
            ),
            const Expanded(
                child: SizedBox(
              child: Icon(
                Icons.sync_alt_outlined,
                size: 12,
                color: Color.fromARGB(255, 100, 220, 249),
              ),
            )),
            PetitesCartes(
              depart: pointDeDepart,
              destination: destinationB,
            ),
          ],
        ),
      ),
    ),
  );
}

// ignore: must_be_immutable
class PetitesCartes extends StatefulWidget {
  PetitesCartes({super.key, required this.depart, required this.destination});
  String depart;
  String destination;

  @override
  State<PetitesCartes> createState() => _PetitesCartesState();
}

class _PetitesCartesState extends State<PetitesCartes> {
  Map<String, dynamic>? userData;
  int? prix;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> donneesUtilisateur() async {
    Map<String, dynamic>? data = await InformationsUtilisateur();
    await recuperationAffectationPrix();
    setState(() {
      userData = data;
    });
  }

  Future<Map<String, dynamic>?> InformationsUtilisateur() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Vérifier si l'utilisateur est null
    if (user == null) {
      return null; // Arrêter l'exécution si l'utilisateur est null
    }

    try {
      // Récupérer le document de l'utilisateur depuis Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      // Vérifier si le document existe
      if (!documentSnapshot.exists) {
        return null; // Arrêter l'exécution si le document n'existe pas
      }

      // Extraire les informations du document
      Map<String, dynamic> userData =
          documentSnapshot.data() as Map<String, dynamic>;
      int points = userData['points'] ?? 0;

      // Vérifier si les points de l'utilisateur sont égaux à 0
      if (points == 0) {
        // Afficher une alerte et retourner null
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 8), // Espacement entre l'icône et le texte
                  Text(
                    'Alerte',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                'Votre profil est soumis à une restriction, \nveuillez contacter l\'administrateur MVST Mobile.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Ferme l'alerte
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        return null; // Arrêter l'exécution si les points sont à 0
      }

      // Retourner les informations utilisateur
      return {
        'nom': userData['nom'] ?? '',
        'prenoms': userData['prenoms'] ?? '',
        'telephone': userData['telephone'] ?? '',
      };
    } catch (e) {
      return null; // Arrêter l'exécution en cas d'erreur
    }
  }

  Future<List<Map<String, dynamic>>> getPrixDesTickets() async {
    // Établir la connexion
    final conn = await Connexion.connexionDB();

    // Exécuter la requête
    final results = await conn.query('SELECT axe, prix FROM PrixDesTickets');

    // Transformer les résultats en une liste de maps
    final List<Map<String, dynamic>> data = results.map((_prix) {
      return {'axe': _prix['axe'], 'prix': _prix['prix']};
    }).toList();

    // Fermer la connexion
    await conn.close();

    return data;
  }

  Future<void> recuperationAffectationPrix() async {
    List<Map<String, dynamic>> data = await getPrixDesTickets();
    setState(() {
      for (var item in data) {
        prixDesBillets[item['axe']] = item['prix'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          if (FirebaseAuth.instance.currentUser != null) {
            String userId = FirebaseAuth.instance.currentUser!.uid;
            setState(() {
              _isLoading = true;
            });

            // Récupérer les données utilisateur
            Map<String, dynamic>? data = await InformationsUtilisateur();
            if (data == null) {
              return; // Arrêter ici si les données utilisateur ne sont pas valides
            }

            setState(() {
              userData = data;
            });

            // Récupérer et affecter les prix des billets
            await recuperationAffectationPrix();
            String cle = "${widget.depart} ${widget.destination}";

            // Vérifier si le prix est disponible
            if (prixDesBillets.containsKey(cle)) {
              prix = prixDesBillets[cle];

              // Navigation vers la page de commande
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Commande(
                    idUtilisateur: userId,
                    nom: userData!['nom'],
                    prenoms: userData!['prenoms'],
                    telephone: userData!['telephone'],
                    prixDuBillet: prix!,
                    depart: widget.depart,
                    destination: widget.destination,
                  ),
                ),
              );
            } else {
              throw Exception('Prix non trouvé pour $cle');
            }
          } else {
            // L'utilisateur n'est pas connecté, rediriger vers la page de connexion
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Login(),
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur...'),
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color.fromARGB(255, 121, 185, 238)),
        ),
        color: const Color.fromARGB(255, 217, 244, 252),
        child: SizedBox(
          height: 85,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.depart,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 2,
                  ),
                  const Icon(
                    color: Color.fromARGB(255, 108, 108, 108),
                    Icons.airport_shuttle_sharp,
                    size: 12,
                  ),
                  const SizedBox(
                    width: 2,
                  ),
                  Text(
                    widget.destination,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              ),
              if (_isLoading) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget carteALettre(String lettre) {
  return Card(
    color: Config.colors.bleuClaire,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Config.colors.jauneBlanc),
    ),
    child: SizedBox(
      height: 40,
      width: 40,
      child: Center(
        child: Text(
          lettre,
          style: const TextStyle(
            fontFamily: 'Lobster',
            fontSize: 16,
            color: Color.fromARGB(255, 96, 177, 244),
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

Widget porte() {
  return Row(children: [
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(
          color: const Color.fromARGB(255, 89, 87, 87),
          width: 1,
        ),
      ),
      height: 23,
      width: 8,
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(
          color: const Color.fromARGB(255, 89, 87, 87),
          width: 1,
        ),
      ),
      height: 24,
      width: 10,
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        border: Border.all(
          color: const Color.fromARGB(255, 89, 87, 87),
          width: 1,
        ),
      ),
      height: 25,
      width: 12,
    ),
  ]);
}

Map<String, int> prixDesBillets = {};

class ImageModel {
  final int id;
  final String titre;
  final String description;
  final String statut;
  final String lien_image;

  ImageModel({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.lien_image,
  });

  // Méthode pour créer une instance d'ImageModel à partir de JSON
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['id'],
      titre: json['titre'],
      description: json['description'],
      statut: json['statut'],
      lien_image: json['lien_image'],
    );
  }
}


/*


  Future<Map<String, dynamic>?> _InformationsUtilisateur() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Récupérer le document de l'utilisateur à partir de Firestore
        DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .get();
        if (documentSnapshot.exists) {
          // Extraire les informations du document
          Map<String, dynamic> userData =
              documentSnapshot.data() as Map<String, dynamic>;
          String nom = userData['nom'] ?? '';
          String prenoms = userData['prenoms'] ?? '';
          String telephone = userData['telephone'] ?? '';
          int points = userData['points'] ?? 0;
          if (points > 0) {
            // Retourner les informations récupérées
            return {
              'nom': nom,
              'prenoms': prenoms,
              'telephone': telephone,
            };
          } else {
            // Si l'utilisateur n'a pas de points
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Center(
                      child: Text(
                    'Alerte',
                    style: TextStyle(
                        color: Colors.yellow, fontWeight: FontWeight.bold),
                  )),
                  content: Text(
                      'Votre profil est soumis à une restriction, \nveuillez contacter l\'administrateur MVST Mobile.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Ferme l'alerte
                      },
                      child: Text(
                        'OK',
                        style: TextStyle(
                            color: Colors.yellow, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          return null; // Document non trouvé
        }
      } catch (e) {
        return null; // Erreur lors de la récupération des informations
      }
    } else {
      return null; // Utilisateur non connecté
    }
  }


*/