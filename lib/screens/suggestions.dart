import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mvst/config/config.dart';

class Suggestions extends StatefulWidget {
  const Suggestions({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _nameError;
  String? _phoneNumberError;
  String? _emailError;
  String? _messageError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    CollectionReference usersCollection = _firestore.collection('utilisateurs');
    try {
      QuerySnapshot querySnapshot = await usersCollection
          .where('id', isEqualTo: widget.idUtilisateur)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          var _noms = "${userData['nom']} ${userData['prenoms']}";
          setState(() {
            _nameController.text = _noms;
            _phoneNumberController.text = userData['telephone'] ?? '';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            backgroundColor: Config.colors.bleuFonce2,
            content: Text(
              'Aucun utilisateur trouvé avec l\'ID "${widget.idUtilisateur}".',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          backgroundColor: Config.colors.bleuFonce2,
          content: Text(
            'Erreur lors de la récupération des données de l\'utilisateur : $e',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suggestions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        backgroundColor: Color.fromRGBO(5, 82, 121, 0.518),
      ),
      body: _isLoading
          ? Center(
              child: SpinKitPouringHourGlassRefined(
              color: Colors.blueGrey,
            ))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laissez-nous vos suggestions :',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        border: const OutlineInputBorder(),
                        errorText: _nameError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        border: const OutlineInputBorder(),
                        errorText: _phoneNumberError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Adresse email',
                        border: const OutlineInputBorder(),
                        errorText: _emailError,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLines: 10,
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Votre suggestion',
                        border: const OutlineInputBorder(),
                        errorText: _messageError,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Réinitialiser les messages d'erreur
                          setState(() {
                            _nameError = null;
                            _phoneNumberError = null;
                            _emailError = null;
                            _messageError = null;
                          });

                          // Vérifier si tous les champs sont remplis
                          if (_nameController.text.isEmpty) {
                            setState(() {
                              _nameError = 'Veuillez saisir votre nom.';
                            });
                          }
                          if (_phoneNumberController.text.isEmpty) {
                            setState(() {
                              _phoneNumberError =
                                  'Veuillez saisir votre numéro de téléphone.';
                            });
                          }
                          if (_emailController.text.isEmpty) {
                            setState(() {
                              _emailError =
                                  'Veuillez saisir votre adresse email.';
                            });
                          } else if (!_isValidEmail(_emailController.text)) {
                            setState(() {
                              _emailError = 'Adresse email invalide.';
                            });
                          }
                          if (_messageController.text.isEmpty) {
                            setState(() {
                              _messageError =
                                  'Veuillez saisir votre suggestion.';
                            });
                          }

                          // Si tous les champs sont remplis, traiter les suggestions
                          if (_nameController.text.isNotEmpty &&
                              _phoneNumberController.text.isNotEmpty &&
                              _emailController.text.isNotEmpty &&
                              _isValidEmail(_emailController.text) &&
                              _messageController.text.isNotEmpty) {
                            // Traiter les suggestions ici

                            // Réinitialiser les champs après soumission
                            _nameController.clear();
                            _phoneNumberController.clear();
                            _emailController.clear();
                            _messageController.clear();

                            // Afficher une confirmation à l'utilisateur
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Merci pour votre suggestion !'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.colors.bleuFonce2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        child: const Text(
                          'Soumettre',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Fonction pour valider le format de l'adresse email
  bool _isValidEmail(String email) {
    // Expression régulière pour vérifier le format de l'adresse email
    final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$");
    return emailRegExp.hasMatch(email);
  }
}















/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';

class Suggestions extends StatefulWidget {
  const Suggestions({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  _SuggestionsState createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _nameError;
  String? _phoneNumberError;
  String? _emailError;
  String? _messageError;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    CollectionReference usersCollection = _firestore.collection('utilisateurs');
    try {
      QuerySnapshot querySnapshot = await usersCollection
          .where('id', isEqualTo: widget.idUtilisateur)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        Map<String, dynamic>? userData =
            userDoc.data() as Map<String, dynamic>?;

        if (userData != null) {
          var _noms = await "${userData['nom']} ${userData['prenoms']}";
          setState(() {
            _nameController.text = _noms;
            _phoneNumberController.text = userData['telephone'] ?? '';
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: Duration(seconds: 8),
            backgroundColor: Config.colors.bleuFonce2,
            content: Text(
              'Aucun utilisateur trouvé avec l\'ID "${widget.idUtilisateur}".',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          backgroundColor: Config.colors.bleuFonce2,
          content: Text(
            'Erreur lors de la récupération des données de l\'utilisateur : $e',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suggestions',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(132, 5, 82, 121),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laissez-nous vos suggestions :',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: const OutlineInputBorder(),
                  errorText: _phoneNumberError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse email',
                  border: const OutlineInputBorder(),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                maxLines: 10,
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Votre suggestion',
                  border: const OutlineInputBorder(),
                  errorText: _messageError,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Réinitialiser les messages d'erreur
                    setState(() {
                      _nameError = null;
                      _phoneNumberError = null;
                      _emailError = null;
                      _messageError = null;
                    });

                    // Vérifier si tous les champs sont remplis
                    if (_nameController.text.isEmpty) {
                      setState(() {
                        _nameError = 'Veuillez saisir votre nom.';
                      });
                    }
                    if (_phoneNumberController.text.isEmpty) {
                      setState(() {
                        _phoneNumberError =
                            'Veuillez saisir votre numéro de téléphone.';
                      });
                    }
                    if (_emailController.text.isEmpty) {
                      setState(() {
                        _emailError = 'Veuillez saisir votre adresse email.';
                      });
                    } else if (!_isValidEmail(_emailController.text)) {
                      setState(() {
                        _emailError = 'Adresse email invalide.';
                      });
                    }
                    if (_messageController.text.isEmpty) {
                      setState(() {
                        _messageError = 'Veuillez saisir votre suggestion.';
                      });
                    }

                    // Si tous les champs sont remplis, traiter les suggestions
                    if (_nameController.text.isNotEmpty &&
                        _phoneNumberController.text.isNotEmpty &&
                        _emailController.text.isNotEmpty &&
                        _isValidEmail(_emailController.text) &&
                        _messageController.text.isNotEmpty) {
                      // Traiter les suggestions ici

                      // Réinitialiser les champs après soumission
                      _nameController.clear();
                      _phoneNumberController.clear();
                      _emailController.clear();
                      _messageController.clear();

                      // Afficher une confirmation à l'utilisateur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Merci pour votre suggestion !'),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.colors.bleuFonce2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                  child: const Text(
                    'Soumettre',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction pour valider le format de l'adresse email
  bool _isValidEmail(String email) {
    // Expression régulière pour vérifier le format de l'adresse email
    final RegExp emailRegExp = RegExp(
        r"^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$");
    return emailRegExp.hasMatch(email);
  }
}*/