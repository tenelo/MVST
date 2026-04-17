import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/profil/profil.dart';
import 'package:mvst/screens/commande.dart';
import 'package:mvst/screens/conditionsDutilisation.dart';
import 'package:mvst/screens/detailsImages.dart';
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/tableauDesTickets.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ── Couleurs VIP figées (indépendantes du thème) ───────────────────────────
const Color _kVipBg = Color(0xFF07070F);
const Color _kVipCard = Color(0xFF11111F);
const Color _kVipGold = Color(0xFFFFD700);
const Color _kVipGoldDim = Color(0xFFB8860B);

// ── Routes disponibles ─────────────────────────────────────────────────────
const List<Map<String, String>> _kRoutes = [
  {'depart': 'Ferké', 'destination': 'Abidjan'},
  {'depart': 'Ferké', 'destination': 'Bouaké'},
  {'depart': 'Bouaké', 'destination': 'Ferké'},
  {'depart': 'Bouaké', 'destination': 'Abidjan'},
  {'depart': 'Abidjan', 'destination': 'Ferké'},
  {'depart': 'Abidjan', 'destination': 'Bouaké'},
];

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
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Retourne les deux initiales (nom + prénom) ou une seule si mononyme.
  String _initiales(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) return 'U';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ── Build ────────────────────────────────────────────────────────────────
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
          _buildAccueilVip(context),
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
          //fontSize: 24,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () {
              if (_currentUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Profil(
                      idUtilisateur: _currentUser!.uid,
                      userProfil: _currentUser!.displayName ?? '',
                    ),
                  ),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.homeAccent.withValues(alpha: 0.70),
                  width: 1.0, // Ajuste l'épaisseur
                ),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: c.homeBandeauBorder.withValues(alpha: 0.20),
                child: _currentUser != null
                    ? Text(
                        _initiales(_currentUser!.displayName),
                        style: TextStyle(
                          fontFamily: 'Lobster',
                          color: c.couleurInitiales,
                          fontWeight: FontWeight.bold,
                          //sfontSize: 11,
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
    final grouped = _groupByDepart(_kRoutes);

    return Container(
      color: c.homeBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Carousel promos — tout en haut, directement sous l'AppBar
          const _PromoStrip(),
          _buildHeroBand(context, isVip: false),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.homeButtonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_kRoutes.length} lignes',
                    style: TextStyle(
                      color: c.homeButtonPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

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
    );
  }

  // ── Onglet VIP ────────────────────────────────────────────────────────────
  Widget _buildAccueilVip(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final grouped = _groupByDepart(_kRoutes);

    return Container(
      color: _kVipBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Carousel promos — tout en haut
          const _PromoStrip(isVip: true),
          _buildHeroBand(context, isVip: true),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Text(
                  '✦ ',
                  style: TextStyle(color: _kVipGold, fontSize: 14),
                ),
                Text(
                  'Lignes Classe VIP',
                  style: TextStyle(
                    color: _kVipGold,
                    fontWeight: FontWeight.w800,
                    fontSize: w * 0.043,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
            child: Text(
              'Sièges spacieux · Confort absolu · QR instantané',
              style: TextStyle(
                color: _kVipGoldDim.withValues(alpha: 0.75),
                fontSize: w * 0.030,
                letterSpacing: 0.3,
              ),
            ),
          ),

          ...grouped.entries.map(
            (e) => _buildOriginGroup(
              context,
              depart: e.key,
              destinations: e.value,
              typeVoyage: 'vip',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
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

    final List<_Pill> pills = isVip
        ? const [_Pill('★ Premium', ''), _Pill('🛋️ Grand confort', '')]
        : const [_Pill('⚡ Temps réel', ''), _Pill('🎫 QR Code', '')];

    return Container(
      width: double.infinity,
      color: bg,
      padding: EdgeInsets.fromLTRB(20, 22, 20, w * 0.065),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label badge
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
                  size: 13,
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

          // Titre principal
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

          // Pills caractéristiques
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: pills
                .map((p) => _buildHeroPill(p.label, titleColor))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête ville de départ
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              Text(
                  depart == 'Abidjan'
                      ? "A partir d'${depart.toUpperCase()}"
                      : "A partir de ${depart.toUpperCase()}",
                  style: TextStyle(
                    color: dotColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),

          // Carte contenant les lignes
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
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
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: List.generate(destinations.length, (i) {
                  final isLast = i == destinations.length - 1;
                  return Column(
                    children: [
                      _RouteRow(
                        depart: depart,
                        destination: destinations[i],
                        typeVoyage: typeVoyage,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: dividerColor,
                          indent: 60,
                          endIndent: 16,
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
                top: BorderSide(color: c.homeButtonPrimary, width: 2.5),
              ),
            ),
            dividerColor: Colors.transparent,
            tabs: [
              // Accueil
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
              // Tickets
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
              // VIP
              Tab(
                icon: Icon(
                  _tabController.index == 2
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 22,
                  color: _tabController.index == 2
                      ? _kVipGold
                      : c.homeTabUnselected,
                ),
                text: 'VIP',
              ),
              // Historique
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
              // Infos
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
                    if (FirebaseAuth.instance.currentUser != null) {
                      final u = FirebaseAuth.instance.currentUser!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Profil(
                            idUtilisateur: u.uid,
                            userProfil: u.displayName!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PageDAuthentification(),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.notification_add_outlined,
                  label: 'Notification',
                  onTap: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      Navigator.pop(context);
                      _showNonAuthSnack(context);
                    }
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
                    if (FirebaseAuth.instance.currentUser != null) {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Suggestions(idUtilisateur: uid),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                      _showNonAuthSnack(context);
                    }
                  },
                ),
                _buildThemeSelector(context),
                Divider(
                  color: Colors.white.withValues(alpha: 0.15),
                  thickness: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.power_settings_new,
                  label: 'Déconnexion',
                  onTap: () => _deconnexion(context),
                  isDestructive: true,
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

// ── Ligne de route  ───────────────────────────────────
class _RouteRow extends StatefulWidget {
  const _RouteRow({
    required this.depart,
    required this.destination,
    required this.typeVoyage,
  });
  final String depart;
  final String destination;
  final String typeVoyage;

  @override
  State<_RouteRow> createState() => _RouteRowState();
}

class _RouteRowState extends State<_RouteRow> {
  bool _loading = false;

  Future<Map<String, dynamic>?> _verifierUtilisateur() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final res = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/verifierUtilisateur.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idUtilisateur': user.uid}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == false) return null;
        final int points = data['points'] ?? 0;
        if (points == 0) {
          if (mounted) _showRestrictedDialog();
          return null;
        }
        return {'nom': data['nom'] ?? '', 'telephone': data['telephone'] ?? ''};
      }
    } catch (_) {}
    return null;
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

  Future<int?> _getPrix() async {
    try {
      final res = await http.post(
        Uri.parse('https://mvst.tenelo.cloud/getPrixDesTickets.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'type': widget.typeVoyage}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          prixDesBillets.clear();
          for (final item in List<Map<String, dynamic>>.from(data['heures'])) {
            prixDesBillets[item['axe']] = item['prix'];
          }
          return prixDesBillets['${widget.depart} ${widget.destination}'];
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _onTap() async {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final userData = await _verifierUtilisateur();
      if (userData == null) return;
      final prix = await _getPrix();
      if (prix == null) throw Exception('Prix non trouvé');
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Commande(
            idUtilisateur: FirebaseAuth.instance.currentUser!.uid,
            nom: userData['nom'],
            prenoms: '',
            telephone: userData['telephone'],
            prixDuBillet: prix,
            depart: widget.depart,
            destination: widget.destination,
            typeVoyage: widget.typeVoyage,
            ongletOrigine: widget.typeVoyage == 'vip' ? 2 : 0,
          ),
        ),
      );
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final bool isVip = widget.typeVoyage == 'vip';

    final Color accent = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color textColor = isVip ? Colors.white : c.homeTextPrimary;
    final Color subColor = isVip
        ? Colors.white38
        : c.homeTextPrimary.withValues(alpha: 0.4);
    final Color iconBg = accent.withValues(alpha: 0.10);
    final Color btnColor = isVip ? _kVipGold : c.homeButtonPrimary;

    return InkWell(
      onTap: _loading ? null : _onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            // Icône
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                isVip
                    ? Icons.airline_seat_recline_extra
                    : Icons.directions_bus_rounded,
                color: accent,
                size: 19,
              ),
            ),
            const SizedBox(width: 14),

            // Texte trajet
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.depart} → ${widget.destination}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ligne ${widget.depart} ${widget.destination}',
                    style: TextStyle(
                      color: subColor,
                      fontStyle: FontStyle.italic,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Bouton / loader
            if (_loading)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: c.homeAccent,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: btnColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Réserver',
                  style: TextStyle(
                    color: c.homeAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _PromoStrip — Carousel compact publicités & offres
//
// • Se cache totalement (SizedBox.shrink) si aucune image active.
// • Se connecte au socket pour mises à jour temps réel.
// • isVip: true → teinte dorée pour l'onglet VIP.
// ════════════════════════════════════════════════════════════════════════════
class _PromoStrip extends StatefulWidget {
  const _PromoStrip({this.isVip = false});
  final bool isVip;

  @override
  State<_PromoStrip> createState() => _PromoStripState();
}

class _PromoStripState extends State<_PromoStrip> {
  List<ImageModel> _images = [];
  bool _loading = true;
  int _current = 0;
  io.Socket? _socket;
  static const String _base = 'https://mvst.tenelo.cloud/';

  @override
  void initState() {
    super.initState();
    _charger();
    _connectSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _connectSocket() {
    try {
      _socket = io.io(
        'https://mvst.tenelo.cloud',
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      _socket!.connect();
      _socket!.on('connect', (_) => _charger());
      _socket!.on('images_modifiees', (_) => _charger());
      _socket!.on('disconnect', (_) {
        Future.delayed(const Duration(seconds: 3), _connectSocket);
      });
    } catch (_) {}
  }

  Future<void> _charger() async {
    try {
      final res = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/getImages.php'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          setState(() {
            _images = List<ImageModel>.from(
              data['images'].map((i) => ImageModel.fromJson(i)),
            ).where((i) => i.statut.toLowerCase() == 'actif').toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Invisible si chargement ou aucune image → zéro espace occupé
    if (_loading || _images.isEmpty) return const SizedBox.shrink();

    final c = Config.colors;
    final bool isVip = widget.isVip;
    final Color accent = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color dotInactive = isVip
        ? _kVipGold.withValues(alpha: 0.22)
        : c.homeButtonPrimary.withValues(alpha: 0.20);

    return Padding(
      // Espace uniquement si des images sont présentes
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Étiquette discrète ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'ACTUALITÉS & OFFRES',
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // ── Carousel compact ──────────────────────────────────────────
          CarouselSlider.builder(
            itemCount: _images.length,
            itemBuilder: (ctx, i, _) {
              final url = _base + _images[i].lien_image;
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, double scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsImages(
                        imageUrl: url,
                        titre: _images[i].titre,
                        description: _images[i].description,
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stack) => Container(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          color: accent.withValues(alpha: 0.3),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 136,
              viewportFraction: 0.80,
              autoPlay: _images.isNotEmpty,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              autoPlayCurve: Curves.easeInOutCubic,
              enlargeCenterPage: true,
              enlargeFactor: 0.20,
              padEnds: true,
              onPageChanged: (i, _) => setState(() => _current = i),
            ),
          ),
          // ── Indicateurs dots ──────────────────────────────────────────
          if (_images.length > 1) ...[
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (i) {
                final bool active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: active ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: active ? accent : dotInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helpers internes ──────────────────────────────────────────────────────
// ignore: unused_element
class _NavItem {
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
}

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

void _showNonAuthSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 8),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: const Text(
        'Vous n\'êtes pas authentifié. Allez dans Paramètres › Profil pour créer votre compte.',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
