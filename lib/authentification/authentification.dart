// // ignore_for_file: library_private_types_in_public_api


// ignore_for_file: library_private_types_in_public_api

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/authentification/pin_creation.dart';
import 'package:mvst/config/config.dart';

// ════════════════════════════════════════════════════════════════
// FONCTIONS GLOBALES
// ════════════════════════════════════════════════════════════════

Future<void> creerUtilisateurEtAuthentifierParMail(
  String nom,
  String prenoms,
  String telephone,
  String ville,
  String pin,
  BuildContext context,
) async {
  try {
    final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: "$telephone@gmail.com",
          password: '${pin}mv',
        );

    User? user = userCredential.user;
    if (user != null) {
      await user.updateDisplayName('$nom $prenoms');

      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .set({
            'id': user.uid,
            'idAuth': user.uid,
            'nom': nom,
            'prenoms': prenoms,
            'residence': ville,
            'telephone': telephone,
            'points': 3,
            'mail': "$telephone@gmail.com",
            'dateDeCreation': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await ajouterUtilisateurALaBaseDeDonnees(
        idUtilisateur: user.uid,
        idAuth: user.uid,
        nom: nom,
        prenoms: prenoms,
        residence: ville,
        telephone: telephone,
        points: 3,
        mail: "$telephone@gmail.com",
      );

      const storage = FlutterSecureStorage();
      await storage.write(key: 'user_phone', value: telephone);
      await storage.write(key: 'user_pin', value: pin);
      await storage.write(key: 'user_id', value: user.uid);
      await storage.write(key: 'user_name', value: '$nom $prenoms');
    }
  } catch (e) {
    debugPrint('Erreur création compte: $e');
    rethrow;
  }
}

Future<void> ajouterUtilisateurALaBaseDeDonnees({
  required String idUtilisateur,
  required String idAuth,
  required String nom,
  required String prenoms,
  required String residence,
  required String telephone,
  required int points,
  required String mail,
}) async {
  const String apiUrl = '$kBaseUrl/insert_utilisateur.php';

  try {
    final response = await http
        .post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'idUtilisateur': idUtilisateur,
            'idAuth': idAuth,
            'nom': nom,
            'prenoms': prenoms,
            'residence': residence,
            'telephone': telephone,
            'points': points,
            'mail': mail,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!data['success']) {
        debugPrint('Erreur: ${data['message']}');
      }
    }
  } catch (e) {
    debugPrint('Erreur envoi données: $e');
  }
}

// ════════════════════════════════════════════════════════════════
// PAGE D'AUTHENTIFICATION (inscription)
// ════════════════════════════════════════════════════════════════

class PageDAuthentification extends StatefulWidget {
  const PageDAuthentification({super.key});

  @override
  _PageDAuthentificationState createState() => _PageDAuthentificationState();
}

class _PageDAuthentificationState extends State<PageDAuthentification> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _residenceController = TextEditingController();

  bool _isLoading = false;
  String? _erreur;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  Future<bool> _verifierNumero(String numero) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/verifierTelephone.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telephone': numero}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          if (data['bloque'] == true) {
            if (mounted) {
              final c = Config.colors;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: c.authDialogBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gpp_bad, color: Colors.red, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Accès Bloqué",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "\nVotre compte a été bloqué pour des raisons de sécurité."
                    "\n\nVeuillez contacter les administrateurs MVST pour assistance.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Future.delayed(
                          const Duration(milliseconds: 500),
                          () => SystemNavigator.pop(),
                        );
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return false;
          }

          if (data['existe'] == true) {
            if (mounted) {
              final c = Config.colors;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: c.authDialogBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        "Accès Refusé",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "\nLe numéro utilisé est déjà associé à un utilisateur existant."
                    "\nVeuillez contacter les administrateurs MVST pour assistance.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Future.delayed(
                          const Duration(milliseconds: 500),
                          () => SystemNavigator.pop(),
                        );
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de vérification. Réessayez.')),
        );
      }
      return false;
    }
  }

  Future<void> _creerCompte() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _residenceController.text.isEmpty) {
      setState(() => _erreur = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() {
      _isLoading = true;
      _erreur = null;
    });

    FocusScope.of(context).unfocus();

    // Vérifier le numéro avant de continuer
    final numeroValide = await _verifierNumero(_telephoneController.text);
    if (!numeroValide) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Aller directement vers PinCreation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PinCreation(
          onPinConfirmed: (pin) => creerUtilisateurEtAuthentifierParMail(
            _nomController.text,
            _prenomController.text,
            _telephoneController.text,
            _residenceController.text,
            pin,
            context,
          ),
        ),
      ),
    );
  }

  Widget _buildChamp({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.authCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.authBorder, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        cursorColor: c.authAccent,
        style: TextStyle(color: c.authTextPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          labelText: label,
          labelStyle: TextStyle(
            color: c.authTextSecondary,
            fontSize: screenWidth * 0.034,
          ),
          prefixIcon: Icon(icone, color: c.authAccent, size: 20),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (_, constraints) {
            final h = constraints.maxHeight;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: h * 0.04),
                    Container(
                      width: sw * 0.20,
                      height: sw * 0.20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.authAccent, width: 2),
                        color: c.authCardBackground,
                      ),
                      child: Center(
                        child: Text(
                          'MVST',
                          style: TextStyle(
                            color: c.authAccent,
                            fontSize: sw * 0.042,
                            fontFamily: 'Lobster',
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: h * 0.03),
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: c.authTextPrimary,
                        fontSize: sw * 0.058,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: h * 0.006),
                    Text(
                      'Remplissez les informations ci-dessous',
                      style: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: sw * 0.032,
                      ),
                    ),
                    SizedBox(height: h * 0.035),
                    _buildChamp(
                      controller: _nomController,
                      label: 'Nom',
                      icone: Icons.person_outline,
                    ),
                    _buildChamp(
                      controller: _prenomController,
                      label: 'Prénoms',
                      icone: Icons.person_outline,
                    ),
                    _buildChamp(
                      controller: _telephoneController,
                      label: 'Numéro de téléphone',
                      icone: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    _buildChamp(
                      controller: _residenceController,
                      label: 'Lieu de résidence',
                      icone: Icons.location_on_outlined,
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erreur!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ],
                    SizedBox(height: h * 0.01),
                    SizedBox(
                      width: double.infinity,
                      height: sw * 0.13,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.authButton,
                          foregroundColor: c.authTextPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isLoading ? null : _creerCompte,
                        child: _isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: c.authTextPrimary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Vérification...',
                                    style: TextStyle(
                                      color: c.authTextPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Créer mon compte',
                                style: TextStyle(
                                  fontSize: sw * 0.038,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: h * 0.03),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}





// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:mvst/authentification/pin_creation.dart';
// import 'package:mvst/config/config.dart';

// // ════════════════════════════════════════════════════════════════
// // FONCTIONS GLOBALES (accessibles par les deux classes)
// // ════════════════════════════════════════════════════════════════

// Future<void> creerUtilisateurEtAuthentifierParMail(
//   String authUid,
//   String nom,
//   String prenoms,
//   String telephone,
//   String ville,
//   String pin,
//   BuildContext context,
// ) async {
//   try {
//     final UserCredential userCredential = await FirebaseAuth.instance
//         .createUserWithEmailAndPassword(
//           email: "$telephone@gmail.com",
//           password: '${pin}mv',
//         );

//     User? user = userCredential.user;
//     if (user != null) {
//       await user.updateDisplayName('$nom $prenoms');

//       await FirebaseFirestore.instance
//           .collection('utilisateurs')
//           .doc(user.uid)
//           .set({
//             'id': user.uid,
//             'idAuth': authUid,
//             'nom': nom,
//             'prenoms': prenoms,
//             'residence': ville,
//             'telephone': telephone,
//             'points': 3,
//             'mail': "$telephone@gmail.com",
//             'dateDeCreation': FieldValue.serverTimestamp(),
//           }, SetOptions(merge: true));

//       await ajouterUtilisateurALaBaseDeDonnees(
//         idUtilisateur: user.uid,
//         idAuth: authUid,
//         nom: nom,
//         prenoms: prenoms,
//         residence: ville,
//         telephone: telephone,
//         points: 3,
//         mail: "$telephone@gmail.com",
//       );

//       const storage = FlutterSecureStorage();
//       await storage.write(key: 'user_phone', value: telephone);
//       await storage.write(key: 'user_pin', value: pin);
//       await storage.write(key: 'user_id', value: user.uid);
//       await storage.write(key: 'user_name', value: '$nom $prenoms');
//     }
//   } catch (e) {
//     debugPrint('❌ Erreur création compte: $e');
//   }
// }

// Future<void> ajouterUtilisateurALaBaseDeDonnees({
//   required String idUtilisateur,
//   required String idAuth,
//   required String nom,
//   required String prenoms,
//   required String residence,
//   required String telephone,
//   required int points,
//   required String mail,
// }) async {
//   const String apiUrl = '$kBaseUrl/insert_utilisateur.php';

//   try {
//     final Map<String, dynamic> requestBody = {
//       'idUtilisateur': idUtilisateur,
//       'idAuth': idAuth,
//       'nom': nom,
//       'prenoms': prenoms,
//       'residence': residence,
//       'telephone': telephone,
//       'points': points,
//       'mail': mail,
//     };

//     final response = await http
//         .post(
//           Uri.parse(apiUrl),
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode(requestBody),
//         )
//         .timeout(const Duration(seconds: 10));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       if (data['success']) {
//         debugPrint('Utilisateur ajouté avec succès');
//       } else {
//         debugPrint('Erreur: ${data['message']}');
//       }
//     } else {
//       debugPrint('Erreur serveur: ${response.statusCode}');
//     }
//   } catch (e) {
//     debugPrint('Erreur envoi données: $e');
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // PAGE D'AUTHENTIFICATION (inscription)
// // ════════════════════════════════════════════════════════════════

// class PageDAuthentification extends StatefulWidget {
//   const PageDAuthentification({super.key});

//   @override
//   _PageDAuthentificationState createState() => _PageDAuthentificationState();
// }

// class _PageDAuthentificationState extends State<PageDAuthentification> {
//   final TextEditingController _nomController = TextEditingController();
//   final TextEditingController _prenomController = TextEditingController();
//   final TextEditingController _telephoneController = TextEditingController();
//   final TextEditingController _residenceController = TextEditingController();

//   bool _isLoading = false;

//   Future<bool> verificationListeNoire(String numero) async {
//     try {
//       final response = await http
//           .post(
//             Uri.parse('$kBaseUrl/verifierTelephone.php'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({'telephone': numero}),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);

//         if (data['success'] == true) {
//           if (data['bloque'] == true) {
//             if (mounted) {
//               final c = Config.colors;
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   backgroundColor: c.authDialogBackground,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   title: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.gpp_bad, color: Colors.red, size: 28),
//                       SizedBox(width: 8),
//                       Text(
//                         "Accès Bloqué",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   content: const Text(
//                     "\nVotre compte a été bloqué pour des raisons de sécurité."
//                     "\nTrop de tentatives de connexion incorrectes."
//                     "\n\nVeuillez contacter les administrateurs MVST pour assistance.",
//                     style: TextStyle(color: Colors.white70),
//                     textAlign: TextAlign.center,
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         Future.delayed(const Duration(milliseconds: 500), () {
//                           SystemNavigator.pop();
//                         });
//                       },
//                       child: const Text(
//                         "OK",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//             return true;
//           }

//           if (data['existe'] == true) {
//             if (mounted) {
//               final c = Config.colors;
//               showDialog(
//                 context: context,
//                 builder: (context) => AlertDialog(
//                   backgroundColor: c.authDialogBackground,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   title: const Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.warning, color: Colors.red),
//                       SizedBox(width: 8),
//                       Text(
//                         "Accès Refusé",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   content: const Text(
//                     "\nLe numéro utilisé est déjà associé à un utilisateur existant."
//                     "\nVeuillez contacter les administrateurs MVST pour assistance.",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         Future.delayed(const Duration(milliseconds: 500), () {
//                           SystemNavigator.pop();
//                         });
//                       },
//                       child: const Text(
//                         "OK",
//                         style: TextStyle(
//                           color: Colors.red,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//             return true;
//           }
//         }
//         return false;
//       }
//       return false;
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Erreur lors de la vérification, reprenez le processus',
//             ),
//           ),
//         );
//       }
//       return false;
//     }
//   }

//   Future<void> _envoyerCodeDeVerification() async {
//     if (_nomController.text.isEmpty ||
//         _prenomController.text.isEmpty ||
//         _telephoneController.text.isEmpty ||
//         _residenceController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Color.fromARGB(255, 241, 94, 94),
//           content: Text(
//             'Veuillez remplir tous les champs.',
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//           ),
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);

//     bool surListeNoire = await verificationListeNoire(
//       _telephoneController.text,
//     );

//     if (surListeNoire) {
//       setState(() => _isLoading = false);
//       return;
//     }

//     String numeroTelephone = '+225${_telephoneController.text}';

//     try {
//       await FirebaseAuth.instance.verifyPhoneNumber(
//         phoneNumber: numeroTelephone,
//         timeout: const Duration(seconds: 120),

//         verificationCompleted: (PhoneAuthCredential credential) async {
//           try {
//             final userCredential = await FirebaseAuth.instance
//                 .signInWithCredential(credential);
//             final user = userCredential.user;
//             if (user == null || !mounted) return;

//             await user.updateDisplayName(
//               '${_nomController.text} ${_prenomController.text}',
//             );

//             if (mounted) {
//               setState(() => _isLoading = false);
//               //  On navigue vers PageDeVerification avec l'uid déjà connu
//               // L'utilisateur doit quand même appuyer sur "Valider" consciemment
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => PageDeVerification(
//                     verificationId: '',
//                     nom: _nomController.text,
//                     prenoms: _prenomController.text,
//                     telephone: _telephoneController.text,
//                     ville: _residenceController.text,
//                     uidDejaAuthentifie: user.uid,
//                   ),
//                 ),
//               );
//             }
//           } catch (_) {
//             if (mounted) setState(() => _isLoading = false);
//           }
//         },

//         verificationFailed: (FirebaseAuthException e) {
//           if (mounted) {
//             setState(() => _isLoading = false);
//             String message = 'Erreur de vérification. Réessayez.';
//             if (e.code == 'too-many-requests') {
//               message = 'Trop de tentatives. Réessayez plus tard.';
//             } else if (e.code == 'network-request-failed') {
//               message = 'Erreur réseau. Vérifiez votre connexion.';
//             } else if (e.code == 'invalid-phone-number') {
//               message = 'Numéro de téléphone invalide.';
//             }
//             ScaffoldMessenger.of(
//               context,
//             ).showSnackBar(SnackBar(content: Text(message)));
//           }
//         },

//         // verificationFailed: (FirebaseAuthException e) {
//         //   if (mounted) {
//         //     setState(() => _isLoading = false);
//         //     ScaffoldMessenger.of(
//         //       context,
//         //     ).showSnackBar(SnackBar(content: Text('${e.code} — ${e.message}')));
//         //   }
//         // },
//         codeSent: (String verificationId, int? resendToken) async {
//           if (mounted) {
//             setState(() => _isLoading = false);
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => PageDeVerification(
//                   verificationId: verificationId,
//                   nom: _nomController.text,
//                   prenoms: _prenomController.text,
//                   telephone: _telephoneController.text,
//                   ville: _residenceController.text,
//                 ),
//               ),
//             );
//           }
//         },

//         codeAutoRetrievalTimeout: (String verificationId) {},
//       );
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Erreur lors de l\'envoi du code.')),
//         );
//       }
//     }
//   }

//   Widget _buildChamp({
//     required TextEditingController controller,
//     required String label,
//     required IconData icone,
//     TextInputType keyboardType = TextInputType.text,
//     int? maxLength,
//   }) {
//     final c = Config.colors;
//     final double screenWidth = MediaQuery.of(context).size.width;
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: c.authCardBackground,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: c.authBorder, width: 1.5),
//       ),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLength: maxLength,
//         cursorColor: c.authAccent,
//         style: TextStyle(color: c.authTextPrimary, fontWeight: FontWeight.w500),
//         decoration: InputDecoration(
//           counterText: '',
//           border: InputBorder.none,
//           labelText: label,
//           labelStyle: TextStyle(
//             color: c.authTextSecondary,
//             fontSize: screenWidth * 0.034,
//           ),
//           prefixIcon: Icon(icone, color: c.authAccent, size: 20),
//           contentPadding: const EdgeInsets.symmetric(
//             vertical: 16,
//             horizontal: 12,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = Config.colors;
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: c.authBackground,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 SizedBox(height: screenHeight * 0.04),
//                 Container(
//                   width: screenWidth * 0.20,
//                   height: screenWidth * 0.20,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: c.authAccent, width: 2),
//                     color: c.authCardBackground,
//                   ),
//                   child: Center(
//                     child: Text(
//                       'MVST',
//                       style: TextStyle(
//                         color: c.authAccent,
//                         fontSize: screenWidth * 0.042,
//                         fontFamily: 'Lobster',
//                         letterSpacing: 1.5,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.03),
//                 Text(
//                   'Créer un compte',
//                   style: TextStyle(
//                     color: c.authTextPrimary,
//                     fontSize: screenWidth * 0.058,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 1,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.006),
//                 Text(
//                   'Remplissez les informations ci-dessous',
//                   style: TextStyle(
//                     color: c.authTextSecondary,
//                     fontSize: screenWidth * 0.032,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.035),
//                 _buildChamp(
//                   controller: _nomController,
//                   label: 'Nom',
//                   icone: Icons.person_outline,
//                 ),
//                 _buildChamp(
//                   controller: _prenomController,
//                   label: 'Prénoms',
//                   icone: Icons.person_outline,
//                 ),
//                 _buildChamp(
//                   controller: _telephoneController,
//                   label: 'Numéro de téléphone',
//                   icone: Icons.phone_outlined,
//                   keyboardType: TextInputType.phone,
//                   maxLength: 10,
//                 ),
//                 _buildChamp(
//                   controller: _residenceController,
//                   label: 'Lieu de résidence',
//                   icone: Icons.location_on_outlined,
//                 ),
//                 SizedBox(height: screenHeight * 0.01),
//                 SizedBox(
//                   width: double.infinity,
//                   height: screenHeight * 0.058,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: c.authButton,
//                       foregroundColor: c.authTextPrimary,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: _isLoading ? null : _envoyerCodeDeVerification,
//                     child: _isLoading
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               SizedBox(
//                                 width: 22,
//                                 height: 22,
//                                 child: CircularProgressIndicator(
//                                   color: c.authTextPrimary,
//                                   strokeWidth: 2.5,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Text(
//                                 'Envoi en cours...',
//                                 style: TextStyle(
//                                   color: c.authTextPrimary,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           )
//                         : Text(
//                             'Recevoir le code par SMS',
//                             style: TextStyle(
//                               fontSize: screenWidth * 0.038,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.03),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════
// // PAGE DE VERIFICATION (saisie du code SMS)
// // ════════════════════════════════════════════════════════════════

// class PageDeVerification extends StatefulWidget {
//   final String verificationId;
//   final String nom;
//   final String prenoms;
//   final String telephone;
//   final String ville;
//   final String? uidDejaAuthentifie;

//   const PageDeVerification({
//     super.key,
//     required this.verificationId,
//     required this.nom,
//     required this.prenoms,
//     required this.telephone,
//     required this.ville,
//     this.uidDejaAuthentifie,
//   });

//   @override
//   _PageDeVerificationState createState() => _PageDeVerificationState();
// }

// class _PageDeVerificationState extends State<PageDeVerification> {
//   final TextEditingController _codeController = TextEditingController();
//   String idAuth = '';
//   bool _isDisposed = false;
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _isDisposed = true;
//     _codeController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = Config.colors;
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double screenHeight = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: c.authBackground,
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 SizedBox(height: screenHeight * 0.06),
//                 Container(
//                   width: screenWidth * 0.20,
//                   height: screenWidth * 0.20,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border: Border.all(color: c.authAccent, width: 2),
//                     color: c.authCardBackground,
//                   ),
//                   child: Icon(
//                     Icons.sms_outlined,
//                     color: c.authAccent,
//                     size: screenWidth * 0.09,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.035),
//                 Text(
//                   'Code de vérification',
//                   style: TextStyle(
//                     color: c.authTextPrimary,
//                     fontSize: screenWidth * 0.056,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.008),
//                 Text(
//                   'Entrez le code reçu par SMS au',
//                   style: TextStyle(
//                     color: c.authTextSecondary,
//                     fontSize: screenWidth * 0.032,
//                   ),
//                 ),
//                 Text(
//                   '+225 ${widget.telephone}',
//                   style: TextStyle(
//                     color: c.authAccent,
//                     fontSize: screenWidth * 0.034,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.045),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: c.authCardBackground,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: c.authBorder, width: 1.5),
//                   ),
//                   child: TextFormField(
//                     maxLength: 6,
//                     cursorColor: c.authAccent,
//                     // Auto-remplissage du code à 6 chiffres reçu par SMS
//                     autofillHints: const [AutofillHints.oneTimeCode],
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: c.authTextPrimary,
//                       fontSize: screenWidth * 0.055,
//                       letterSpacing: 8,
//                     ),
//                     textAlign: TextAlign.center,
//                     controller: _codeController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       counterText: '',
//                       border: InputBorder.none,
//                       hintText: '------',
//                       hintStyle: TextStyle(
//                         color: c.authTextSecondary,
//                         fontSize: screenWidth * 0.05,
//                         letterSpacing: 8,
//                       ),
//                       contentPadding: EdgeInsets.symmetric(
//                         vertical: screenHeight * 0.022,
//                       ),
//                     ),
//                     onChanged: (value) {
//                       setState(() {});
//                       // Dès 6 chiffres saisis → vérification automatique
//                       if (value.length == 6) {
//                         _seConnecterParNumTelephone(
//                           widget.verificationId,
//                           value,
//                         );
//                       }
//                     },
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.035),
//                 SizedBox(
//                   width: double.infinity,
//                   height: screenHeight * 0.058,
//                   child: ElevatedButton(
//                     onPressed: _isLoading || _codeController.text.isEmpty
//                         ? null
//                         : () => _seConnecterParNumTelephone(
//                             widget.verificationId,
//                             _codeController.text,
//                           ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: c.authButton,
//                       foregroundColor: c.authTextPrimary,
//                       elevation: 0,
//                       disabledBackgroundColor: c.authButtonDisabled,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? SizedBox(
//                             width: 22,
//                             height: 22,
//                             child: CircularProgressIndicator(
//                               color: c.authTextPrimary,
//                               strokeWidth: 2.5,
//                             ),
//                           )
//                         : Text(
//                             'Valider',
//                             style: TextStyle(
//                               fontSize: screenWidth * 0.038,
//                               fontWeight: FontWeight.bold,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.02),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Future<void> _seConnecterParNumTelephone(
//     String verificationId,
//     String smsCode,
//   ) async {
//     if (_isDisposed) return;
//     setState(() => _isLoading = true);

//     try {
//       String uid;

//       if (widget.uidDejaAuthentifie != null &&
//           widget.uidDejaAuthentifie!.isNotEmpty) {
//         // CAS AUTO-DÉTECTION : sign-in déjà fait, on utilise l'uid existant
//         uid = widget.uidDejaAuthentifie!;
//       } else {
//         // CAS NORMAL : l'utilisateur saisit le code manuellement
//         final AuthCredential credential = PhoneAuthProvider.credential(
//           verificationId: verificationId,
//           smsCode: smsCode,
//         );

//         final UserCredential authResult = await FirebaseAuth.instance
//             .signInWithCredential(credential);

//         final User? user = authResult.user;
//         if (user == null) return;

//         await user.updateDisplayName('${widget.nom} ${widget.prenoms}');
//         uid = user.uid;
//       }

//       setState(() => idAuth = uid);

//       if (mounted) {
//         FocusScope.of(context).unfocus();
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => PinCreation(
//               onPinConfirmed: (pin) => creerUtilisateurEtAuthentifierParMail(
//                 uid,
//                 widget.nom,
//                 widget.prenoms,
//                 widget.telephone,
//                 widget.ville,
//                 pin,
//                 context,
//               ),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         String message = 'Une erreur est survenue. Réessayez.';
//         if (e is FirebaseAuthException) {
//           switch (e.code) {
//             case 'session-expired':
//               message =
//                   'Le code a expiré. Veuillez redemander un nouveau code.';
//               break;
//             case 'invalid-verification-code':
//               message = 'Code incorrect. Vérifiez le SMS et réessayez.';
//               break;
//             case 'too-many-requests':
//               message = 'Trop de tentatives. Réessayez dans quelques minutes.';
//               break;
//             case 'network-request-failed':
//               message = 'Erreur réseau. Vérifiez votre connexion.';
//               break;
//           }
//         }
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(message)));
//       }
//     }

//     if (mounted) setState(() => _isLoading = false);
//   }
// }
