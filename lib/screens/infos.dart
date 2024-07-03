// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:mvst/config/config.dart';

class Informations extends StatelessWidget {
  Informations({super.key});
  final CollectionReference itemsCollection =
      FirebaseFirestore.instance.collection('infosGares');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.18,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(109, 158, 158, 158),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
                ),
              ),
            ),
            Card(
              color: const Color.fromARGB(63, 158, 158, 158),
              child: SingleChildScrollView(
                child: StreamBuilder(
                  stream: itemsCollection.snapshots(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('Aucune donnée'));
                    }
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: snapshot.data!.docs.map((document) {
                        return carteInfos(
                          context,
                          document['ville'],
                          document['description'],
                          document['telephone'],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget carteInfos(
    BuildContext context, String ville, String localisation, String contact) {
  return Card(
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.20,
      width: MediaQuery.of(context).size.width * 0.80,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, top: 4.0, right: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ville,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
            Text(
              localisation,
              maxLines: 4,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _appel(contact);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(132, 5, 82, 121),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Rayon des bordures
                  ),
                ),
                child: Text(
                  "Appeler à la gare",
                  style: TextStyle(color: Config.colors.jauneBlanc),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

_appel(String numero) async {
  bool? res = await FlutterPhoneDirectCaller.callNumber(numero);
}
