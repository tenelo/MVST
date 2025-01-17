import 'package:flutter/material.dart';

class InformationPrix extends StatelessWidget {
  final List<Map<String, dynamic>> prices = [
    {'destination': 'Paris', 'price': 120.0, 'currency': '€'},
    {'destination': 'Londres', 'price': 150.0, 'currency': '€'},
    {'destination': 'New York', 'price': 400.0, 'currency': '\$'},
    {'destination': 'Tokyo', 'price': 600.0, 'currency': '¥'},
    {'destination': 'Paris', 'price': 120.0, 'currency': '€'},
    {'destination': 'Londres', 'price': 150.0, 'currency': '€'},
    {'destination': 'New York', 'price': 400.0, 'currency': '\$'},
    {'destination': 'Tokyo', 'price': 600.0, 'currency': '¥'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: prices.length,
          itemBuilder: (context, index) {
            final price = prices[index];
            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.grey[850],
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: Text(
                  price['destination'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${price['price']} ${price['currency']}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
                onTap: () {
                  // Ajoutez une action ici si nécessaire
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
