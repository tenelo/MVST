import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/config/app_colors.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/services/api_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ── Constantes ────────────────────────────────────────────────────────────────
// Chemin SANS kBaseUrl : ApiClient le préfixe lui-même.
const String _apiPath = 'api_suggestions.php';

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

// ── Statuts ────────────────────────────────────────────────────────────────
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

// ── Modèle ─────────────────────────────────────────────────────────────────
class _Suggestion {
  final int id;
  final String nom;
  final String telephone;
  final String message;
  final String categorie;
  final String idutilisateur;
  String statut;
  final DateTime createdat;

  _Suggestion({
    required this.id,
    required this.nom,
    required this.telephone,
    required this.message,
    required this.categorie,
    required this.idutilisateur,
    required this.statut,
    required this.createdat,
  });

  factory _Suggestion.fromJson(Map<String, dynamic> j) => _Suggestion(
    id: (j['id'] as num).toInt(),
    nom: j['nom'] ?? '',
    telephone: j['telephone'] ?? '',
    message: j['message'] ?? '',
    categorie: j['categorie'] ?? 'Autre',
    idutilisateur: j['idutilisateur'] ?? '',
    statut: j['statut'] ?? 'en_attente',
    createdat: DateTime.tryParse(j['createdat'] ?? '') ?? DateTime.now(),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
class Suggestions extends StatefulWidget {
  const Suggestions({super.key, required this.idUtilisateur});
  final String idUtilisateur;

  @override
  State<Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<Suggestions>
    with SingleTickerProviderStateMixin {
  final _messageCtrl = TextEditingController();
  final _messageFocus = FocusNode();

  String _nomUtilisateur = '';
  String _prenomsUtilisateur = '';
  String _telephoneUtilisateur = '';
  String _categorieSelectionnee = _categories[0].label;

  bool _isLoading = false;
  bool _loadingProfil = true;
  bool _loadingSuggestions = false;

  late TabController _tabController;
  List<_Suggestion> _suggestions = [];
  late io.Socket _socket;

  static const int _maxChars = 500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _messageCtrl.addListener(() => setState(() {}));
    _chargerProfil();
    _chargerSuggestions();
    _connecterSocket();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _messageFocus.dispose();
    _tabController.dispose();
    _socket.disconnect();
    _socket.dispose();
    super.dispose();
  }

  // ── Profil utilisateur (Firestore) ────────────────────────────────────────
  Future<void> _chargerProfil() async {
    try {
      // Charger le profil via l'API existante ou Firestore
      // On utilise ici Firestore car le profil utilisateur reste dans Firebase
      final snap = await _fetchProfilFirestore();
      if (mounted) {
        setState(() {
          _nomUtilisateur = snap['nom'] ?? '';
          _prenomsUtilisateur = snap['prenoms'] ?? '';
          _telephoneUtilisateur = snap['telephone'] ?? '';
          _loadingProfil = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProfil = false);
    }
  }

  Future<Map<String, dynamic>> _fetchProfilFirestore() async {
    // Import lazy pour éviter la dépendance directe au top du fichier
    // si Firestore est déjà dans l'app pour d'autres usages
    try {
      final resp = await ApiClient.instance.get(
        'get_utilisateur.php?id=${widget.idUtilisateur}',
        timeout: const Duration(seconds: 5),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true && data['utilisateur'] != null) {
          return data['utilisateur'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return {};
  }

  // ── Chargement HTTP des suggestions ──────────────────────────────────────
  Future<void> _chargerSuggestions() async {
    if (_loadingSuggestions) return;
    setState(() => _loadingSuggestions = true);
    try {
      final resp = await ApiClient.instance.get(
        '$_apiPath?action=get_by_user&idutilisateur=${widget.idUtilisateur}',
        timeout: const Duration(seconds: 10),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true && mounted) {
          final list = (data['suggestions'] as List)
              .map((j) => _Suggestion.fromJson(j))
              .toList();
          setState(() => _suggestions = list);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  // ── Socket.IO ─────────────────────────────────────────────────────────────
  void _connecterSocket() {
    _socket = io.io(
      kBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );
    _socket.connect();

    _socket.onConnect((_) {
      // Rejoindre la room personnelle pour recevoir les updates de statut
      _socket.emit('rejoindre_suggestions_user', {
        'idutilisateur': widget.idUtilisateur,
      });
    });

    // L'admin a changé le statut d'une suggestion
    _socket.on('statut_suggestion_change', (data) {
      if (!mounted) return;
      final int id = (data['id'] as num).toInt();
      final String statut = data['statut'] ?? '';
      setState(() {
        for (final s in _suggestions) {
          if (s.id == id) s.statut = statut;
        }
      });
    });

    // Une suggestion a été supprimée côté admin (edge case)
    _socket.on('suggestion_supprimee_admin', (data) {
      if (!mounted) return;
      final int id = (data['id'] as num).toInt();
      setState(() => _suggestions.removeWhere((s) => s.id == id));
    });
  }

  // ── Envoi d'une nouvelle suggestion ──────────────────────────────────────
  Future<void> _envoyer() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    // Si le profil n'a pas chargé, on retente une fois
    if (_nomUtilisateur.isEmpty) {
      await _chargerProfil();
    }

    try {
      final resp = await ApiClient.instance.post(
        _apiPath,
        body: {
          'action': 'add',
          'nom': _nomUtilisateur.isNotEmpty
              ? '$_nomUtilisateur${_prenomsUtilisateur.isNotEmpty ? " $_prenomsUtilisateur" : ""}'
              : 'Utilisateur',
          'telephone': _telephoneUtilisateur.isNotEmpty
              ? _telephoneUtilisateur
              : '-',
          'message': _messageCtrl.text.trim(),
          'categorie': _categorieSelectionnee,
          'idutilisateur': widget.idUtilisateur,
        },
        timeout: const Duration(seconds: 10),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          final newSugg = _Suggestion(
            id: data['id'] as int,
            nom: _nomUtilisateur,
            telephone: _telephoneUtilisateur,
            message: _messageCtrl.text.trim(),
            categorie: _categorieSelectionnee,
            idutilisateur: widget.idUtilisateur,
            statut: 'en_attente',
            createdat:
                DateTime.tryParse(data['createdat'] ?? '') ?? DateTime.now(),
          );

          // Notifier les admins en temps réel
          _socket.emit('nouvelle_suggestion', {
            'id': newSugg.id,
            'nom': newSugg.nom,
            'telephone': newSugg.telephone,
            'message': newSugg.message,
            'categorie': newSugg.categorie,
            'idutilisateur': newSugg.idutilisateur,
            'statut': newSugg.statut,
            'createdat': data['createdat'],
          });

          if (mounted) {
            setState(() => _suggestions.insert(0, newSugg));
            _messageCtrl.clear();
            _tabController.animateTo(1);
            _afficherSucces();
          }
        } else {
          if (mounted) _afficherErreur();
        }
      } else {
        if (mounted) _afficherErreur();
      }
    } catch (_) {
      if (mounted) _afficherErreur();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Suppression ───────────────────────────────────────────────────────────
  Future<void> _supprimer(_Suggestion s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer la suggestion'),
        content: const Text('Cette action est irréversible. Confirmer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      final resp = await ApiClient.instance.post(
        _apiPath,
        body: {
          'action': 'delete',
          'id': s.id,
          'idutilisateur': widget.idUtilisateur,
        },
        timeout: const Duration(seconds: 8),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        // Notifier les admins
        _socket.emit('suggestion_supprimee', {'id': s.id});
        if (mounted) setState(() => _suggestions.remove(s));
      }
    } catch (_) {}
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

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      body: _loadingProfil
          ? Center(child: CircularProgressIndicator(color: c.homeButtonPrimary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
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
    final int restants = _maxChars - _messageCtrl.text.length;
    final bool pret =
        _messageCtrl.text.trim().isNotEmpty &&
        _messageCtrl.text.length <= _maxChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expéditeur
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
                            ? '$_nomUtilisateur${_prenomsUtilisateur.isNotEmpty ? " $_prenomsUtilisateur" : ""}'
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

          // Catégories
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
                final selected = cat.label == _categorieSelectionnee;
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

          // Message
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
            controller: _messageCtrl,
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
    if (_loadingSuggestions) {
      return Center(
        child: CircularProgressIndicator(color: c.homeButtonPrimary),
      );
    }

    if (_suggestions.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _chargerSuggestions,
      color: c.homeButtonPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildCarteHistorique(c, _suggestions[i]),
      ),
    );
  }

  Widget _buildCarteHistorique(AppColors c, _Suggestion s) {
    final statutInfo = _statuts[s.statut] ?? _statuts['en_attente']!;
    final catInfo = _categories.firstWhere(
      (x) => x.label == s.categorie,
      orElse: () => _categories.last,
    );
    final date = DateFormat(
      'd MMM y · HH:mm',
      'fr_FR',
    ).format(s.createdat.toLocal());

    return Dismissible(
      key: ValueKey(s.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _supprimer(s);
        return false; // on gère nous-mêmes le retrait dans _supprimer
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      child: Container(
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
              // En-tête : catégorie + statut animé
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
                          s.categorie,
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(s.statut),
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
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Text(
                s.message,
                style: TextStyle(
                  color: c.homeTextPrimary,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  // Bouton supprimer discret
                  GestureDetector(
                    onTap: () => _supprimer(s),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
