import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/screens/detailsImages.dart';

// ── Carousel ───────────────────────────────────────────────────────────────────
class Carousel extends StatefulWidget {
  const Carousel({Key? key}) : super(key: key);

  @override
  _CarouselState createState() => _CarouselState();
}

class _CarouselState extends State<Carousel> {
  bool isLoading = false;
  bool erreurConnexion = false;
  List<ImageModel> images = [];
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _recupImages();
    _connecterSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = io.io(
        kBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      _socket!.connect();
      _socket!.on('connect', (_) {
        _recupImages();
      });
      _socket!.on('images_modifiees', (_) => _recupImages());
      _socket!.on('disconnect', (_) {
        Future.delayed(const Duration(seconds: 3), _connecterSocket);
      });
    } catch (e) {}
  }

  // void _connecterSocket() {
  //   // ── Nettoyer l'ancienne instance si elle existe ────────────────
  //   _socket?.off('connect');
  //   _socket?.off('disconnect');
  //   _socket?.off('images_modifiees');
  //   _socket?.disconnect();
  //   _socket?.dispose();
  //   _socket = null;

  //   try {
  //     _socket = IO.io(
  //       kBaseUrl,
  //       IO.OptionBuilder()
  //           .setTransports(['websocket'])
  //           .disableAutoConnect()
  //           .enableReconnection() // ← reconnexion automatique native
  //           .setReconnectionAttempts(999) // ← tentatives illimitées
  //           .setReconnectionDelay(3000) // ← attendre 3s entre chaque tentative
  //           .build(),
  //     );
  //     _socket!.connect();
  //     _socket!.on('connect', (_) {
  //       _recupImages(); // ← recharge à chaque reconnexion
  //     });
  //     _socket!.on('images_modifiees', (_) => _recupImages());
  //     // ── Pas besoin de gérer disconnect manuellement ────────────────
  //     // enableReconnection() s'en charge nativement
  //   } catch (e) {}
  // }

  Future<void> _recupImages() async {
    setState(() {
      isLoading = true;
      erreurConnexion = false;
    });
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/getImages.php'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            images = List<ImageModel>.from(
              data['images'].map((image) => ImageModel.fromJson(image)),
            ).where((image) => image.statut.toLowerCase() == 'actif').toList();
          });
        }
      }
    } catch (e) {
      setState(() => erreurConnexion = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double paddingH = MediaQuery.of(context).size.width * 0.03;

    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Center(child: CircularProgressIndicator(color: c.homeAccent)),
      );
    }

    if (erreurConnexion) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Center(
          child: Text(
            'Vérifiez la connexion internet',
            style: TextStyle(
              color: c.homeTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (images.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: paddingH),
        child: Center(
          child: Text(
            'Aucune image disponible',
            style: TextStyle(
              color: c.homeTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      //height: 300,
      margin: EdgeInsets.symmetric(horizontal: paddingH),
      child: CarouselSlider.builder(
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index, int realIndex) {
          final String url = '$kBaseUrl/${images[index].lien_image}';
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
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      'Vérifiez la connexion internet',
                      style: TextStyle(
                        color: c.homeTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
          autoPlayAnimationDuration: const Duration(milliseconds: 940),
          autoPlayCurve: Curves.fastOutSlowIn,
          scrollDirection: Axis.horizontal,
          padEnds: true,
        ),
      ),
    );
  }
}

Widget carte(
  BuildContext context,
  String depart,
  String destA,
  String destB,
  double width,
) {
  final c = Config.colors;
  return Container(
    decoration: BoxDecoration(
      color: c.homeGrandeCarte,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: c.homeBordurePetiteCarte, width: 1),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: PetitesCartes(
            depart: depart,
            destination: destA,
            typeVoyage: 'standard',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.sync_alt_outlined,
            color: c.homeButtonPrimary,
            size: width * 0.04,
          ),
        ),
        Expanded(
          child: PetitesCartes(
            depart: depart,
            destination: destB,
            typeVoyage: 'standard',
          ),
        ),
      ],
    ),
  );
}

Widget carteVip(
  BuildContext context,
  String depart,
  String destA,
  String destB,
  double width,
) {
  return Container(
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 34, 89, 64),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFD700), width: 1),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: PetitesCartes(
            depart: depart,
            destination: destA,
            typeVoyage: 'vip',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.sync_alt_outlined,
            color: const Color(0xFFFFD700),
            size: width * 0.04,
          ),
        ),
        Expanded(
          child: PetitesCartes(
            depart: depart,
            destination: destB,
            typeVoyage: 'vip',
          ),
        ),
      ],
    ),
  );
}

// ── PetitesCartes ──────────────────────────────────────────────────────────────
// ignore: must_be_immutable
class PetitesCartes extends StatefulWidget {
  PetitesCartes({
    super.key,
    required this.depart,
    required this.destination,
    this.typeVoyage = 'standard',
  });
  String depart;
  String destination;
  String typeVoyage;

  @override
  State<PetitesCartes> createState() => _PetitesCartesState();
}

class _PetitesCartesState extends State<PetitesCartes> {
  Map<String, dynamic>? userData;
  int? prix;
  bool _isLoading = false;

  Future<Map<String, dynamic>?> InformationsUtilisateur() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/verifierUtilisateur.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idUtilisateur': user.uid}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == false) return null;

        final int points = data['points'] ?? 0;

        if (points == 0) {
          if (context.mounted) {
            final c = Config.colors;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: c.homeCardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Accès restreint',
                        style: TextStyle(
                          color: c.homeTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Votre profil est soumis à une restriction.\nVeuillez contacter l\'administrateur MVST Mobile.',
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
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
          }
          return null;
        }

        return {'nom': data['nom'] ?? '', 'telephone': data['telephone'] ?? ''};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur verifierUtilisateur: $e');
      return null;
    }
  }

  // ── Récupération prix selon le type de voyage ─────────────────────────────
  Future<void> recuperationAffectationPrix() async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/getPrixDesTickets.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'type': widget.typeVoyage}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            prixDesBillets.clear();
            for (var item in List<Map<String, dynamic>>.from(data['heures'])) {
              prixDesBillets[item['axe']] = item['prix'];
            }
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double carteWidth = screenWidth * 0.40;
    final double carteHeight = screenWidth * 0.22;
    final double fontSize = screenWidth * 0.033;
    final double iconeSize = screenWidth * 0.031;

    // ── Couleurs selon type ───────────────────────────────────────────────
    final bool isVip = widget.typeVoyage == 'vip';
    final Color cardColor = isVip
        ? const Color(0xFF1A3D2B)
        : c.homeCardBackground.withValues(alpha: 0.85);
    final Color borderColor = isVip
        ? const Color(0xFFFFD700)
        : c.homeBordurePetiteCarte;
    final Color textColor = isVip ? const Color(0xFFFFD700) : c.homeTextPrimary;
    final Color iconColor = isVip ? const Color(0xFFFFD700) : c.homeAccent;

    return GestureDetector(
      onTap: () async {
        try {
          if (FirebaseAuth.instance.currentUser != null) {
            final userId = FirebaseAuth.instance.currentUser!.uid;
            setState(() => _isLoading = true);

            final data = await InformationsUtilisateur();
            if (data == null) return;
            setState(() => userData = data);

            await recuperationAffectationPrix();
            final cle = "${widget.depart} ${widget.destination}";

            if (prixDesBillets.containsKey(cle)) {
              prix = prixDesBillets[cle];
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Commande(
                    idUtilisateur: userId,
                    nom: userData!['nom'],
                    prenoms: '',
                    telephone: userData!['telephone'],
                    prixDuBillet: prix!,
                    depart: widget.depart,
                    destination: widget.destination,
                    typeVoyage: widget.typeVoyage,
                    ongletOrigine: widget.typeVoyage == 'vip' ? 2 : 0,
                  ),
                ),
              );
            } else {
              throw Exception('Prix non trouvé pour $cle');
            }
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          }
        } catch (e) {
          afficherErreur(context, e);
        } finally {
          setState(() => _isLoading = false);
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
        color: cardColor,
        elevation: 3,
        child: SizedBox(
          height: carteHeight,
          width: carteWidth,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.depart,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.airport_shuttle_sharp,
                    color: iconColor,
                    size: iconeSize,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      widget.destination,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                CircularProgressIndicator(color: iconColor, strokeWidth: 2.5),
            ],
          ),
        ),
      ),
    );
  }
}

// ── porte ──────────────────────────────────────────────────────────────────────
Widget porte() {
  return Row(
    children: [
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
    ],
  );
}

// ── Modèles ────────────────────────────────────────────────────────────────────
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

class InfosTarifs {
  final String depart;
  final String destination;
  final int prix;

  InfosTarifs(this.depart, this.destination, this.prix);

  factory InfosTarifs.fromJson(Map<String, dynamic> json) {
    return InfosTarifs(json['depart'], json['destination'], json['prix']);
  }
}
