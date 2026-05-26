import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/screens/carousel.dart';
import 'package:mvst/screens/commande.dart';

//const Color _vipGreen = Color(0xFF00D87E);
//const Color _vipGold = Color(0xFFC8A227);
const Color _vipGreen = Color(0xFF28C47A);
const Color _vipGold = Color.fromARGB(255, 243, 206, 85);

class Accueil extends StatefulWidget {
  const Accueil({super.key});
  @override
  State<Accueil> createState() => _AccueilState();
}

class _AccueilState extends State<Accueil> {
  List<Map<String, String>> _lignesVip = [];
  List<Map<String, String>> _lignesStd = [];
  bool _loadingLignes = true;

  String? _departVip;
  String? _destVip;
  bool _loadingVip = false;

  String? _departStd;
  String? _destStd;
  bool _loadingStd = false;

  // 'vip' | 'std' | null  — quelle section est en cours de saisie
  String? _sectionActive;
  Key _promoKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _chargerLignes();
  }

  List<String> get _departsVip =>
      _lignesVip.map((l) => l['depart']!).toSet().toList();

  List<String> get _departsStd =>
      _lignesStd.map((l) => l['depart']!).toSet().toList();

  List<String> _destsVip(String? depart) => depart == null
      ? []
      : _lignesVip
            .where((l) => l['depart'] == depart)
            .map((l) => l['destination']!)
            .toList();

  List<String> _destsStd(String? depart) => depart == null
      ? []
      : _lignesStd
            .where((l) => l['depart'] == depart)
            .map((l) => l['destination']!)
            .toList();

  // Chargement initial des lignes
  Future<void> _chargerLignes() async {
    if (!mounted) return;
    setState(() => _loadingLignes = true);
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/api_lignes.php?type=all'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          final lignes = List<Map<String, dynamic>>.from(data['lignes']);
          setState(() {
            _lignesStd = lignes
                .where((l) => l['type'] == 'standard')
                .map(
                  (l) => {
                    'depart': l['depart'].toString(),
                    'destination': l['destination'].toString(),
                  },
                )
                .toList();
            _lignesVip = lignes
                .where((l) => l['type'] == 'vip')
                .map(
                  (l) => {
                    'depart': l['depart'].toString(),
                    'destination': l['destination'].toString(),
                  },
                )
                .toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingLignes = false);
  }

  // Pull-to-refresh : vide les sélections et la section active
  Future<void> _rafraichirPromo() async {
    setState(() {
      _promoKey = UniqueKey();
      _departVip = null;
      _destVip = null;
      _departStd = null;
      _destStd = null;
      _sectionActive = null;
    });
  }

  void _showRestrictedDialog() {
    final c = Config.colors;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.homeCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Accès restreint',
              style: TextStyle(
                color: c.homeTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Votre profil est soumis à une restriction.\nVeuillez contacter l\'administrateur MVST Mobile.',
          style: TextStyle(color: c.homeTextPrimary.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reserver({
    required String depart,
    required String destination,
    required String type,
    required void Function(bool) setLoading,
  }) async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }
    setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final userRes = await http
          .post(
            Uri.parse('$kBaseUrl/verifierUtilisateur.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idUtilisateur': user.uid}),
          )
          .timeout(const Duration(seconds: 10));
      if (userRes.statusCode != 200 || !mounted) return;
      final userData = json.decode(userRes.body);
      if (userData['success'] == false) return;
      if ((userData['points'] ?? 0) == 0) {
        if (mounted) _showRestrictedDialog();
        return;
      }

      final prixRes = await http
          .post(
            Uri.parse('$kBaseUrl/getPrixDesTickets.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'type': type}),
          )
          .timeout(const Duration(seconds: 10));
      if (prixRes.statusCode != 200 || !mounted) return;
      final prixData = json.decode(prixRes.body);
      if (prixData['success'] != true) return;
      prixDesBillets.clear();
      for (final item in List<Map<String, dynamic>>.from(prixData['heures'])) {
        prixDesBillets[item['axe']] = item['prix'];
      }
      final prix = prixDesBillets['$depart $destination'];
      if (prix == null) throw Exception('Prix non trouvé');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Commande(
            idUtilisateur: user.uid,
            nom: userData['nom'] ?? '',
            prenoms: userData['prenoms'] ?? '',
            telephone: userData['telephone'] ?? '',
            prixDuBillet: prix,
            depart: depart,
            destination: destination,
            typeVoyage: type,
            ongletOrigine: 0,
          ),
        ),
      ).then((_) {
        if (mounted) {
          setState(() {
            _sectionActive = null;
            _departVip = null;
            _destVip = null;
            _departStd = null;
            _destStd = null;
          });
        }
      });
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Container(
      color: c.homeBackground,
      child: RefreshIndicator(
        color: c.homeButtonPrimary,
        onRefresh: _rafraichirPromo,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: PromoStripWidget(key: _promoKey)),
            SliverToBoxAdapter(child: _buildHeroBand(context)),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _sectionActive == null || _sectionActive == 'vip'
                        ? 1.0
                        : 0.70,
                    duration: const Duration(milliseconds: 250),
                    child: _buildVipSection(context),
                  ),
                  AnimatedOpacity(
                    opacity: _sectionActive == null || _sectionActive == 'std'
                        ? 1.0
                        : 0.60,
                    duration: const Duration(milliseconds: 250),
                    child: _buildStdSection(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVipSection(BuildContext context) {
    // final c = Config.colors;
    final w = MediaQuery.of(context).size.width;
    final destsVip = _destsVip(_departVip);
    final bool canReserve = _departVip != null && _destVip != null;
    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.020, w * 0.02, w * 0.020, 0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 1, 77, 41).withAlpha(30),

        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(
          color: const Color.fromARGB(255, 3, 189, 93),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.all(w * 0.020),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.005,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 1, 77, 41),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _vipGold, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.airline_seat_recline_extra,
                      color: _vipGold,
                      size: w * 0.040,
                    ),
                    SizedBox(width: w * 0.015),
                    Text(
                      'VIP — Voyages Premium',
                      style: TextStyle(
                        color: _vipGold,
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.032,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_loadingLignes)
                Text(
                  '${_lignesVip.length} lignes',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: w * 0.027,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: w * 0.02),
          Row(
            children: [
              Text(
                'Voyagez en première classe',
                style: TextStyle(
                  color: const Color.fromARGB(255, 1, 87, 8),
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {
                  _departVip = null;
                  _destVip = null;
                  _sectionActive = null;
                }),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.green,
                  size: w * 0.05,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.010),
          if (_loadingLignes)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: w * 0.04),
                child: CircularProgressIndicator(
                  color: _vipGold,
                  strokeWidth: 1,
                ),
              ),
            )
          else if (_lignesVip.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: w * 0.04),
              child: Text(
                'Aucune ligne VIP disponible',
                style: TextStyle(
                  color: _vipGreen.withValues(alpha: 0.5),
                  fontSize: w * 0.035,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'Départ',
                    value: _departVip,
                    items: _departsVip,
                    accentColor: const Color.fromARGB(255, 3, 189, 93),
                    enabled: _sectionActive == null || _sectionActive == 'vip',
                    onChanged: (val) => setState(() {
                      _departVip = val;
                      _destVip = null;
                      _sectionActive = val != null ? 'vip' : null;
                    }),
                    dark: true,
                  ),
                ),
                SizedBox(width: w * 0.01),
                Expanded(
                  child: _buildDropdown(
                    hint: 'Destination',
                    value: _destVip,
                    items: destsVip,
                    accentColor: const Color.fromARGB(255, 3, 189, 93),
                    enabled: _sectionActive == 'vip' && _departVip != null,
                    onChanged: (val) => setState(() => _destVip = val),
                    dark: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: w * 0.02),
            SizedBox(
              width: double.infinity,
              height: w * 0.10,
              child: ElevatedButton(
                onPressed: (canReserve && !_loadingVip)
                    ? () => _reserver(
                        depart: _departVip!,
                        destination: _destVip!,
                        type: 'vip',
                        setLoading: (v) => setState(() => _loadingVip = v),
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 88, 43),
                  disabledBackgroundColor: const Color.fromARGB(
                    255,
                    65,
                    165,
                    99,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.035),
                  ),
                  elevation: 0,
                ),
                child: _loadingVip
                    ? SizedBox(
                        width: w * 0.055,
                        height: w * 0.055,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _vipGreen,
                        ),
                      )
                    : Text(
                        'Réserver VIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: w * 0.038,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget _buildVipSection(BuildContext context) {
  //   final c = Config.colors;
  //   final w = MediaQuery.of(context).size.width;
  //   final destsVip = _destsVip(_departVip);
  //   final bool canReserve = _departVip != null && _destVip != null;
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(w * 0.020, w * 0.02, w * 0.020, 0),
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           Color(0xFF091A0E),
  //           Color.fromARGB(255, 24, 66, 19),
  //           Color(0xFF061009),
  //         ],
  //         // colors: [
  //         //   Color.fromARGB(255, 0, 32, 9),
  //         //   Color.fromARGB(255, 35, 95, 2),
  //         //   Color.fromARGB(255, 0, 32, 9),
  //         // ],
  //         stops: [0.0, 0.80, 1.0],
  //         // colors: [
  //         //   Color.fromARGB(255, 2, 57, 18),
  //         //   Color.fromARGB(255, 48, 125, 3),
  //         //   Color.fromARGB(255, 2, 57, 18),
  //         // ],
  //         //stops: [0.0, 0.55, 1.0],
  //       ),
  //       borderRadius: BorderRadius.circular(w * 0.045),
  //       border: Border.all(
  //         color: _vipGreen.withValues(alpha: 0.30),
  //         width: 1.5,
  //       ),
  //     ),
  //     padding: EdgeInsets.all(w * 0.020),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Container(
  //               padding: EdgeInsets.symmetric(
  //                 horizontal: w * 0.025,
  //                 vertical: w * 0.008,
  //               ),
  //               decoration: BoxDecoration(
  //                 color: _vipGreen.withValues(alpha: 0.12),
  //                 borderRadius: BorderRadius.circular(30),
  //                 border: Border.all(
  //                   color: _vipGreen.withValues(alpha: 0.30),
  //                   width: 0.8,
  //                 ),
  //               ),
  //               child: Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(
  //                     Icons.airline_seat_recline_extra,
  //                     color: _vipGreen,
  //                     size: w * 0.033,
  //                   ),
  //                   SizedBox(width: w * 0.015),
  //                   Text(
  //                     'VIP — Voyages Premium',
  //                     style: TextStyle(
  //                       color: _vipGreen,
  //                       fontWeight: FontWeight.w700,
  //                       fontSize: w * 0.029,
  //                       letterSpacing: 0.4,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const Spacer(),
  //             if (!_loadingLignes)
  //               Text(
  //                 '${_lignesVip.length} lignes',
  //                 style: TextStyle(
  //                   color: c.homeAccent,
  //                   fontSize: w * 0.027,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //           ],
  //         ),
  //         SizedBox(height: w * 0.02),
  //         Row(
  //           children: [
  //             Text(
  //               'Voyagez en première classe',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w900,
  //                 height: 1.15,
  //                 letterSpacing: -0.8,
  //               ),
  //             ),
  //             const Spacer(),
  //             IconButton(
  //               onPressed: () => setState(() {
  //                 _departVip = null;
  //                 _destVip = null;
  //                 _sectionActive = null;
  //               }),
  //               icon: Icon(
  //                 Icons.refresh_rounded,
  //                 color: _vipGreen,
  //                 size: w * 0.05,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: w * 0.010),
  //         if (_loadingLignes)
  //           Center(
  //             child: Padding(
  //               padding: EdgeInsets.symmetric(vertical: w * 0.04),
  //               child: CircularProgressIndicator(
  //                 color: _vipGreen,
  //                 strokeWidth: 1,
  //               ),
  //             ),
  //           )
  //         else if (_lignesVip.isEmpty)
  //           Padding(
  //             padding: EdgeInsets.symmetric(vertical: w * 0.04),
  //             child: Text(
  //               'Aucune ligne VIP disponible',
  //               style: TextStyle(
  //                 color: _vipGreen.withValues(alpha: 0.5),
  //                 fontSize: w * 0.035,
  //               ),
  //             ),
  //           )
  //         else ...[
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildDropdown(
  //                   hint: 'Départ',
  //                   value: _departVip,
  //                   items: _departsVip,
  //                   accentColor: _vipGreen,
  //                   enabled: _sectionActive == null || _sectionActive == 'vip',
  //                   onChanged: (val) => setState(() {
  //                     _departVip = val;
  //                     _destVip = null;
  //                     _sectionActive = val != null ? 'vip' : null;
  //                   }),
  //                   dark: true,
  //                 ),
  //               ),
  //               SizedBox(width: w * 0.01),
  //               Expanded(
  //                 child: _buildDropdown(
  //                   hint: 'Destination',
  //                   value: _destVip,
  //                   items: destsVip,
  //                   accentColor: _vipGreen,
  //                   enabled: _sectionActive == 'vip' && _departVip != null,
  //                   onChanged: (val) => setState(() => _destVip = val),
  //                   dark: true,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: w * 0.02),
  //           SizedBox(
  //             width: double.infinity,
  //             height: w * 0.10,
  //             child: ElevatedButton(
  //               onPressed: (canReserve && !_loadingVip)
  //                   ? () => _reserver(
  //                       depart: _departVip!,
  //                       destination: _destVip!,
  //                       type: 'vip',
  //                       setLoading: (v) => setState(() => _loadingVip = v),
  //                     )
  //                   : null,
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: _vipGreen,
  //                 disabledBackgroundColor: _vipGreen.withValues(alpha: 0.25),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(w * 0.035),
  //                 ),
  //                 elevation: 0,
  //               ),
  //               child: _loadingVip
  //                   ? SizedBox(
  //                       width: w * 0.055,
  //                       height: w * 0.055,
  //                       child: const CircularProgressIndicator(
  //                         strokeWidth: 2.5,
  //                         color: _vipGreen,
  //                       ),
  //                     )
  //                   : Text(
  //                       'Réserver VIP',
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w800,
  //                         fontSize: w * 0.038,
  //                         letterSpacing: 0.3,
  //                       ),
  //                     ),
  //             ),
  //           ),
  //         ],
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStdSection(BuildContext context) {
    final c = Config.colors;
    final w = MediaQuery.of(context).size.width;
    final destsStd = _destsStd(_departStd);
    final bool canReserve = _departStd != null && _destStd != null;
    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.020, w * 0.03, w * 0.020, w * 0.02),
      decoration: BoxDecoration(
        // color: c.homeBordurePetiteCarte.withValues(alpha: 0.20),
        color: c.homeBordurePetiteCarte.withAlpha(20),
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: c.homeTabSelected, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(w * 0.020),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.025,
                  vertical: w * 0.005,
                ),
                decoration: BoxDecoration(
                  color: c.homeButtonPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: c.homeButtonPrimary.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_bus_filled_rounded,
                      color: c.homeButtonPrimary,
                      size: w * 0.040,
                    ),
                    SizedBox(width: w * 0.015),
                    Text(
                      'Voyages Ordinaires',
                      style: TextStyle(
                        color: c.homeButtonPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: w * 0.032,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!_loadingLignes)
                Text(
                  '${_lignesStd.length} lignes',
                  style: TextStyle(
                    color: c.homeButtonPrimary.withValues(alpha: 0.7),
                    fontSize: w * 0.027,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: w * 0.02),
          Row(
            children: [
              Text(
                'Votre voyage , notre priorité',
                style: TextStyle(
                  color: c.homeTextPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() {
                  _departStd = null;
                  _destStd = null;
                  _sectionActive = null;
                }),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: c.homeTextPrimary.withValues(alpha: 0.7),
                  size: w * 0.05,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.010),
          if (_loadingLignes)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: w * 0.04),
                child: CircularProgressIndicator(
                  color: c.homeButtonPrimary,
                  strokeWidth: 1,
                ),
              ),
            )
          else if (_lignesStd.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: w * 0.04),
              child: Text(
                'Aucune ligne disponible',
                style: TextStyle(
                  color: c.homeTextPrimary.withValues(alpha: 0.5),
                  fontSize: w * 0.035,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    hint: 'Départ',
                    value: _departStd,
                    items: _departsStd,
                    accentColor: c.homeButtonPrimary,
                    enabled: _sectionActive == null || _sectionActive == 'std',
                    onChanged: (val) => setState(() {
                      _departStd = val;
                      _destStd = null;
                      _sectionActive = val != null ? 'std' : null;
                    }),
                    dark: false,
                  ),
                ),
                SizedBox(width: w * 0.01),
                Expanded(
                  child: _buildDropdown(
                    hint: 'Destination',
                    value: _destStd,
                    items: destsStd,
                    accentColor: c.homeButtonPrimary,
                    enabled: _sectionActive == 'std' && _departStd != null,
                    onChanged: (val) => setState(() => _destStd = val),
                    dark: false,
                  ),
                ),
              ],
            ),
            SizedBox(height: w * 0.02),
            SizedBox(
              width: double.infinity,
              height: w * 0.10,
              child: ElevatedButton(
                onPressed: (canReserve && !_loadingStd)
                    ? () => _reserver(
                        depart: _departStd!,
                        destination: _destStd!,
                        type: 'standard',
                        setLoading: (v) => setState(() => _loadingStd = v),
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.homeButtonPrimary,
                  disabledBackgroundColor: c.homeButtonPrimary.withValues(
                    alpha: 0.65,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.035),
                  ),
                  elevation: 0,
                ),
                child: _loadingStd
                    ? SizedBox(
                        width: w * 0.055,
                        height: w * 0.055,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: c.authAccent,
                        ),
                      )
                    : Text(
                        'Réserver',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: w * 0.038,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Color accentColor,
    required void Function(String?) onChanged,
    bool enabled = true,
    bool dark = false,
  }) {
    final c = Config.colors;
    final w = MediaQuery.of(context).size.width;
    final Color bgColor = dark
        ? Colors.white.withValues(alpha: 0.07)
        : c.homeBackground;
    final Color textColor = c.homeTextPrimary;
    final Color borderColor = enabled
        ? accentColor.withValues(alpha: 0.50)
        : (c.homeTextPrimary.withValues(alpha: 0.15));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: TextStyle(
              color: (c.homeTextPrimary).withValues(alpha: 0.50),
              fontSize: w * 0.033,
            ),
          ),
          value: value,
          isExpanded: true,
          dropdownColor: c.homeCardBackground,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled
                ? accentColor
                : (c.homeTextPrimary.withValues(alpha: 0.30)),
          ),
          style: TextStyle(
            color: textColor,
            fontSize: w * 0.035,
            fontWeight: FontWeight.w600,
          ),
          onChanged: enabled ? onChanged : null,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHeroBand(BuildContext context) {
    final c = Config.colors;
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: double.infinity,
      color: c.homeButtonPrimary.withValues(alpha: 0.07),
      padding: EdgeInsets.fromLTRB(w * 0.052, w * 0.010, w * 0.052, w * 0.005),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.025,
              vertical: w * 0.01,
            ),
            decoration: BoxDecoration(
              color: c.homeButtonPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: c.homeButtonPrimary.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus_filled_rounded,
                  color: c.homeButtonPrimary,
                  size: w * 0.033,
                ),
                SizedBox(width: w * 0.015),
                Text(
                  'MVST — Transport Interurbain',
                  style: TextStyle(
                    color: c.homeButtonPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.028,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            'Où allez-vous aujourd\'hui ?',
            style: TextStyle(
              color: c.homeTextPrimary,
              fontWeight: FontWeight.w900,
              fontSize: w * 0.055,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }
}
