import 'package:flutter/material.dart';
import 'package:mvst/config/config.dart';

class Home2B extends StatefulWidget {
  const Home2B({super.key});

  @override
  State<Home2B> createState() => _Home2BState();
}

class _Home2BState extends State<Home2B> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.colors.jauneBlanc,
        title: const Text(
          'Billets de Bus',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications),
            color: Colors.black,
          ),
        ],
      ),
      drawer: const Drawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Voyages Récents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  VoyageCard(
                    from: 'Ferké',
                    to: 'Abidjan',
                    price: '5000 FCFA',
                    time: '12:00 PM',
                  ),
                  SizedBox(height: 8),
                  VoyageCard(
                    from: 'Bouaké',
                    to: 'Ferké',
                    price: '4500 FCFA',
                    time: '02:30 PM',
                  ),
                  SizedBox(height: 8),
                  VoyageCard(
                    from: 'Abidjan',
                    to: 'Ferké',
                    price: '5500 FCFA',
                    time: '04:00 PM',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Mes Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Infos',
          ),
        ],
      ),
    );
  }
}

class VoyageCard extends StatelessWidget {
  final String from;
  final String to;
  final String price;
  final String time;

  const VoyageCard({
    required this.from,
    required this.to,
    required this.price,
    required this.time,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.directions_bus),
        ),
        title: Text('$from - $to'),
        subtitle: Text('$price • $time'),
        trailing: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
    );
  }
}
