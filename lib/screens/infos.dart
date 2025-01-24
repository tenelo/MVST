// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/infosPrix.dart';
import 'package:mvst/screens/localisation.dart';

class Informations extends StatefulWidget {
  const Informations({super.key});

  @override
  State<Informations> createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    LocalisationsDesGars(),
    InformationPrix(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            NavigationRail(
              groupAlignment: 0.0,
              indicatorColor: Config.colors.bleuFonce2,
              backgroundColor: const Color.fromARGB(255, 160, 196, 226),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(
                color: Colors.amber, // Couleur pour l'icône sélectionnée
                size: 30,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.white, // Couleur pour l'icône non sélectionnée
                size: 24,
              ),
              selectedLabelTextStyle: TextStyle(
                color: Colors.amber, // Couleur pour le texte sélectionné
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.white, // Couleur pour le texte non sélectionné
                fontWeight: FontWeight.normal,
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.location_on_outlined),
                  label: Text('Nos Gares'),
                  padding: EdgeInsets.symmetric(vertical: 20), // Espacement
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.attach_money_outlined),
                  label: Text('Nos tarifs'),
                ),
              ],
            ),
            // Affichage de la page sélectionnée
            Expanded(
              child: _pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}
