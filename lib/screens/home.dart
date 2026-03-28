// ignore_for_file: unnecessary_null_comparison

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/models.dart';
import 'package:mvst/profil/profil.dart';
import 'package:mvst/screens/conditionsDutilisation.dart';
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/tableauDesTickets.dart';

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
    final BlocCompteur initialiseBloc = BlocProvider.of<BlocCompteur>(context);
    initialiseBloc.add(EventInitialise());
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) setState(() => _currentUser = user);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    final c = Config.colors;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double appBarHeight = screenHeight * 0.14;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.homeBackground,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: SafeArea(
          bottom: false,
          child: AppBar(
            iconTheme: IconThemeData(color: c.homeAccent),
            flexibleSpace: Carousel(),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
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

  Widget _buildAccueil(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingH = screenWidth * 0.04;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: c.homeBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: constraints.maxHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Bandeau info ───────────────────────────────────────
                _buildBandeau(screenWidth, isVip: false),
                SizedBox(height: constraints.maxHeight * 0.02),

                // ── Label section ──────────────────────────────────────
                _buildSectionLabel('Réserver un ticket', screenWidth),
                SizedBox(height: constraints.maxHeight * 0.015),

                // ── Cartes trajets ─────────────────────────────────────
                carte(context, "Ferké", "Abidjan", "Bouaké", screenWidth),
                SizedBox(height: constraints.maxHeight * 0.012),
                carte(context, "Bouaké", "Ferké", "Abidjan", screenWidth),
                SizedBox(height: constraints.maxHeight * 0.012),
                carte(context, "Abidjan", "Ferké", "Bouaké", screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccueilVip(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingH = screenWidth * 0.04;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: Config.colors.homeBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: constraints.maxHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBandeau(screenWidth, isVip: true),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildSectionLabel('★  VIP', screenWidth, isVip: true),
                SizedBox(height: constraints.maxHeight * 0.015),
                carteVip(context, "Ferké", "Abidjan", "Bouaké", screenWidth),
                SizedBox(height: constraints.maxHeight * 0.012),
                carteVip(context, "Bouaké", "Ferké", "Abidjan", screenWidth),
                SizedBox(height: constraints.maxHeight * 0.012),
                carteVip(context, "Abidjan", "Ferké", "Bouaké", screenWidth),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBandeau(double width, {required bool isVip}) {
    final c = Config.colors;
    final Color bg = isVip ? const Color(0xFF1A3D2B) : c.homeBandeauBackground;
    final Color border = isVip ? const Color(0xFFFFD700) : c.homeBandeauBorder;
    final Color accentColor = isVip
        ? const Color(0xFFFFD700)
        : c.homeButtonPrimary;
    final Color textColor = isVip
        ? Colors.white70
        : c.homeTextPrimary.withOpacity(0.75);

    final List<Map<String, String>> infos = isVip
        ? [
            {'icon': '⭐', 'texte': 'Voyagez en classe VIP'},
            {'icon': '🛋️', 'texte': 'Sièges spacieux et confortables'},
            {'icon': '🎫', 'texte': 'Ticket QR Code instantané'},
          ]
        : [
            {'icon': '🚌', 'texte': 'Réservez votre place en quelques clics'},
            {'icon': '⚡', 'texte': 'Disponibilité en temps réel'},
            {'icon': '🎫', 'texte': 'Ticket QR Code instantané'},
          ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre accent gauche ──────────────────────────────────────
          Container(
            width: 4,
            height: 90,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          // ── Contenu ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVip
                        ? 'MVST VIP — Voyage Premium'
                        : 'MVST — Transport Interurbain',
                    style: TextStyle(
                      fontSize: width * 0.033,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...infos.map(
                    (info) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Text(
                            info['icon']!,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            info['texte']!,
                            style: TextStyle(
                              fontSize: width * 0.029,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, double width, {bool isVip = false}) {
    final c = Config.colors;
    final Color color = isVip ? const Color(0xFFB8860B) : c.homeButtonPrimary;
    final Color underline = isVip ? const Color(0xFFFFD700) : c.homeAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: width * 0.038,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: underline,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final c = Config.colors;
    final double fontSize = MediaQuery.of(context).size.width * 0.028;
    return BottomAppBar(
      color: c.homeCardBackground,
      elevation: 8,
      child: Center(
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Accueil'),
            Tab(icon: Icon(Icons.receipt_outlined), text: 'Tickets'),
            Tab(
              icon: Icon(
                _tabController.index == 2 ? Icons.star : Icons.star_outline,
                color: _tabController.index == 2 ? c.homeTabSelected : null,
              ),
              text: 'VIP',
            ),
            Tab(icon: Icon(Icons.list), text: 'Historique'),
            Tab(icon: Icon(Icons.info_outlined), text: 'Infos'),
          ],
          labelColor: c.homeTabSelected,
          indicatorColor: c.homeAccent,
          indicatorSize: TabBarIndicatorSize.tab,
          unselectedLabelColor: c.homeTabUnselected,
          indicatorWeight: 4.0,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DRAWER commun
  // ══════════════════════════════════════════════════════════════════════════
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
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: c.homeAccent, width: 1.5),
                            color: Colors.white.withOpacity(0.1),
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
                          style: TextStyle(color: c.homeAccent, fontSize: 12),
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
                      final userId = FirebaseAuth.instance.currentUser!.uid;
                      final userProfil =
                          FirebaseAuth.instance.currentUser!.displayName;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Profil(
                            idUtilisateur: userId,
                            userProfil: userProfil!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PageDAuthentification(),
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
                      showIncompleteFieldsSnackBar(context);
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
                        builder: (context) => const ConditionsDUtilisation(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.lightbulb_outlined,
                  label: 'Suggestions',
                  onTap: () async {
                    if (FirebaseAuth.instance.currentUser != null) {
                      final userId = FirebaseAuth.instance.currentUser!.uid;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Suggestions(idUtilisateur: userId),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                      showIncompleteFieldsSnackBar(context);
                    }
                  },
                ),
                // ── Sélecteur de thème ──────────────────────────────────
                _buildThemeSelector(context),
                Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
                _buildDrawerItem(
                  icon: Icons.power_settings_new,
                  label: 'Déconnexion',
                  onTap: () => deconnexion(context),
                  isDestructive: true,
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.15), thickness: 1),
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
    final c = Config.colors;
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
              color: Colors.white.withOpacity(0.5),
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
                  setState(
                    () => Config.activeTheme = t['mode'] as AppThemeMode,
                  );
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
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? (t['color'] as Color)
                          : Colors.white.withOpacity(0.2),
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
        : Colors.white.withOpacity(0.85);
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

// ── Fonctions globales ─────────────────────────────────────────────────────────
void deconnexion(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (BuildContext context) => const Login()),
    (route) => false,
  );
}

void showIncompleteFieldsSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 8),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(
        'Vous n\'êtes pas authentifié, allez dans Paramètres puis Profil pour créer votre compte',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
