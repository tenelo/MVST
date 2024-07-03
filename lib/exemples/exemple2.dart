import 'package:flutter/material.dart';
import 'package:mvst/models/models.dart';

class Home3 extends StatefulWidget {
  const Home3({super.key});

  @override
  State<Home3> createState() => _Home3State();
}

class _Home3State extends State<Home3> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: const Text('MVST', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      drawer: const Drawer(),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          carte("Ferké", "Abidjan", "Bouaké"),
          carte("Bouaké", "Ferké", "Abidjan"),
          carte("Abidjan", "Ferké", "Bouaké"),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            label: 'Mes Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outlined),
            label: 'Infos',
          ),
        ],
      ),
    );
  }
}






/*import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';

class Home3 extends StatefulWidget {
  const Home3({super.key});

  @override
  State<Home3> createState() => _Home3State();
}

class _Home3State extends State<Home3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        title: Text('MVST', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      drawer: const Drawer(),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          carte("Ferké", "Abidjan", "Bouaké"),
          carte("Bouaké", "Ferké", "Abidjan"),
          carte("Abidjan", "Ferké", "Bouaké"),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.green,
        height: 55,
        destinations: [
          NavigationDestination(
            icon: Icon(color: Colors.white, Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(color: Colors.white, Icons.receipt_outlined),
            label: 'Mes Tickets',
          ),
          NavigationDestination(
            icon: Icon(color: Colors.white, Icons.info_outlined),
            label: 'Infos',
          ),
        ],
      ),
    );
  }
}
*/