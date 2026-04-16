// ignore_for_file: use_build_context_synchronously
// ──────────────────────────────────────────────────────────────────────────────
// HomeV3 — Design "Atlas"
// Bold, editorial, dynamique. Carousel en hero, grandes cartes de trajet avec
// ligne de connexion départ→arrivée, VIP glassmorphism sur fond sombre.
// ──────────────────────────────────────────────────────────────────────────────
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
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/tableauDesTickets.dart';

// ── Constantes VIP ────────────────────────────────────────────────────────
const Color _kVipDeep = Color(0xFF04040E);
const Color _kVipGlass = Color(0xFF17172A);
const Color _kVipGold = Color(0xFFFFD700);
const Color _kVipGoldDim = Color(0xFFB8860B);

// ── Routes ────────────────────────────────────────────────────────────────
const List<Map<String, String>> _kRoutes = [
  {'depart': 'Ferké', 'destination': 'Abidjan'},
  {'depart': 'Ferké', 'destination': 'Bouaké'},
  {'depart': 'Bouaké', 'destination': 'Ferké'},
  {'depart': 'Bouaké', 'destination': 'Abidjan'},
  {'depart': 'Abidjan', 'destination': 'Ferké'},
  {'depart': 'Abidjan', 'destination': 'Bouaké'},
];

// ════════════════════════════════════════════════════════════════════════════
class HomeV3 extends StatefulWidget {
  const HomeV3({super.key, this.ongletInitial = 0});
  final int ongletInitial;

  @override
  State<HomeV3> createState() => _HomeV3State();
}

class _HomeV3State extends State<HomeV3> with SingleTickerProviderStateMixin {
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

  // ── AppBar compact ───────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final c = Config.colors;
    return AppBar(
      backgroundColor: c.homeCardBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: c.homeTextPrimary),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: c.homeButtonPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'MVST',
            style: TextStyle(
              color: c.homeTextPrimary,
              fontFamily: 'Lobster',
              fontSize: 22,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
            child: CircleAvatar(
              radius: 16,
              backgroundColor: c.homeButtonPrimary.withValues(alpha: 0.13),
              child: _currentUser != null
                  ? Text(
                      (_currentUser!.displayName ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: TextStyle(
                        color: c.homeButtonPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: c.homeButtonPrimary,
                      size: 18,
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

    return Container(
      color: c.homeBackground,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Carousel hero ──────────────────────────────────────────────
          Container(
            color: c.homeCardBackground,
            padding: const EdgeInsets.fromLTRB(0, 6, 0, 14),
            child: const _AtlasCarousel(),
          ),

          // ── Titre section ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nos lignes',
                      style: TextStyle(
                        color: c.homeTextPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: w * 0.055,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Standard · Réservation instantanée',
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(alpha: 0.45),
                        fontSize: w * 0.029,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.homeButtonPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_kRoutes.length} lignes',
                    style: TextStyle(
                      color: c.homeButtonPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Cartes trajet ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: _kRoutes
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RouteCardV3(
                        depart: r['depart']!,
                        destination: r['destination']!,
                        typeVoyage: 'standard',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Onglet VIP ────────────────────────────────────────────────────────────
  Widget _buildAccueilVip(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return Container(
      color: _kVipDeep,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero VIP dégradé ───────────────────────────────────────────
          _buildVipHero(context),

          // ── Titre ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '✦ ',
                          style: TextStyle(color: _kVipGold, fontSize: 15),
                        ),
                        Text(
                          'Lignes VIP',
                          style: TextStyle(
                            color: _kVipGold,
                            fontWeight: FontWeight.w900,
                            fontSize: w * 0.055,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Première classe · Confort absolu',
                      style: TextStyle(
                        color: _kVipGoldDim.withValues(alpha: 0.75),
                        fontSize: w * 0.029,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kVipGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _kVipGold.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    '★ VIP',
                    style: TextStyle(
                      color: _kVipGold,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Cartes VIP ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: _kRoutes
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RouteCardV3(
                        depart: r['depart']!,
                        destination: r['destination']!,
                        typeVoyage: 'vip',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Hero VIP ──────────────────────────────────────────────────────────────
  Widget _buildVipHero(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF0A0A1E), Color(0xFF04040E)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 28, 20, w * 0.07),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: _kVipGold.withValues(alpha: 0.5),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(30),
              color: _kVipGold.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: _kVipGold, size: 13),
                const SizedBox(width: 5),
                Text(
                  'MVST VIP — Classe Première',
                  style: TextStyle(
                    color: _kVipGold,
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.028,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.05),

          // Titre
          Text(
            'L\'excellence\ndu voyage',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: w * 0.072,
              height: 1.1,
              letterSpacing: -1.0,
            ),
          ),
          SizedBox(height: w * 0.04),

          // Features chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _vipFeatureChip('🛋️  Sièges XL'),
              _vipFeatureChip('⭐  Prioritaire'),
              _vipFeatureChip('🎫  QR Express'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vipFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _kVipGlass,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _kVipGold.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kVipGold,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Bottom nav — pilule active ────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final c = Config.colors;
    final double w = MediaQuery.of(context).size.width;
    final double fontSize = w * 0.027;

    return BottomAppBar(
      color: c.homeCardBackground,
      elevation: 0,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: c.homeTextPrimary.withValues(alpha: 0.08),
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
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: c.homeButtonPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: c.homeButtonPrimary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              const Tab(
                icon: Icon(Icons.home_rounded, size: 21),
                text: 'Accueil',
              ),
              const Tab(
                icon: Icon(Icons.receipt_outlined, size: 21),
                text: 'Tickets',
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 2
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 21,
                  color: _tabController.index == 2
                      ? _kVipGold
                      : c.homeTabUnselected,
                ),
                text: 'VIP',
              ),
              const Tab(
                icon: Icon(Icons.history_rounded, size: 21),
                text: 'Historique',
              ),
              const Tab(
                icon: Icon(Icons.info_outline_rounded, size: 21),
                text: 'Infos',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Drawer (identique à l'original) ──────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final c = Config.colors;
    return Drawer(
      backgroundColor: c.homeDrawerBackground,
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
                      _showNonAuthSnackV3(context);
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
                      _showNonAuthSnackV3(context);
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
                  onTap: () => _deconnexionV3(context),
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

// ════════════════════════════════════════════════════════════════════════════
// Carousel Atlas — charge les images du serveur via Socket.IO
// ════════════════════════════════════════════════════════════════════════════
class _AtlasCarousel extends StatefulWidget {
  const _AtlasCarousel();

  @override
  State<_AtlasCarousel> createState() => _AtlasCarouselState();
}

class _AtlasCarouselState extends State<_AtlasCarousel> {
  bool _loading = false;
  bool _erreur = false;
  List<ImageModel> _images = [];
  int _currentIndex = 0;
  final String _base = 'https://mvst.tenelo.cloud/';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _erreur = false;
    });
    try {
      final res = await http.get(
        Uri.parse('https://mvst.tenelo.cloud/getImages.php'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true) {
          setState(() {
            _images = List<ImageModel>.from(
              data['images'].map((i) => ImageModel.fromJson(i)),
            ).where((i) => i.statut.toLowerCase() == 'actif').toList();
          });
        }
      }
    } catch (_) {
      setState(() => _erreur = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double w = MediaQuery.of(context).size.width;

    if (_loading) {
      return SizedBox(
        height: w * 0.44,
        child: Center(child: CircularProgressIndicator(color: c.homeAccent)),
      );
    }

    if (_erreur || _images.isEmpty) {
      return Container(
        height: w * 0.44,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: c.homeButtonPrimary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.homeButtonPrimary.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_outlined,
                color: c.homeButtonPrimary.withValues(alpha: 0.4),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                _erreur
                    ? 'Vérifiez la connexion internet'
                    : 'Aucune image disponible',
                style: TextStyle(
                  color: c.homeTextPrimary.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _images.length,
          itemBuilder: (ctx, index, _) {
            final url = _base + _images[index].lien_image;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stack) => Container(
                    color: c.homeButtonPrimary.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: c.homeButtonPrimary.withValues(alpha: 0.4),
                      size: 40,
                    ),
                  ),
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: w * 0.44,
            viewportFraction: 0.88,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 820),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: true,
            enlargeFactor: 0.12,
            onPageChanged: (i, _) => setState(() => _currentIndex = i),
          ),
        ),
        const SizedBox(height: 10),
        // Indicateurs dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_images.length, (i) {
            final bool active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? c.homeButtonPrimary
                    : c.homeButtonPrimary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Carte de trajet Atlas — grande carte avec ligne de connexion départ→arrivée
// ════════════════════════════════════════════════════════════════════════════
class _RouteCardV3 extends StatefulWidget {
  const _RouteCardV3({
    required this.depart,
    required this.destination,
    required this.typeVoyage,
  });
  final String depart;
  final String destination;
  final String typeVoyage;

  @override
  State<_RouteCardV3> createState() => _RouteCardV3State();
}

class _RouteCardV3State extends State<_RouteCardV3> {
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
        if ((data['points'] ?? 0) == 0) {
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
    final double w = MediaQuery.of(context).size.width;
    final bool isVip = widget.typeVoyage == 'vip';

    // Couleurs
    final Color cardBg = isVip ? _kVipGlass : c.homeCardBackground;
    final Color cardBorder = isVip
        ? _kVipGold.withValues(alpha: 0.3)
        : c.homeBordurePetiteCarte;
    final Color accent = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color titleColor = isVip ? Colors.white : c.homeTextPrimary;
    final Color subColor = isVip
        ? Colors.white38
        : c.homeTextPrimary.withValues(alpha: 0.38);
    final Color lineColor = isVip
        ? _kVipGold.withValues(alpha: 0.4)
        : c.homeButtonPrimary.withValues(alpha: 0.3);
    final Color btnBg = isVip ? _kVipGold : c.homeButtonPrimary;
    final Color btnFg = isVip ? _kVipDeep : Colors.white;

    return GestureDetector(
      onTap: _loading ? null : _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: isVip
                  ? _kVipGold.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              // ── Colonne départ / ligne / arrivée ─────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Départ
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.depart,
                        style: TextStyle(
                          color: subColor,
                          fontSize: w * 0.030,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Ligne verticale
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      width: 1.5,
                      height: 24,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
                  // Arrivée
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardBg, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.5),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.destination,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: w * 0.042,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // ── Bouton réserver ───────────────────────────────────────
              if (_loading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: accent,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: btnBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: btnBg.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Réserver',
                        style: TextStyle(
                          color: btnFg,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.arrow_forward_rounded, color: btnFg, size: 14),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────
void _deconnexionV3(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
    (route) => false,
  );
}

void _showNonAuthSnackV3(BuildContext context) {
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
