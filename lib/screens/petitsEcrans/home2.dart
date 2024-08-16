import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/profil/profil.dart';
import 'package:mvst/screens/conditionsDutilisation.dart';
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/petitsEcrans/models2.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/tableauDesTickets.dart';

final user = FirebaseAuth.instance.currentUser!;

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _Home2State();
}

class _Home2State extends State<Home2> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final BlocCompteur initialiseBloc = BlocProvider.of<BlocCompteur>(context);
    initialiseBloc.add(EventInitialise());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.colors.bleuFonce2,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(95),
        child: SafeArea(
          bottom: false,
          child: AppBar(
            iconTheme: IconThemeData(
              color: Config.colors.jauneBlanc,
            ),
            flexibleSpace: const Carousel2(),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Config.colors.bleuFonce2,
                    ),
                    child: Center(
                      child: Container(
                        width: 120.0,
                        height: 120.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Config.colors.jauneBlanc,
                            width: 2.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'MVST',
                            style: TextStyle(
                              color: Config.colors.bleuClaire,
                              fontSize: 24,
                              fontFamily: 'Lobster',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.perm_identity_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Profil',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser != null) {
                        String userId = FirebaseAuth.instance.currentUser!.uid;
                        String? userProfil =
                            FirebaseAuth.instance.currentUser!.displayName;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Profil(
                              idUtilisateur: userId,
                              userProfil: userProfil!,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PageDAuthentification(),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.notification_add_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Notification',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      if (FirebaseAuth.instance.currentUser != null) {
                      } else {
                        Navigator.pop(context);
                        showIncompleteFieldsSnackBar(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.receipt_long_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Termes et Conditions',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConditionsDUtilisation(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lightbulb_outlined,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Suggestions',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () async {
                      if (FirebaseAuth.instance.currentUser != null) {
                        String userId =
                            await FirebaseAuth.instance.currentUser!.uid;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Suggestions(
                              idUtilisateur: userId,
                            ),
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                        showIncompleteFieldsSnackBar(context);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.power_settings_new,
                      color: Config.colors.bleuClaire,
                    ),
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Config.colors.bleuClaire,
                        fontFamily: 'Lobster',
                      ),
                    ),
                    onTap: () => deconnexion(context),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.info_outlined,
                color: Config.colors.bleuClaire,
              ),
              title: Text(
                'À propos du développeur',
                style: TextStyle(
                  color: Config.colors.bleuClaire,
                  fontFamily: 'Lobster',
                ),
              ),
              onTap: () {
                if (FirebaseAuth.instance.currentUser != null) {
                } else {
                  Navigator.pop(context);
                  showIncompleteFieldsSnackBar(context);
                }
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              top: 4,
              right: 10,
            ),
            child: Card(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 4,
                      top: 30,
                      right: 4,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        carteALettre("M"),
                        carteALettre("V"),
                        carteALettre("S"),
                        carteALettre("T"),
                      ],
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 90.0),
                      child: Column(
                        children: [
                          carte2("Ferké", "Abidjan", "Bouaké"),
                          carte2("Bouaké", "Ferké", "Abidjan"),
                          carte2("Abidjan", "Ferké", "Bouaké"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ignore: unnecessary_null_comparison
          user != null
              ? MesTickets(
                  idUtilisateur: user.uid,
                )
              : const Login(), // Redirige directement vers la page de connexion
          FirebaseAuth.instance.currentUser != null
              ? TableauDeTickets(
                  idUtilisateur: user.uid,
                )
              : const Login(),
          Informations(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: TabBar(
          tabAlignment: TabAlignment.center,
          labelStyle: TextStyle(fontSize: 10),
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Accueil',
            ),
            Tab(icon: Icon(Icons.receipt_outlined), text: 'Mes Tickets'),
            Tab(icon: Icon(Icons.list), text: 'Tous mes Tickets'),
            Tab(icon: Icon(Icons.info_outlined), text: 'Infos'),
          ],
          labelColor: Colors.lightBlue,
          indicatorColor: Colors.lightBlueAccent,
          unselectedLabelColor: Colors.grey[600],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

void deconnexion(BuildContext context) async {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  await _auth.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (BuildContext context) => const Login()),
    (route) => false,
  );
}

void showIncompleteFieldsSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      duration: Duration(seconds: 8),
      backgroundColor: Color.fromARGB(255, 241, 94, 94),
      content: Text(
        'Vous n\'êtes pas authentifié, allez dans Paramètres puis Profil pour créer votre compte',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
