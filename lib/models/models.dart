import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/screens/detailsImages.dart';

class Carousel extends StatefulWidget {
  const Carousel({Key? key}) : super(key: key);

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  List<Map<String, String>> imgList = [];

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('images')
          .orderBy('dateCreation', descending: false)
          .get();
      final List<Map<String, String>> urls = snapshot.docs
          .map((doc) => {
                'url': doc['url'] as String,
                'titre': doc['titre'] as String,
                'description': doc['description'] as String,
              })
          .toList();
      setState(() {
        imgList = urls;
      });
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: imgList.isEmpty
          ? Center(child: CircularProgressIndicator())
          : CarouselSlider.builder(
              itemCount: imgList.length,
              itemBuilder: (BuildContext context, int index, int realIndex) {
                final String url = imgList[index]['url']!;
                final String titre = imgList[index]['titre']!;
                final String description = imgList[index]['description']!;
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
                  ),
                );
              },
              options: CarouselOptions(
                autoPlay: true,
                pauseAutoPlayOnTouch: true,
                viewportFraction: 1.0,
                aspectRatio: 16 / 9,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 940),
                autoPlayCurve: Curves.fastOutSlowIn,
                scrollDirection: Axis.horizontal,
              ),
            ),
    );
  }
}

/*
class Carousel extends StatefulWidget {
  const Carousel({super.key});

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  final List<String> imgList = [
    'assets/images/MVST_pt_Sf.png',
    'assets/images/dame1.png',
    'assets/images/dame2.png',
    'assets/images/MVST_pt_Sf.png',
    'assets/images/dame3.png',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: CarouselSlider.builder(
        itemCount: imgList.length,
        itemBuilder: (BuildContext context, int index, int realIndex) {
          final String assetName = imgList[index];
          return Image.asset(
            assetName,
            fit: BoxFit.cover,
            width: double.infinity,
          );
        },
        options: CarouselOptions(
          autoPlay: true,
          pauseAutoPlayOnTouch: true,
          viewportFraction: 1.0,
          //enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 940),
          autoPlayCurve: Curves.fastOutSlowIn,
          scrollDirection: Axis.horizontal,
        ),
      ),
    );
  }
}
*/

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

          // Retourner les informations récupérées
          return {
            'nom': nom,
            'prenoms': prenoms,
            'telephone': telephone,
          };
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

  Future<List<Map<String, dynamic>>> getPrixDesTickets() async {
    final QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('prixDesTickets').get();

    final List<Map<String, dynamic>> data = querySnapshot.docs.map((doc) {
      final axe = doc.get('axe');
      final prix = doc.get('prix');
      return {'axe': axe, 'prix': prix};
    }).toList();

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
            //listenForTicketChanges();
            // Récupérer les données utilisateur
            Map<String, dynamic>? data = await InformationsUtilisateur();
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
          print('Erreur lors de la récupération des données : $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: Impossible de récupérer les données.'),
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
