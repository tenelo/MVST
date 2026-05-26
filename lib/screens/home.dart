import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/bloc/event.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/mes_services/auth_service.dart';
import 'package:mvst/profil/profil.dart';
import 'package:mvst/screens/accueil.dart';
import 'package:mvst/screens/conditionsDutilisation.dart';
import 'package:mvst/screens/infos.dart';
import 'package:mvst/screens/mestickets.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/screens/tableauDesTickets.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.ongletInitial.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    BlocProvider.of<BlocCompteur>(context).add(EventInitialise());
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() => _currentUser = user);
        if (user != null) _chargerNomEtPrenoms(user.uid);
      }
    });
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

  @override
  void dispose() {
    _tabController.dispose();
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
          const Accueil(),
          _currentUser != null
              ? MesTickets(idUtilisateur: _currentUser!.uid)
              : const Login(),
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

  // ── Bottom nav ────────────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final c = Config.colors;
    final double fontSize = MediaQuery.of(context).size.width * 0.027;

    return BottomAppBar(
      color: c.homeCardBackground,
      elevation: 0,
      padding: EdgeInsets.zero,
      height: 70,
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
                      ? Icons.history_rounded
                      : Icons.history_outlined,
                  size: 22,
                  color: _tabController.index == 2
                      ? c.homeTabSelected
                      : c.homeTabUnselected,
                ),
                text: 'Historique',
              ),
              Tab(
                icon: Icon(
                  _tabController.index == 3
                      ? Icons.info_rounded
                      : Icons.info_outlined,
                  size: 22,
                  color: _tabController.index == 3
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

void _deconnexion(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const Login()),
    (route) => false,
  );
}
