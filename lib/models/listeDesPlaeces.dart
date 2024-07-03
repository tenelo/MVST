import 'package:cloud_firestore/cloud_firestore.dart';

class FonctionListeDesPlaces {
  static Future<void> recup() async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final snapshot = await _firestore.collection('tickets').get();
    ListeDesPlaces.listeNummeros = snapshot.docs
        .map((doc) {
          final data = doc.data();
          return data['place'] as int?;
        })
        .where((place) => place != null)
        .map((place) => place!)
        .toList();
  }
}

class ListeDesPlaces {
  static List<int> listeNummeros = [];
}

class ClasseListeDesPlaces {
  static void getTicketsStream() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    _firestore.collection('tickets').snapshots().listen((snapshot) {
      ListeDesPlaces.listeNummeros.clear();
      snapshot.docs.forEach((doc) {
        final data = doc.data();
        if (data['place'] != null) {
          ListeDesPlaces.listeNummeros.add(data['place'] as int);
        }
      });
    });
  }
}
