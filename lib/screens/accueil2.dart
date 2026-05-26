// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mvst/authentification/connection.dart';
// import 'package:mvst/config/config.dart';
// import 'package:mvst/mes_services/mesFonctions.dart';
// import 'package:mvst/models/models.dart';
// import 'package:mvst/screens/commande.dart';

// const Color _vipGold = Color(0xFFFFD700);
// const Color _vipGoldDim = Color(0xFFB8860B);
// const Color _vipBg = Color(0xFF11111F);
// const Color _vipGreen = Color(0xFF00D87E);
// const Color _vipGreenDark = Color(0xFF019A5A);

// class Accueil2 extends StatefulWidget {
//   const Accueil2({super.key});

//   @override
//   State<Accueil2> createState() => _Accueil2State();
// }

// class _Accueil2State extends State<Accueil2> {
//   // Listes des villes
//   List<String> _villesStandard = [];
//   List<String> _villesVip = [];

//   // Lignes complètes pour vérification de trajet valide
//   List<Map<String, dynamic>> _lignesStandard = [];
//   List<Map<String, dynamic>> _lignesVip = [];

//   // Sélections Standard
//   String? _departStandard;
//   String? _destinationStandard;

//   // Sélections VIP
//   String? _departVip;
//   String? _destinationVip;

//   bool _loadingLignes = true;
//   bool _loadingReservationStandard = false;
//   bool _loadingReservationVip = false;

//   @override
//   void initState() {
//     super.initState();
//     _chargerLignes();
//   }

//   Future<void> _chargerLignes() async {
//     setState(() => _loadingLignes = true);
//     try {
//       final res = await http
//           .get(Uri.parse('$kBaseUrl/api_lignes.php?type=all'))
//           .timeout(const Duration(seconds: 10));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == true && mounted) {
//           final lignes = List<Map<String, dynamic>>.from(data['lignes']);

//           final standard = lignes
//               .where((l) => l['type'] == 'standard')
//               .toList();
//           final vip = lignes.where((l) => l['type'] == 'vip').toList();

//           // Extraire les villes uniques
//           final villesStd = <String>{};
//           for (final l in standard) {
//             villesStd.add(l['depart'].toString());
//             villesStd.add(l['destination'].toString());
//           }
//           final villesVip = <String>{};
//           for (final l in vip) {
//             villesVip.add(l['depart'].toString());
//             villesVip.add(l['destination'].toString());
//           }

//           setState(() {
//             _lignesStandard = standard;
//             _lignesVip = vip;
//             _villesStandard = villesStd.toList()..sort();
//             _villesVip = villesVip.toList()..sort();
//             _loadingLignes = false;
//           });
//         }
//       }
//     } catch (_) {
//       if (mounted) setState(() => _loadingLignes = false);
//     }
//   }

//   bool _trajetValide(
//     List<Map<String, dynamic>> lignes,
//     String depart,
//     String destination,
//   ) {
//     return lignes.any(
//       (l) =>
//           l['depart'].toString() == depart &&
//           l['destination'].toString() == destination,
//     );
//   }

//   Future<Map<String, dynamic>?> _verifierUtilisateur() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return null;
//     try {
//       final res = await http
//           .post(
//             Uri.parse('$kBaseUrl/verifierUtilisateur.php'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({'idUtilisateur': user.uid}),
//           )
//           .timeout(const Duration(seconds: 10));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == false) return null;
//         final int points = data['points'] ?? 0;
//         if (points == 0) {
//           if (mounted) _showRestrictedDialog();
//           return null;
//         }
//         return {
//           'nom': data['nom'] ?? '',
//           'prenoms': data['prenoms'] ?? '',
//           'telephone': data['telephone'] ?? '',
//         };
//       }
//     } catch (_) {}
//     return null;
//   }

//   Future<int?> _getPrix(String depart, String destination, String type) async {
//     try {
//       final res = await http
//           .post(
//             Uri.parse('$kBaseUrl/getPrixDesTickets.php'),
//             headers: {'Content-Type': 'application/json'},
//             body: json.encode({'type': type}),
//           )
//           .timeout(const Duration(seconds: 10));
//       if (res.statusCode == 200) {
//         final data = json.decode(res.body);
//         if (data['success'] == true) {
//           prixDesBillets.clear();
//           for (final item in List<Map<String, dynamic>>.from(data['heures'])) {
//             prixDesBillets[item['axe']] = item['prix'];
//           }
//           return prixDesBillets['$depart $destination'];
//         }
//       }
//     } catch (_) {}
//     return null;
//   }

//   Future<void> _reserver(String type) async {
//     final depart = type == 'vip' ? _departVip : _departStandard;
//     final destination = type == 'vip' ? _destinationVip : _destinationStandard;

//     if (depart == null || destination == null) return;

//     if (FirebaseAuth.instance.currentUser == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const Login()),
//       );
//       return;
//     }

//     setState(() {
//       if (type == 'vip') {
//         _loadingReservationVip = true;
//       } else {
//         _loadingReservationStandard = true;
//       }
//     });

//     try {
//       final userData = await _verifierUtilisateur();
//       if (userData == null) return;

//       final prix = await _getPrix(depart, destination, type);
//       if (prix == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Prix non disponible pour ce trajet.'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//         return;
//       }

//       if (!mounted) return;
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => Commande(
//             idUtilisateur: FirebaseAuth.instance.currentUser!.uid,
//             nom: userData['nom'],
//             prenoms: userData['prenoms'] ?? '',
//             telephone: userData['telephone'],
//             prixDuBillet: prix,
//             depart: depart,
//             destination: destination,
//             typeVoyage: type,
//             ongletOrigine: 0,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (mounted) afficherErreur(context, e);
//     } finally {
//       if (mounted) {
//         setState(() {
//           if (type == 'vip') {
//             _loadingReservationVip = false;
//           } else {
//             _loadingReservationStandard = false;
//           }
//         });
//       }
//     }
//   }

//   void _showRestrictedDialog() {
//     final c = Config.colors;
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         backgroundColor: c.homeCardBackground,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             const Icon(Icons.warning_amber_rounded, color: Colors.orange),
//             const SizedBox(width: 8),
//             Text(
//               'Accès restreint',
//               style: TextStyle(
//                 color: c.homeTextPrimary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         content: Text(
//           'Votre profil est soumis à une restriction.\nVeuillez contacter l\'administrateur MVST Mobile.',
//           style: TextStyle(color: c.homeTextPrimary.withValues(alpha: 0.8)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             child: const Text(
//               'OK',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final c = Config.colors;
//     final w = MediaQuery.of(context).size.width;

//     return RefreshIndicator(
//       color: c.homeButtonPrimary,
//       onRefresh: _chargerLignes,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: EdgeInsets.zero,
//         children: [
//           if (_loadingLignes)
//             SizedBox(
//               height: 300,
//               child: Center(
//                 child: CircularProgressIndicator(color: c.homeButtonPrimary),
//               ),
//             )
//           else ...[
//             // ── Bloc VIP ───────────────────────────────────────────
//             _buildBlocVip(w),
//             SizedBox(height: w * 0.05),
//             // ── Bloc Standard ──────────────────────────────────────
//             _buildBlocStandard(c, w),
//             SizedBox(height: w * 0.08),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── BLOC VIP ────────────────────────────────────────────────────────────
//   Widget _buildBlocVip(double w) {
//     final trajetOk =
//         _departVip != null &&
//         _destinationVip != null &&
//         _trajetValide(_lignesVip, _departVip!, _destinationVip!);

//     final destinationsVip = _villesVip.where((v) => v != _departVip).toList();

//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF091A0E), Color(0xFF0F2E18), Color(0xFF061009)],
//           stops: [0.0, 0.55, 1.0],
//         ),
//       ),
//       padding: EdgeInsets.fromLTRB(w * 0.055, w * 0.07, w * 0.055, w * 0.07),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Badge VIP
//           Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: w * 0.030,
//               vertical: w * 0.012,
//             ),
//             decoration: BoxDecoration(
//               color: _vipGreen.withValues(alpha: 0.10),
//               borderRadius: BorderRadius.circular(w * 0.075),
//               border: Border.all(
//                 color: _vipGreen.withValues(alpha: 0.30),
//                 width: 0.9,
//               ),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   Icons.airline_seat_recline_extra,
//                   color: _vipGreen,
//                   size: w * 0.033,
//                 ),
//                 SizedBox(width: w * 0.018),
//                 Text(
//                   'MVST VIP — Voyage Premium',
//                   style: TextStyle(
//                     color: _vipGreen,
//                     fontWeight: FontWeight.w700,
//                     fontSize: w * 0.029,
//                     letterSpacing: 0.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           SizedBox(height: w * 0.025),

//           Text(
//             'Voyagez en\npremière classe',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: w * 0.057,
//               height: 1.15,
//               letterSpacing: -0.8,
//             ),
//           ),

//           SizedBox(height: w * 0.02),

//           // Ligne or décorative
//           Row(
//             children: [
//               Container(
//                 width: w * 0.08,
//                 height: 2,
//                 decoration: BoxDecoration(
//                   color: _vipGold,
//                   borderRadius: BorderRadius.circular(1),
//                 ),
//               ),
//               SizedBox(width: w * 0.015),
//               Container(
//                 width: w * 0.025,
//                 height: 2,
//                 decoration: BoxDecoration(
//                   color: _vipGold.withValues(alpha: 0.4),
//                   borderRadius: BorderRadius.circular(1),
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(height: w * 0.05),

//           // Dropdowns VIP sur la même ligne
//           Row(
//             children: [
//               Expanded(
//                 child: _buildDropdown(
//                   hint: 'Départ',
//                   value: _departVip,
//                   items: _villesVip,
//                   isVip: true,
//                   onChanged: (val) => setState(() {
//                     _departVip = val;
//                     if (_destinationVip == val) _destinationVip = null;
//                   }),
//                 ),
//               ),
//               SizedBox(width: w * 0.03),
//               Expanded(
//                 child: _buildDropdown(
//                   hint: 'Destination',
//                   value: destinationsVip.contains(_destinationVip)
//                       ? _destinationVip
//                       : null,
//                   items: destinationsVip,
//                   isVip: true,
//                   onChanged: _departVip == null
//                       ? null
//                       : (val) => setState(() => _destinationVip = val),
//                 ),
//               ),
//             ],
//           ),

//           // Avertissement trajet invalide
//           if (_departVip != null && _destinationVip != null && !trajetOk) ...[
//             SizedBox(height: w * 0.03),
//             Row(
//               children: [
//                 Icon(Icons.info_outline, color: _vipGold, size: 14),
//                 SizedBox(width: w * 0.02),
//                 Text(
//                   'Trajet non disponible en VIP',
//                   style: TextStyle(color: _vipGold, fontSize: w * 0.030),
//                 ),
//               ],
//             ),
//           ],

//           // Bouton Réserver VIP
//           if (trajetOk) ...[
//             SizedBox(height: w * 0.05),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _loadingReservationVip
//                     ? null
//                     : () => _reserver('vip'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _vipGreen,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: w * 0.038),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(w * 0.035),
//                   ),
//                 ),
//                 child: _loadingReservationVip
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2.5,
//                         ),
//                       )
//                     : Text(
//                         'Réserver — $_departVip → $_destinationVip',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: w * 0.036,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── BLOC STANDARD ────────────────────────────────────────────────────────
//   Widget _buildBlocStandard(dynamic c, double w) {
//     final trajetOk =
//         _departStandard != null &&
//         _destinationStandard != null &&
//         _trajetValide(_lignesStandard, _departStandard!, _destinationStandard!);

//     final destinationsStandard = _villesStandard
//         .where((v) => v != _departStandard)
//         .toList();

//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: w * 0.05),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Titre Standard
//           Row(
//             children: [
//               Container(
//                 width: w * 0.008,
//                 height: w * 0.05,
//                 decoration: BoxDecoration(
//                   color: c.homeButtonPrimary,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(width: w * 0.025),
//               Text(
//                 'Transport Standard',
//                 style: TextStyle(
//                   color: c.homeTextPrimary,
//                   fontWeight: FontWeight.w800,
//                   fontSize: w * 0.044,
//                   letterSpacing: -0.4,
//                 ),
//               ),
//             ],
//           ),

//           SizedBox(height: w * 0.01),

//           Padding(
//             padding: EdgeInsets.only(left: w * 0.033),
//             child: Text(
//               'Confortable · Ponctuel · Accessible',
//               style: TextStyle(
//                 color: c.homeTextPrimary.withValues(alpha: 0.5),
//                 fontSize: w * 0.030,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ),

//           SizedBox(height: w * 0.05),

//           // Dropdowns Standard sur la même ligne
//           Row(
//             children: [
//               Expanded(
//                 child: _buildDropdown(
//                   hint: 'Départ',
//                   value: _departStandard,
//                   items: _villesStandard,
//                   isVip: false,
//                   onChanged: (val) => setState(() {
//                     _departStandard = val;
//                     if (_destinationStandard == val) {
//                       _destinationStandard = null;
//                     }
//                   }),
//                 ),
//               ),
//               SizedBox(width: w * 0.03),
//               Expanded(
//                 child: _buildDropdown(
//                   hint: 'Destination',
//                   value: destinationsStandard.contains(_destinationStandard)
//                       ? _destinationStandard
//                       : null,
//                   items: destinationsStandard,
//                   isVip: false,
//                   onChanged: _departStandard == null
//                       ? null
//                       : (val) => setState(() => _destinationStandard = val),
//                 ),
//               ),
//             ],
//           ),

//           // Avertissement trajet invalide
//           if (_departStandard != null &&
//               _destinationStandard != null &&
//               !trajetOk) ...[
//             SizedBox(height: w * 0.03),
//             Row(
//               children: [
//                 Icon(Icons.info_outline, color: c.homeButtonPrimary, size: 14),
//                 SizedBox(width: w * 0.02),
//                 Text(
//                   'Trajet non disponible',
//                   style: TextStyle(
//                     color: c.homeButtonPrimary,
//                     fontSize: w * 0.030,
//                   ),
//                 ),
//               ],
//             ),
//           ],

//           // Bouton Réserver Standard
//           if (trajetOk) ...[
//             SizedBox(height: w * 0.05),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _loadingReservationStandard
//                     ? null
//                     : () => _reserver('standard'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: c.homeButtonPrimary,
//                   foregroundColor: Colors.white,
//                   padding: EdgeInsets.symmetric(vertical: w * 0.038),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(w * 0.035),
//                   ),
//                 ),
//                 child: _loadingReservationStandard
//                     ? const SizedBox(
//                         width: 22,
//                         height: 22,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2.5,
//                         ),
//                       )
//                     : Text(
//                         'Réserver — $_departStandard → $_destinationStandard',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w800,
//                           fontSize: w * 0.036,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   // ── DROPDOWN réutilisable ────────────────────────────────────────────────
//   Widget _buildDropdown({
//     required String hint,
//     required String? value,
//     required List<String> items,
//     required bool isVip,
//     required void Function(String?)? onChanged,
//   }) {
//     final borderColor = isVip
//         ? _vipGreen.withValues(alpha: 0.4)
//         : Colors.grey.shade300;
//     final bgColor = isVip
//         ? Colors.white.withValues(alpha: 0.07)
//         : Config.colors.homeCardBackground;
//     final textColor = isVip ? Colors.white : Config.colors.homeTextPrimary;
//     final hintColor = isVip
//         ? Colors.white.withValues(alpha: 0.4)
//         : Config.colors.homeTextPrimary.withValues(alpha: 0.4);
//     final iconColor = isVip ? _vipGreen : Config.colors.homeButtonPrimary;
//     final dropdownBg = isVip
//         ? const Color(0xFF0F2E18)
//         : Config.colors.homeCardBackground;

//     return Container(
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: borderColor, width: 1.5),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           isExpanded: true,
//           dropdownColor: dropdownBg,
//           icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 20),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           hint: Text(hint, style: TextStyle(color: hintColor, fontSize: 13)),
//           style: TextStyle(
//             color: textColor,
//             fontSize: 13,
//             fontWeight: FontWeight.w600,
//           ),
//           items: items
//               .map(
//                 (v) => DropdownMenuItem(
//                   value: v,
//                   child: Text(
//                     v,
//                     style: TextStyle(color: textColor, fontSize: 13),
//                   ),
//                 ),
//               )
//               .toList(),
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
// }
