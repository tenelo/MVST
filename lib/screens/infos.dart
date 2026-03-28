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

  final List<Widget> _pages = [LocalisationsDesGars(), InformationPrix()];

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Navigation Rail ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.30,
              child: NavigationRail(
                groupAlignment: 0.0,
                indicatorColor: c.homeAccent,
                backgroundColor: c.homeButtonPrimary,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) {
                  setState(() => _selectedIndex = index);
                },
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: IconThemeData(color: Colors.white, size: 26),
                unselectedIconTheme: IconThemeData(
                  color: Colors.white,
                  size: 22,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: c.homeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.location_on_outlined),
                    label: Text('Nos Gares'),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.attach_money_outlined),
                    label: Text('Nos Tarifs'),
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ],
              ),
            ),
          ),
          // ── Page sélectionnée ──────────────────────────────────────
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
