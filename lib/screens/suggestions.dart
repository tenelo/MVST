import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mvst/config/app_colors.dart';
import 'package:mvst/config/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// ── Catégories disponibles ─────────────────────────────────────────────────
const List<_Categorie> _categories = [
  _Categorie('Amélioration', Icons.build_circle_outlined),
  _Categorie('Problème', Icons.warning_amber_outlined),
  _Categorie('Compliment', Icons.star_outline_rounded),
  _Categorie('Autre', Icons.chat_bubble_outline_rounded),
  _Categorie('Nouveau trajet', Icons.map_outlined),
];

class _Categorie {
  final String label;
  final IconData icon;
  const _Categorie(this.label, this.icon);
}

// ── Statuts affichés pour l'utilisateur ────────────────────────────────────
const Map<String, _StatutInfo> _statuts = {
  'en_attente': _StatutInfo(
    'En attente',
    Color(0xFFF59E0B),
    Icons.hourglass_empty_rounded,
  ),
  'lu': _StatutInfo('Lu', Color(0xFF3B82F6), Icons.drafts_outlined),
  'traite': _StatutInfo(
    'Traité',
    Color(0xFF10B981),
    Icons.check_circle_outline_rounded,
  ),
};

class _StatutInfo {
  final String label;
  final Color color;
  final IconData icon;
  const _StatutInfo(this.label, this.color, this.icon);
}

// ──────────────────────────────────────────────────────────────────────────
class Suggestions extends StatefulWidget {
  const Suggestions({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  State<Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions>
    with SingleTickerProviderStateMixin {
  final TextEditingController _message = TextEditingController();
  final FocusNode _messageFocus = FocusNode();

  String _nomUtilisateur = '';
  String _telephoneUtilisateur = '';
  String _categorieSelectionnee = _categories[0].label;
  bool _isLoading = false;
  bool _loadingProfil = true;
  late TabController _tabController;
  late Stream<QuerySnapshot> _suggestionsStream;

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _message.addListener(() => setState(() {}));
    // Stream initialisé une seule fois pour éviter le flash lors des rebuilds
    _suggestionsStream = FirebaseFirestore.instance
        .collection('suggestions')
        .where('idUtilisateur', isEqualTo: widget.idUtilisateur)
        .snapshots();
    _chargerProfil();
  }

  @override
  void dispose() {
    _message.dispose();
    _messageFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Chargement du profil utilisateur ─────────────────────────────────────
  Future<void> _chargerProfil() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('id', isEqualTo: widget.idUtilisateur)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final d = snap.docs.first.data();
        setState(() {
          _nomUtilisateur = '${d['nom'] ?? ''} ${d['prenoms'] ?? ''}'.trim();
          _telephoneUtilisateur = d['telephone'] ?? '';
          _loadingProfil = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfil = false);
    }
  }

  // ── Envoi de la suggestion ────────────────────────────────────────────────
  Future<void> _envoyer() async {
    if (_message.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      // 1. Sauvegarde Firestore (pour le suivi utilisateur + admin)
      await FirebaseFirestore.instance.collection('suggestions').add({
        'idUtilisateur': widget.idUtilisateur,
        'nom': _nomUtilisateur,
        'telephone': _telephoneUtilisateur,
        'categorie': _categorieSelectionnee,
        'message': _message.text.trim(),
        'statut': 'en_attente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Notification serveur PHP (existant — ne rien casser côté admin)
      try {
        await http.post(
          Uri.parse('https://mvst.tenelo.cloud/suggestions.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nomClient': _nomUtilisateur,
            'telephoneClient': _telephoneUtilisateur,
            'suggestion': '[$_categorieSelectionnee] ${_message.text.trim()}',
          }),
        );
      } catch (_) {
        // PHP optionnel — si indisponible, Firestore suffit
      }

      if (mounted) {
        _message.clear();
        _tabController.animateTo(1); // bascule vers l'historique
        _afficherSucces();
      }
    } catch (e) {
      if (mounted) _afficherErreur();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _afficherSucces() {
    final c = Config.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: c.homeButtonPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Suggestion envoyée, merci !',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _afficherErreur() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          'Erreur lors de l\'envoi, réessayez.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: _loadingProfil
          ? Center(child: CircularProgressIndicator(color: c.homeButtonPrimary))
          : NestedScrollView(
              headerSliverBuilder: (_, _) => [
                SliverAppBar(
                  expandedHeight: 160,
                  pinned: true,
                  backgroundColor: c.homeButtonPrimary,
                  iconTheme: IconThemeData(color: c.homeAccent),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [c.homeHeaderTop, c.homeButtonPrimary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Suggestions',
                                style: TextStyle(
                                  color: c.homeAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Lobster',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Votre avis améliore le service',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(46),
                    child: Container(
                      color: c.homeButtonPrimary,
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withValues(
                          alpha: 0.55,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Nouvelle suggestion'),
                          Tab(text: 'Mes envois'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [_buildFormulaire(c), _buildHistorique(c)],
              ),
            ),
    );
  }

  // ── Onglet 1 : Formulaire ─────────────────────────────────────────────────
  Widget _buildFormulaire(AppColors c) {
    final int restants = _maxChars - _message.text.length;
    final bool pret =
        _message.text.trim().isNotEmpty && _message.text.length <= _maxChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Expéditeur ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.homeButtonPrimary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: c.homeButtonPrimary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person_outline,
                    color: c.homeButtonPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nomUtilisateur.isNotEmpty
                            ? _nomUtilisateur
                            : 'Utilisateur',
                        style: TextStyle(
                          color: c.homeTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (_telephoneUtilisateur.isNotEmpty)
                        Text(
                          _telephoneUtilisateur,
                          style: TextStyle(
                            color: c.homeTextPrimary.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Catégorie ────────────────────────────────────────────────────
          Text(
            'CATÉGORIE',
            style: TextStyle(
              color: c.homeTextPrimary.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final bool selected = cat.label == _categorieSelectionnee;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _categorieSelectionnee = cat.label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.homeButtonPrimary
                            : c.homeButtonPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? c.homeButtonPrimary
                              : c.homeButtonPrimary.withValues(alpha: 0.2),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat.icon,
                            size: 14,
                            color: selected
                                ? Colors.white
                                : c.homeButtonPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : c.homeButtonPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── Message ──────────────────────────────────────────────────────
          Text(
            'VOTRE MESSAGE',
            style: TextStyle(
              color: c.homeTextPrimary.withValues(alpha: 0.45),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _message,
            focusNode: _messageFocus,
            maxLines: 7,
            maxLength: _maxChars,
            style: TextStyle(
              color: c.homeTextPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Décrivez votre suggestion, idée ou problème rencontré...',
              hintStyle: TextStyle(
                color: c.homeTextPrimary.withValues(alpha: 0.35),
                fontSize: 13,
              ),
              filled: true,
              fillColor: c.homeCardBackground,
              counterStyle: TextStyle(
                color: restants < 50
                    ? Colors.redAccent
                    : c.homeTextPrimary.withValues(alpha: 0.4),
                fontSize: 11,
              ),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: c.homeButtonPrimary, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: c.homeTextPrimary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Bouton envoyer ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_isLoading || !pret) ? null : _envoyer,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(_isLoading ? 'Envoi...' : 'Envoyer la suggestion'),
              style: FilledButton.styleFrom(
                backgroundColor: pret
                    ? c.homeButtonPrimary
                    : c.homeButtonPrimary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet 2 : Historique ─────────────────────────────────────────────────
  Widget _buildHistorique(AppColors c) {
    return StreamBuilder<QuerySnapshot>(
      stream: _suggestionsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: c.homeButtonPrimary),
          );
        }

        final docs = (snapshot.data?.docs ?? [])
          ..sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['createdAt'];
            final tb = (b.data() as Map<String, dynamic>)['createdAt'];
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return (tb as Timestamp).compareTo(ta as Timestamp);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 56,
                  color: c.homeButtonPrimary.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aucune suggestion envoyée',
                  style: TextStyle(
                    color: c.homeTextPrimary.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final String categorie = data['categorie'] ?? 'Autre';
            final String message = data['message'] ?? '';
            final String statut = data['statut'] ?? 'en_attente';
            final Timestamp? ts = data['createdAt'];
            final String date = ts != null
                ? DateFormat('d MMM y · HH:mm', 'fr_FR').format(ts.toDate())
                : '—';

            final statutInfo = _statuts[statut] ?? _statuts['en_attente']!;
            final catInfo = _categories.firstWhere(
              (c) => c.label == categorie,
              orElse: () => _categories.last,
            );

            return Container(
              decoration: BoxDecoration(
                color: c.homeCardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: c.homeButtonPrimary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── En-tête : catégorie + statut ─────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: c.homeButtonPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                catInfo.icon,
                                size: 12,
                                color: c.homeButtonPrimary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                categorie,
                                style: TextStyle(
                                  color: c.homeButtonPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statutInfo.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statutInfo.icon,
                                size: 12,
                                color: statutInfo.color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statutInfo.label,
                                style: TextStyle(
                                  color: statutInfo.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Message ──────────────────────────────────────────
                    Text(
                      message,
                      style: TextStyle(
                        color: c.homeTextPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // ── Date ─────────────────────────────────────────────
                    Text(
                      date,
                      style: TextStyle(
                        color: c.homeTextPrimary.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
