import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/mes_services/annonces_store.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  List<Annonce> _annonces = [];
  bool _chargement = true;
  final Set<String> _selection = {};
  bool _modeSelection = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final liste = await AnnoncesStore.lireToutes();
    if (mounted) {
      setState(() {
        _annonces = liste;
        _chargement = false;
      });
    }
  }

  void _basculerSelection(String id) {
    setState(() {
      if (_selection.contains(id)) {
        _selection.remove(id);
        if (_selection.isEmpty) _modeSelection = false;
      } else {
        _selection.add(id);
      }
    });
  }

  void _activerModeSelection(String id) {
    setState(() {
      _modeSelection = true;
      _selection.add(id);
    });
  }

  Future<void> _supprimerSelection() async {
    await AnnoncesStore.supprimer(Set<String>.from(_selection));
    setState(() {
      _selection.clear();
      _modeSelection = false;
    });
    await _charger();
  }

  Future<void> _supprimerUne(String id) async {
    await AnnoncesStore.supprimer({id});
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    return Scaffold(
      backgroundColor: c.homeBackground,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: c.homeButtonPrimary,
            iconTheme: IconThemeData(color: c.homeAccent),
            actions: [
              if (_modeSelection)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: c.homeAccent),
                  onPressed: _selection.isEmpty
                      ? null
                      : _confirmerSuppressionMultiple,
                ),
            ],
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
                        Row(
                          children: [
                            Icon(
                              Icons.campaign_rounded,
                              color: c.homeAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _modeSelection
                                  ? '${_selection.length} selectionnee(s)'
                                  : 'Annonces',
                              style: TextStyle(
                                color: c.homeAccent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Les messages de MVST',
                          style: TextStyle(
                            color: c.homeAccent.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: _chargement
            ? Center(
                child: CircularProgressIndicator(color: c.homeButtonPrimary),
              )
            : _annonces.isEmpty
            ? _etatVide(c)
            : _liste(c),
      ),
    );
  }

  Widget _etatVide(dynamic c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: c.homeTextPrimary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce',
            style: TextStyle(
              color: c.homeTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Les messages de MVST apparaitront ici.',
            style: TextStyle(
              color: c.homeTextPrimary.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liste(dynamic c) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _annonces.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          if (_modeSelection) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
            child: Row(
              children: [
                Icon(
                  Icons.swipe_left_alt_rounded,
                  size: 16,
                  color: c.homeTextPrimary.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Glissez une annonce pour la supprimer · appui long pour en selectionner plusieurs',
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final i = index - 1;
        final a = _annonces[i];
        final selected = _selection.contains(a.id);
        String dateFmt = '';
        try {
          dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(a.date);
        } catch (_) {
          dateFmt = DateFormat('dd/MM/yyyy HH:mm').format(a.date);
        }
        return Dismissible(
          key: ValueKey(a.id),
          direction: _modeSelection
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmerSuppressionUne(),
          onDismissed: (_) => _supprimerUne(a.id),
          child: GestureDetector(
            onLongPress: () => _activerModeSelection(a.id),
            onTap: _modeSelection ? () => _basculerSelection(a.id) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: c.homeCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? c.homeButtonPrimary
                      : c.homeBordurePetiteCarte.withValues(alpha: 0.4),
                  width: selected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_modeSelection)
                      Padding(
                        padding: const EdgeInsets.only(right: 12, top: 2),
                        child: Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected
                              ? c.homeButtonPrimary
                              : c.homeTextPrimary.withValues(alpha: 0.3),
                          size: 22,
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.homeButtonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: c.homeButtonPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.titre,
                            style: TextStyle(
                              color: c.homeTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a.message,
                            style: TextStyle(
                              color: c.homeTextPrimary.withValues(alpha: 0.75),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dateFmt,
                            style: TextStyle(
                              color: c.homeTextPrimary.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_modeSelection)
                      GestureDetector(
                        onTap: () async {
                          if (await _confirmerSuppressionUne()) {
                            await _supprimerUne(a.id);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              Icon(
                                Icons.swipe_left_alt_rounded,
                                size: 16,
                                color: const Color.fromARGB(255, 241, 126, 118),
                              ),
                              Icon(
                                Icons.delete_outline_rounded,
                                color: const Color.fromARGB(255, 241, 126, 118),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmerSuppressionUne() async {
    final c = Config.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.homeCardBackground,
        title: Text('Supprimer', style: TextStyle(color: c.homeTextPrimary)),
        content: Text(
          'Supprimer cette annonce ?',
          style: TextStyle(color: c.homeTextPrimary.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _confirmerSuppressionMultiple() async {
    final c = Config.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.homeCardBackground,
        title: Text('Supprimer', style: TextStyle(color: c.homeTextPrimary)),
        content: Text(
          'Supprimer ${_selection.length} annonce(s) ?',
          style: TextStyle(color: c.homeTextPrimary.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await _supprimerSelection();
  }
}
