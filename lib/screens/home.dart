import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/auth_service.dart';
import 'package:mvst/mes_services/mesFonctions.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/profil/profil.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/screens/carousel.dart';
import 'package:mvst/screens/cartes_lignes_trajets.dart';
import 'package:mvst/screens/conditionsDutilisation.dart';
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/home_vip.dart';
import 'package:mvst/screens/tableauDesTickets.dart';

// ── Couleurs VIP figées (indépendantes du thème) ───────────────────────────
const Color _kVipCard = Color(0xFF11111F);
const Color _kVipGold = Color(0xFFFFD700);
const Color _kVipGoldDim = Color(0xFFB8860B);

Map<String, List<String>> _groupByDepart(List<Map<String, String>> routes) {
  final Map<String, List<String>> grouped = {};
  for (final r in routes) {
    grouped.putIfAbsent(r['depart']!, () => []).add(r['destination']!);
  }
  return grouped;
}

// ════════════════════════════════════════════════════════════════════════════
class Home extends StatefulWidget {
  const Home({super.key, this.ongletInitial = 0});
  final int ongletInitial;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _currentUser;
  String _nomUtilisateur = '';
  String _prenomsUtilisateur = '';
  List<Map<String, String>> _lignesStandard = [];
  List<Map<String, String>> _lignesVip = [];
  bool _loadingLignes = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.ongletInitial,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    BlocProvider.of<BlocCompteur>(context).add(EventInitialise());
    _chargerLignes();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() => _currentUser = user);
        if (user != null) _chargerNomEtPrenoms(user.uid);
      }
    });
  }

  Future<void> _onReserverVip(String depart, String destination) async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/verifierUtilisateur.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idUtilisateur': user.uid}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 || !mounted) return;
      final data = json.decode(res.body);
      if (data['success'] == false) return;
      if ((data['points'] ?? 0) == 0) {
        final c = Config.colors;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: c.homeCardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
        return;
      }
      final prixRes = await http
          .post(
            Uri.parse('$kBaseUrl/getPrixDesTickets.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'type': 'vip'}),
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
      if (prix == null || !mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Commande(
            idUtilisateur: user.uid,
            nom: data['nom'] ?? '',
            prenoms: data['prenoms'] ?? '',
            telephone: data['telephone'] ?? '',
            prixDuBillet: prix,
            depart: depart,
            destination: destination,
            typeVoyage: 'vip',
            ongletOrigine: 2,
          ),
        ),
      );
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  Future<void> _chargerNomEtPrenoms(String uid) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/verifierUtilisateur.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idUtilisateur': uid}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _nomUtilisateur = data['nom'] ?? '';
            _prenomsUtilisateur = data['prenoms'] ?? '';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _chargerLignes() async {
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/api_lignes.php?type=all'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          final lignes = List<Map<String, dynamic>>.from(data['lignes']);
          final standard = lignes
              .where((l) => l['type'] == 'standard')
              .map(
                (l) => {
                  'depart': l['depart'].toString(),
                  'destination': l['destination'].toString(),
                },
              )
              .toList();
          final vip = lignes
              .where((l) => l['type'] == 'vip')
              .map(
                (l) => {
                  'depart': l['depart'].toString(),
                  'destination': l['destination'].toString(),
                },
              )
              .toList();
          setState(() {
            _lignesStandard = standard;
            _lignesVip = vip;
            _loadingLignes = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLignes = false);
    }
  }

  Future<void> _recharger() async {
    await _chargerLignes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _initiales() {
    final n = _nomUtilisateur.isNotEmpty
        ? _nomUtilisateur[0].toUpperCase()
        : '';
    final p = _prenomsUtilisateur.isNotEmpty
        ? _prenomsUtilisateur[0].toUpperCase()
        : '';
    if (n.isNotEmpty && p.isNotEmpty) return '$n$p';
    if (n.isNotEmpty) return n;
    final dn = _currentUser?.displayName?.trim();
    if (dn != null && dn.isNotEmpty) {
      final parts = dn.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccueil(context),
          _currentUser != null
              ? MesTickets(idUtilisateur: _currentUser!.uid)
              : const Login(),
          _currentUser != null ? _buildAccueilVip(context) : const Login(),
          _currentUser != null
              ? TableauDeTickets(idUtilisateur: _currentUser!.uid)
              : const Login(),
          Informations(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = Config.colors;
    return AppBar(
      backgroundColor: c.authButtonDisabled,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: c.homeAccent),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'MVST',
        style: TextStyle(
          color: c.homeBandeauBorder,
          fontFamily: 'Lobster',
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () {
              if (AuthService.estConnecte()) {
                final u = AuthService.getUtilisateur()!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Profil(
                      idUtilisateur: u.uid,
                      userProfil: u.displayName ?? '',
                    ),
                  ),
                );
              } else {
                AuthService.afficherSnackNonConnecte(context);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.homeAccent.withValues(alpha: 0.70),
                  width: 1.0,
                ),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: c.homeBandeauBorder.withValues(alpha: 0.20),
                child: _currentUser != null
                    ? Text(
                        _initiales(),
                        style: TextStyle(
                          fontFamily: 'Lobster',
                          color: c.couleurInitiales,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      )
                    : Icon(
                        Icons.person_outline,
                        color: c.homeButtonPrimary,
                        size: 19,
                      ),
              ),
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: c.homeTextPrimary.withValues(alpha: 0.07),
        ),
      ),
    );
  }

  // ── Onglet Standard ──────────────────────────────────────────────────────
  Widget _buildAccueil(BuildContext context) {
    final c = Config.colors;
    final double w = MediaQuery.of(context).size.width;
    final grouped = _groupByDepart(_lignesStandard);

    return Container(
      color: c.homeBackground,
      child: RefreshIndicator(
        color: c.homeButtonPrimary,
        onRefresh: _recharger,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const PromoStripWidget(),
            _buildHeroBand(context, isVip: false),

            Padding(
              padding: EdgeInsets.fromLTRB(
                w * 0.052,
                w * 0.041,
                w * 0.052,
                w * 0.010,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choisir un itinéraire',
                    style: TextStyle(
                      color: c.homeTextPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: w * 0.043,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (!_loadingLignes)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.026,
                        vertical: w * 0.010,
                      ),
                      decoration: BoxDecoration(
                        color: c.homeButtonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(w * 0.051),
                      ),
                      child: Text(
                        '${_lignesStandard.length} lignes',
                        style: TextStyle(
                          color: c.homeButtonPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: w * 0.028,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_loadingLignes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: c.homeButtonPrimary),
                ),
              )
            else if (_lignesStandard.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Aucune ligne disponible',
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.5),
                      fontSize: w * 0.038,
                    ),
                  ),
                ),
              )
            else
              ...grouped.entries.map(
                (e) => _buildOriginGroup(
                  context,
                  depart: e.key,
                  destinations: e.value,
                  typeVoyage: 'standard',
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Onglet VIP ────────────────────────────────────────────────────────────
  Widget _buildAccueilVip(BuildContext context) {
    if (_loadingLignes) {
      return Center(child: CircularProgressIndicator(color: _kVipGold));
    }
    return RefreshIndicator(
      color: _kVipGold,
      onRefresh: _recharger,
      child: HomeVip(onReserver: _onReserverVip, routes: _lignesVip),
    );
  }

  // ── Bandeau héro ─────────────────────────────────────────────────────────
  Widget _buildHeroBand(BuildContext context, {required bool isVip}) {
    final c = Config.colors;
    final double w = MediaQuery.of(context).size.width;

    final Color bg = isVip
        ? _kVipCard
        : c.homeButtonPrimary.withValues(alpha: 0.07);
    final Color titleColor = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color textColor = isVip ? Colors.white : c.homeTextPrimary;

    final List<_Pill> pills = const [
      _Pill('⚡ Temps réel', ''),
      _Pill('🎫 QR Code', ''),
    ];

    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.fromLTRB(w * 0.052, w * 0.056, w * 0.052, w * 0.065),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: titleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: titleColor.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVip
                      ? Icons.airline_seat_recline_extra
                      : Icons.directions_bus_filled_rounded,
                  color: titleColor,
                  size: w * 0.033,
                ),
                const SizedBox(width: 2),
                Text(
                  isVip
                      ? 'MVST VIP — Voyage Premium'
                      : 'MVST — Transport Interurbain',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.028,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.02),

          Text(
            isVip
                ? 'Voyagez\nen première classe'
                : 'Où allez-\nvous aujourd\'hui ?',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: w * 0.055,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: w * 0.04),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: pills
                      .map((p) => _buildHeroPill(p.label, titleColor, w))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill(String label, Color color, double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.026, vertical: w * 0.015),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.077),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: w * 0.031,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── Groupe par ville de départ ────────────────────────────────────────────
  Widget _buildOriginGroup(
    BuildContext context, {
    required String depart,
    required List<String> destinations,
    required String typeVoyage,
  }) {
    final c = Config.colors;
    final double w = MediaQuery.of(context).size.width;
    final bool isVip = typeVoyage == 'vip';

    final Color dotColor = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color cardBg = isVip ? _kVipCard : c.homeCardBackground;
    final Color cardBorder = isVip
        ? _kVipGoldDim.withValues(alpha: 0.3)
        : c.homeBordurePetiteCarte;
    final Color dividerColor = isVip
        ? _kVipGoldDim.withValues(alpha: 0.18)
        : c.homeTextPrimary.withValues(alpha: 0.07);

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.042, 0, w * 0.042, w * 0.036),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: w * 0.005, bottom: w * 0.020),
            child: Row(
              children: [
                Container(
                  width: w * 0.018,
                  height: w * 0.018,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: w * 0.020),
                Text(
                  depart == 'Abidjan'
                      ? "A partir d'${depart.toUpperCase()}"
                      : "A partir de ${depart.toUpperCase()}",
                  style: TextStyle(
                    color: dotColor,
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.027,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(w * 0.042),
              border: Border.all(color: cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: isVip
                      ? _kVipGold.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.042),
              child: Column(
                children: List.generate(destinations.length, (i) {
                  final isLast = i == destinations.length - 1;
                  return Column(
                    children: [
                      CartesLignesTrajets(
                        depart: depart,
                        destination: destinations[i],
                        typeVoyage: typeVoyage,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: dividerColor,
                          indent: w * 0.155,
                          endIndent: w * 0.042,
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final c = Config.colors;
    final double fontSize = MediaQuery.of(context).size.width * 0.027;
    final Color vertVIP = const Color.fromARGB(255, 2, 136, 80);

    return BottomAppBar(
      color: c.homeCardBackground,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: c.authButtonDisabled.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: Center(
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            controller: _tabController,
            labelStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w400,
            ),
            labelColor: c.homeTabSelected,
            unselectedLabelColor: c.homeTabUnselected,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _tabController.index == 2
                      ? vertVIP
                      : c.homeButtonPrimary,
                  width: 2.5,
                ),
              ),
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                icon: Icon(
                  _tabController.index == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  size: 22,
                  color: _tabController.index == 0
                      ? c.homeTabSelected
                      : c.homeTabUnselected,
                ),
                text: 'Accueil',
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 1
                      ? Icons.receipt_rounded
                      : Icons.receipt_outlined,
                  size: 22,
                  color: _tabController.index == 1
                      ? c.homeTabSelected
                      : c.homeTabUnselected,
                ),
                text: 'Tickets',
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 2
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 22,
                  color: _tabController.index == 2
                      ? vertVIP
                      : c.homeTabUnselected,
                ),
                child: Text(
                  'VIP',
                  style: TextStyle(
                    color: _tabController.index == 2
                        ? vertVIP
                        : c.homeTabUnselected,
                    fontSize: fontSize,
                    fontWeight: _tabController.index == 2
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 3
                      ? Icons.history_rounded
                      : Icons.history_outlined,
                  size: 22,
                  color: _tabController.index == 3
                      ? c.homeTabSelected
                      : c.homeTabUnselected,
                ),
                text: 'Historique',
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 4
                      ? Icons.info_rounded
                      : Icons.info_outlined,
                  size: 22,
                  color: _tabController.index == 4
                      ? c.homeTabSelected
                      : c.homeTabUnselected,
                ),
                text: 'Infos',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer ────────────────────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final c = Config.colors;
    return Drawer(
      backgroundColor: c.authButtonDisabled,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.homeHeaderTop, c.homeHeaderBottom],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.homeAccent, width: 1.5),
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              'MVST',
                              style: TextStyle(
                                color: c.homeAccent,
                                fontSize: 18,
                                fontFamily: 'Lobster',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Mieux Vous Servir Transport',
                          style: TextStyle(color: c.homeAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.perm_identity_outlined,
                  label: 'Profil',
                  onTap: () {
                    if (AuthService.estConnecte()) {
                      final u = AuthService.getUtilisateur()!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Profil(
                            idUtilisateur: u.uid,
                            userProfil: u.displayName ?? '',
                          ),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                      AuthService.afficherSnackNonConnecte(context);
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notification_add_outlined,
                  label: 'Notification',
                  onTap: () {
                    if (!AuthService.estConnecte()) {
                      Navigator.pop(context);
                      AuthService.afficherSnackNonConnecte(context);
                    }
                    // TODO: Ouvrir page Notification quand elle sera créée
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Termes et Conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConditionsDUtilisation(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.lightbulb_outlined,
                  label: 'Suggestions',
                  onTap: () async {
                    if (AuthService.estConnecte()) {
                      final uid = AuthService.getUid()!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Suggestions(idUtilisateur: uid),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                      AuthService.afficherSnackNonConnecte(context);
                    }
                  },
                ),
                _buildThemeSelector(context),
                Divider(
                  color: Colors.white.withValues(alpha: 0.15),
                  thickness: 1,
                ),
                _buildDrawerItem(
                  icon: _currentUser != null
                      ? Icons.power_settings_new
                      : Icons.login_rounded,
                  label: _currentUser != null ? 'Déconnexion' : 'Se connecter',
                  onTap: _currentUser != null
                      ? () => _deconnexion(context)
                      : () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                          );
                        },
                  isDestructive: _currentUser != null,
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.15), thickness: 1),
          _buildDrawerItem(
            icon: Icons.info_outlined,
            label: 'À propos du développeur',
            onTap: () {},
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themes = [
      {
        'mode': AppThemeMode.blue,
        'label': 'Bleu',
        'color': const Color(0xFF1565C0),
      },
      {
        'mode': AppThemeMode.green,
        'label': 'Vert',
        'color': const Color(0xFF1B6B41),
      },
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thème',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: themes.map((t) {
              final bool isActive = Config.activeTheme == t['mode'];
              return GestureDetector(
                onTap: () {
                  final mode = t['mode'] as AppThemeMode;
                  setState(() => Config.activeTheme = mode);
                  Config.sauvegarderTheme(mode);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (t['color'] as Color)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? (t['color'] as Color)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: t['color'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t['label'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? Colors.redAccent
        : Colors.white.withValues(alpha: 0.85);
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(color: color, fontFamily: 'Lobster', fontSize: 15),
      ),
      onTap: onTap,
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────
class _Pill {
  const _Pill(this.label, this.sub);
  final String label;
  final String sub;
}

void _deconnexion(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
    (route) => false,
  );
}
