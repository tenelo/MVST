import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/qrcode/creationQrCode.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:ticket_widget/ticket_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailsTickets extends StatefulWidget {
  final String idTicket;
  final String idUtilisateur;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String etatScann;
  final String statut;
  final String prixTicket;
  final DateTime datePourCalcule;
  final String typeVoyage;

  const DetailsTickets({
    super.key,
    required this.idTicket,
    required this.idUtilisateur,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
    required this.statut,
    required this.prixTicket,
    required this.datePourCalcule,
    required this.typeVoyage,
  });

  @override
  _DetailsTicketsState createState() => _DetailsTicketsState();
}

class _DetailsTicketsState extends State<DetailsTickets> {
  // ── Socket.IO ──────────────────────────────────────────────────────────────
  late IO.Socket socket;
  late String etatScannActuel;
  late StreamController<String> _etatScannController;

  @override
  void initState() {
    super.initState();

    etatScannActuel = widget.etatScann;
    _etatScannController = StreamController<String>.broadcast();
    _rafraichirEtat();
    _connecterSocket();
  }

  @override
  void dispose() {
    _etatScannController.close();
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  void _connecterSocket() {
    socket = IO.io(
      'https://mvst.tenelo.cloud',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    // ── Connexion établie → rejoindre la Room du trajet ───────────────────
    socket.onConnect((_) {
      final dateAvecUnderscores = widget.date.replaceAll(' ', '_');
      socket.emit('rejoindre_room', {
        'depart': widget.depart,
        'destination': widget.destination,
        'date': dateAvecUnderscores,
        'heure': widget.heure,
      });
    });

    // ── Ticket scanné par l'admin → changer couleur QR code ───────────────
    socket.on('ticket_valide', (data) {
      if (data['idUtilisateur'] == widget.idUtilisateur &&
          data['place'] == widget.place) {
        if (mounted) {
          setState(() {
            etatScannActuel = 'scanné';
            _etatScannController.add('scanné');
          });
        }
      }
    });

    // ── Déconnexion ───────────────────────────────────────────────────────
    socket.onDisconnect((_) {});
  }

  // ── GÉNÉRER PDF ────────────────────────────────────────────────────────────
  Future<void> genererPDF(BuildContext context) async {
    final qrData =
        "${widget.idUtilisateur} \n${widget.idTicket} \n${widget.nom} \n${widget.contact} \n${widget.date} \n${widget.heure} \n${widget.place} \n${widget.depart}->${widget.destination} ";

    final QrPainter qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: couleurA),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: couleurB,
      ),
    );
    final qrImage = await qrPainter.toImage(280);
    final ByteData? byteData = await qrImage.toByteData(
      format: ImageByteFormat.png,
    );
    final Uint8List imageData = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final qrImageFile = File('${tempDir.path}/qr_code.png');
    await qrImageFile.writeAsBytes(imageData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          final pdfImage = pw.MemoryImage(imageData);
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Première ligne (MVST) ───────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      height: 25.0,
                      decoration: pw.BoxDecoration(
                        borderRadius: pw.BorderRadius.circular(10.0),
                        border: pw.Border.all(
                          width: 1.0,
                          color: PdfColors.green,
                        ),
                      ),
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(2.0),
                        child: pw.Center(
                          child: pw.Text(
                            ' Mieux Vous Servir Transport ',
                            style: const pw.TextStyle(color: PdfColors.green),
                          ),
                        ),
                      ),
                    ),
                    pw.Text(
                      'MVST',
                      style: pw.TextStyle(
                        fontSize: 20.0,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8.0),
                  child: pw.Text(
                    "Ticket Ref° ${widget.idTicket.toUpperCase()}",
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey,
                    ),
                  ),
                ),
                // ── Départ / Destination ────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 20.0),
                  child: pw.Center(
                    child: pw.Text(
                      '${widget.depart} -> ${widget.destination}',
                      style: pw.TextStyle(
                        fontSize: 20.0,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                  ),
                ),
                // ── Passager / Contact ──────────────────────────────────
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 25.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Passager',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Contact',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.nom,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      widget.contact,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                // ── Date / Heure ────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0),
                      child: pw.Text(
                        'Date de voyage',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0),
                      child: pw.Text(
                        'Heure',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      widget.date,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.Text(
                      widget.heure,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                // ── Tarif / Siège ───────────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 8, top: 16.0),
                      child: pw.Text(
                        'Tarif : ${widget.prixTicket} f',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 16.0, right: 10),
                      child: pw.Text(
                        'Siège',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 18.0),
                      child: pw.Text(
                        widget.place.toString(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // ── QR Code ─────────────────────────────────────────────
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8.0),
                    child: pw.SizedBox(
                      width: 200,
                      height: 200,
                      child: pw.Image(pdfImage),
                    ),
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text(
                    'La compagnie MVST vous souhaite bon voyage!',
                    style: pw.TextStyle(
                      font: pw.Font.courier(),
                      fontItalic: pw.Font.timesItalic(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    Uint8List pdfData = await pdf.save();
    sauvegarderPdf(
      pdfData,
      'ticket_du_${widget.date}_Place_${widget.place}.pdf',
    );
  }

  Future<void> sauvegarderPdf(Uint8List pdfData, String nomDuFichier) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    final directory = await getExternalStorageDirectory();
    final mvstDirectory = Directory('${directory!.path}/TICKETS MVST');

    if (!await mvstDirectory.exists()) {
      await mvstDirectory.create(recursive: true);
    }

    var fichier = nomDuFichier;
    var file = File('${mvstDirectory.path}/$fichier');
    int count = 1;
    while (await file.exists()) {
      final nouveauNom = '${nomDuFichier.replaceAll('.pdf', '')}_$count.pdf';
      fichier = nouveauNom;
      file = File('${mvstDirectory.path}/$fichier');
      count++;
    }

    final cheminFichier = '${mvstDirectory.path}/$fichier';
    final fic = File(cheminFichier);
    await fic.writeAsBytes(pdfData);
    OpenFile.open(cheminFichier);

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.blue,
        content: Text(
          'PDF créé avec succès : $cheminFichier',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _rafraichirEtat() async {
    try {
      final documentId = widget.idTicket;
      final response = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/etatTicket.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'documentId': documentId, 'place': widget.place}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            etatScannActuel = data['etatScanne'];
            _etatScannController.add(etatScannActuel);
          });
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.colors.authDialogBackground,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * 0.06,
        title: const Text(
          'Details du ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Config.colors.authDialogBackground,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 6, right: 6, bottom: 6.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: TicketWidget(
                width: MediaQuery.of(context).size.width * 0.90,
                height: MediaQuery.of(context).size.height * 0.78,
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<String>(
                  stream: _etatScannController.stream,
                  initialData: etatScannActuel,
                  builder: (context, snapshot) {
                    return TicketData(
                      idUtilisateur: widget.idUtilisateur,
                      idTicket: widget.idTicket,
                      place: widget.place,
                      nom: widget.nom,
                      contact: widget.contact,
                      date: widget.date,
                      heure: widget.heure,
                      depart: widget.depart,
                      destination: widget.destination,
                      prixTicket: widget.prixTicket,
                      etatScann: snapshot.data ?? etatScannActuel,
                      dateCalcule: widget.datePourCalcule,
                      typeVoyage: widget.typeVoyage,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () => genererPDF(context),
        child: const Text(
          'Imprimer',
          style: TextStyle(
            color: Color.fromARGB(255, 10, 127, 229),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── TicketData ─────────────────────────────────────────────────────────────────
// StatelessWidget — reçoit etatScann dynamique depuis DetailsTickets
// Quand etatScann change → buildQrCode reçoit la nouvelle valeur
// → CreationQrCode change automatiquement les couleurs :
//   'scanné'    → bleuA + bleuB
//   'nonScanné' → vertA + vertB
class TicketData extends StatelessWidget {
  const TicketData({
    super.key,
    required this.idUtilisateur,
    required this.idTicket,
    required this.place,
    required this.nom,
    required this.contact,
    required this.date,
    required this.heure,
    required this.depart,
    required this.destination,
    required this.etatScann,
    required this.prixTicket,
    required this.dateCalcule,
    required this.typeVoyage,
  });

  final String idUtilisateur;
  final String idTicket;
  final int place;
  final String nom;
  final String contact;
  final String date;
  final String heure;
  final String depart;
  final String destination;
  final String prixTicket;
  final String etatScann;
  final DateTime dateCalcule;
  final String typeVoyage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Première ligne (MVST + badge VIP) ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                height: 25.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(width: 1.0, color: Colors.green),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Center(
                    child: Text(
                      ' Mieux Vous Servir Transport ',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: petitEcran ? 10 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (typeVoyage == 'vip') ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: petitEcran ? 5 : 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '★ VIP',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: petitEcran ? 9 : 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Text(
                  'MVST',
                  style: TextStyle(
                    color: Color.fromARGB(255, 10, 127, 229),
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // ── Référence ticket ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            "Ticket Ref ${idTicket.toUpperCase()}",
            style: const TextStyle(fontSize: 6, color: Colors.grey),
          ),
        ),
        // ── Départ / Destination ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: Center(
            child: Text(
              '$depart -> $destination',
              style: const TextStyle(
                color: Color.fromARGB(255, 9, 15, 123),
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // ── Passager / Contact ─────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passager',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                'Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nom, style: const TextStyle(fontFamily: 'Lobster')),
            Text(contact, style: const TextStyle(fontFamily: 'Lobster')),
          ],
        ),
        // ── Date / Heure ───────────────────────────────────────────────────
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Date de voyage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Heure',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              heure,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        // ── Tarif / Siège ──────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 16.0),
              child: Text(
                'Tarif : $prixTicket f',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0, right: 10),
              child: Text(
                'Siège',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18.0),
              child: Text(
                "$place",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // ── QR Code ────────────────────────────────────────────────────────
        // etatScann est dynamique → reçu depuis DetailsTickets via Socket.IO
        // 'nonScanné' → couleurs vertes
        // 'scanné'    → couleurs bleues (changement instantané)
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              width: 180,
              height: 180,
              child: FittedBox(
                child: CreationQrCode.buildQrCode(
                  idUtilisateur,
                  idTicket,
                  place,
                  nom,
                  contact,
                  date,
                  heure,
                  depart,
                  destination,
                  prixTicket,
                  etatScann, // ← valeur dynamique
                  dateCalcule,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'La compagnie MVST vous souhaite bon voyage!',
            style: TextStyle(fontFamily: 'Lobster'),
          ),
        ),
      ],
    );
  }
}
