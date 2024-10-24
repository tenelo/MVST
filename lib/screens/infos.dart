// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:mvst/config/config.dart';

class Informations extends StatefulWidget {
  Informations({super.key});

  @override
  State<Informations> createState() => _InformationsState();
}

class _InformationsState extends State<Informations> {
  Future<List<Map<String, dynamic>>> fetchInfosGares() async {
    final conn = await Connexion.connexionDB();

    try {
      var results = await conn
          .query('SELECT ville, description, telephone FROM InfosGares');
      List<Map<String, dynamic>> infos = [];

      for (var row in results) {
        infos.add({
          'ville': row['ville'],
          'description': row['description'],
          'telephone': row['telephone'],
        });
      }
      return infos;
    } catch (e) {
      print("Erreur lors de la récupération des infos: $e");
      return [];
    } finally {
      await conn.close();
    }
  }

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
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchInfosGares(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return Center(
                          child: Text(
                        'Aucune donnée',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Config.colors.bleuA),
                      ));
                    }

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: snapshot.data!.map((_infos) {
                        return carteInfos(
                          context,
                          _infos['ville'],
                          _infos['description'],
                          _infos['telephone'],
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
                    borderRadius: BorderRadius.circular(10.0),
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
