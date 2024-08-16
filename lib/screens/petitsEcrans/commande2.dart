import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesfonctions.dart';
import 'package:mvst/screens/petitsEcrans/choixPlace2.dart';
import 'package:mvst/screens/petitsEcrans/home2.dart';

DateTime? dateActuelle = DateTime.now();
DateTime? dateDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 1);
DateTime? dateApresDemain = DateTime.utc(
    dateActuelle!.year, dateActuelle!.month, dateActuelle!.day + 2);
var idDate;

class Commande2 extends StatefulWidget {
  const Commande2(
      {super.key,
      required this.idUtilisateur,
      required this.nom,
      required this.prenoms,
      required this.telephone,
      required this.prixDuBillet,
      required this.depart,
      required this.destination});

  final String? idUtilisateur;
  final String? nom;
  final String? prenoms;
  final String? telephone;
  final String depart;
  final String destination;
  final int prixDuBillet;

  @override
  _Commande2State createState() => _Commande2State();
}

class _Commande2State extends State<Commande2> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController heureController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  DateTime? dateChoisie;
  String? heureDeDepart;
  List<String> listeHeures = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConfirmationDialog();
    });
    _initializeForm();
    _fetchHeuresDeDeparts();
  }

  void _initializeForm() {
    nomController.text = "${widget.nom!} ${widget.prenoms!}";
    contactController.text = widget.telephone!;
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirmez votre trajet",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Text(
              "Départ : ${widget.depart}\nDestination : ${widget.destination}\nTarif : ${widget.prixDuBillet} f"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Home2(),
                      ),
                    );
                  },
                  child: const Text("Annuler"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  void _selectionDate(BuildContext context) async {
    try {
      DateTime? choixDeDate = await showDatePicker(
        context: context,
        //initialDate: dateDemain!,
        firstDate: dateDemain!,
        lastDate: dateApresDemain!,
      );
      if (choixDeDate != null) {
        setState(() {
          _dateController.text =
              DateFormat('EEEE d MMMM y', 'fr_FR').format(choixDeDate);
        });
        idDate = DateFormat('EEEE_d_MMMM_y', 'fr_FR').format(choixDeDate);
      }
    } catch (error) {
      print("Erreur lors de la sélection de la date: $error");
    }
  }

  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final counterBloc = BlocProvider.of<BlocCompteur>(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 40,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        title: Text(
          "${widget.depart} -> ${widget.destination} tarif ${widget.prixDuBillet} f",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(132, 5, 82, 121),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: nomController,
                labelText: 'Nom et Prenoms',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: contactController,
                labelText: 'Contact',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              _buildDatePickerField(),
              const SizedBox(height: 10),
              _buildDropdownButtonFormField(),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });

                            counterBloc.add(EventInitialise());
                            await _recupListeDesNummeros(widget.depart,
                                widget.destination, idDate, heureDeDepart!);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChoixPlaces2(
                                  idDate: idDate,
                                  id: widget.idUtilisateur!,
                                  depart: widget.depart,
                                  destination: widget.destination,
                                  nom: nomController.text,
                                  contact: contactController.text,
                                  date: _dateController.text,
                                  heure: heureDeDepart!,
                                  prixDuBillet: widget.prixDuBillet,
                                ),
                              ),
                            ).then((_) {
                              // Réinitialiser l'état de chargement une fois que la navigation est terminée
                              setState(() {
                                _isLoading = false;
                              });
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(color: Colors.blue),
                    ),
                    backgroundColor: _isLoading
                        ? Color.fromARGB(255, 182, 214, 251)
                        : const Color.fromARGB(132, 17, 110, 156),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Choisir une place',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: Config.colors.bleuFonce,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Config.colors.bleuClaire,
            width: 1.0,
          ),
        ),
      ),
      validator: validator,
    );
  }

  TextFormField _buildDatePickerField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: () {
        _selectionDate(context);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez choisir une date';
        }
        return null;
      },
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Config.colors.bleuClaire,
          ),
        ),
        labelText: 'Date de départ',
        labelStyle: TextStyle(
          color: Config.colors.bleuFonce,
        ),
        suffixIcon: const Icon(
          Icons.calendar_month_outlined,
          color: Colors.blue,
        ),
      ),
    );
  }

  DropdownButtonFormField<String> _buildDropdownButtonFormField() {
    return DropdownButtonFormField<String>(
      iconEnabledColor: Colors.blue,
      value: heureDeDepart,
      onChanged: (value) {
        setState(() {
          heureDeDepart = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Veuillez choisir une heure de départ';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: 'Heure de départ',
        labelStyle: TextStyle(
          color: Config.colors.bleuFonce,
        ),
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Config.colors.bleuClaire,
          ),
        ),
      ),
      items: listeHeures.map((String h) {
        return DropdownMenuItem<String>(
          value: h,
          child: Text(h),
        );
      }).toList(),
    );
  }

  Future<void> _recupListeDesNummeros(
      String depart, String destination, String date, String heure) async {
    await ClasseListeDesPlaces.getTicketsStream(
        depart, destination, date, heure);
  }

  Future<void> _fetchHeuresDeDeparts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('heuresDeDeparts')
          .orderBy('dateCreation', descending: true)
          .get();
      final heures = snapshot.docs.map((doc) => doc['heure']).toList();
      setState(() {
        listeHeures = heures.cast<String>();
      });
    } catch (e) {
      print('Erreur lors de la récupération des heures : $e');
    }
  }
}
