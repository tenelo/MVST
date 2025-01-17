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
              destinations: <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.location_on_outlined, color: Colors.white),
                  label: Text(
                    'Nos Gares',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 20), // Espacement
                ),
                NavigationRailDestination(
                  icon: Icon(
                    Icons.attach_money_outlined,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Les prix',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
