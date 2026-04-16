import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst/config/config.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Exposées pour la génération PDF dans detailsTickets.dart
Color? couleurA;
Color? couleurB;

class CreationQrCode {
  static Widget buildQrCode(
    final String idUtilisateur,
    final String idTicket,
    final int place,
    final String nom,
    final String contact,
    final String date,
    final String heure,
    final String depart,
    final String destination,
    final String prix,
    final String etatScann,
    final DateTime datePourCalcule,
  ) {
    final String message =
        "$idUtilisateur \n$idTicket \n$nom \n$contact \n$date \n$heure \n$place \n$depart->$destination  \n$prix \n$etatScann \n$datePourCalcule";

    final Color qrCouleurA = etatScann == "scanné"
        ? Config.colors.bleuA
        : Config.colors.vertA;
    final Color qrCouleurB = etatScann == "scanné"
        ? Config.colors.bleuB
        : Config.colors.vertB;

    // Mise à jour des globales pour la génération PDF
    couleurA = qrCouleurA;
    couleurB = qrCouleurB;

    return FutureBuilder<ui.Image>(
      future: _loadOverlayImage(),
      builder: (BuildContext ctx, AsyncSnapshot<ui.Image> snapshot) {
        const double size = 250.0;
        return CustomPaint(
          size: const Size.square(size),
          painter: QrPainter(
            data: message,
            version: QrVersions.auto,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: qrCouleurA,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: qrCouleurB,
            ),
            embeddedImage: snapshot.data,
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size.square(52),
            ),
          ),
        );
      },
    );
  }

  static Future<ui.Image> _loadOverlayImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    final ByteData byteData = await rootBundle.load('assets/images/Qr_rd3.png');
    ui.decodeImageFromList(byteData.buffer.asUint8List(), completer.complete);
    return completer.future;
  }
}
