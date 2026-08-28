import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mvst/config/app_colors.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/services/api_client.dart';

class Profil extends StatefulWidget {
  const Profil({
    super.key,
    required this.idUtilisateur,
    required this.userProfil,
  });
  final String idUtilisateur;
  final String userProfil;

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _prenoms = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _residence = TextEditingController();

  late Future<Map<String, dynamic>?> _userDataFuture = getUserData(
    widget.idUtilisateur,
  );

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final resp = await ApiClient.instance.get(
        'get_utilisateur.php?id=$userId',
        timeout: const Duration(seconds: 8),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true && data['utilisateur'] != null) {
          return data['utilisateur'] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Deux initiales depuis nom + prénoms ───────────────────────────────────
  String _initiales(String? nom, String? prenoms) {
    final n = (nom?.trim().isNotEmpty == true)
        ? nom!.trim()[0].toUpperCase()
        : '';
    final p = (prenoms?.trim().isNotEmpty == true)
        ? prenoms!.trim()[0].toUpperCase()
        : '';
    if (n.isNotEmpty && p.isNotEmpty) return '$n$p';
    if (n.isNotEmpty) return n;
    return 'U';
  }

  void _ouvrirModification(Map<String, dynamic> userData) {
    final c = Config.colors;
    _nom.text = userData['nom'] ?? '';
    _prenoms.text = userData['prenoms'] ?? '';
    _telephone.text = userData['telephone'] ?? '';
    _residence.text = userData['residence'] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: c.homeCardBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Poignée ─────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: c.homeTextPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Modifier le profil',
                    style: TextStyle(
                      color: c.homeTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _champEdition('Nom', _nom, Icons.person_outline, c),
                  const SizedBox(height: 14),
                  _champEdition('Prénoms', _prenoms, Icons.badge_outlined, c),
                  const SizedBox(height: 14),
                  _champEdition(
                    'Téléphone',
                    _telephone,
                    Icons.phone_outlined,
                    c,
                    inputType: TextInputType.phone,
                    enabled: false,
                    style: TextStyle(
                      color: c.homeTextPrimary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _champEdition(
                    'Lieu de résidence',
                    _residence,
                    Icons.location_on_outlined,
                    c,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        await editerDocument(
                          context,
                          widget.idUtilisateur,
                          _nom.text.trim(),
                          _prenoms.text.trim(),
                          _telephone.text.trim(),
                          _residence.text.trim(),
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        setState(() {
                          _userDataFuture = getUserData(widget.idUtilisateur);
                        });
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Enregistrer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.homeButtonPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _champEdition(
    String label,
    TextEditingController controller,
    IconData icon,
    AppColors c, {
    TextInputType inputType = TextInputType.text,
    bool enabled = true,
    TextStyle? style,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: inputType,
      style:
          style ??
          TextStyle(
            color: enabled
                ? c.homeTextPrimary
                : c.homeTextPrimary.withValues(alpha: 0.5),
            fontSize: 14,
          ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: c.homeTextPrimary.withValues(alpha: 0.55),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: c.homeButtonPrimary, size: 20),
        filled: true,
        fillColor: enabled
            ? c.homeButtonPrimary.withValues(alpha: 0.06) // Couleur normale
            : c.homeButtonPrimary.withValues(
                alpha: 0.03,
              ), // Plus clair si désactivé
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: enabled
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c.homeButtonPrimary, width: 1.5),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: c.homeBackground,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          // ── Chargement ───────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: c.homeButtonPrimary),
            );
          }

          // ── Erreur / vide ────────────────────────────────────────────────
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    color: c.homeButtonPrimary.withValues(alpha: 0.35),
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Profil introuvable',
                    style: TextStyle(
                      color: c.homeTextPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data!;
          final String nom = userData['nom'] ?? '';
          final String prenoms = userData['prenoms'] ?? '';
          final String telephone = userData['telephone'] ?? '';
          final String residence = userData['residence'] ?? '';
          final String initiales = _initiales(nom, prenoms);

          return CustomScrollView(
            slivers: [
              // ── Header avec avatar ───────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: c.authBackground,
                iconTheme: IconThemeData(color: c.homeAccent),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(color: c.authDialogBackground),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Avatar initiales
                        Container(
                          width: screenW * 0.23,
                          height: screenW * 0.23,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.18),
                            border: Border.all(color: c.homeAccent, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              initiales,
                              style: TextStyle(
                                color: c.homeAccent,
                                fontSize: screenW * 0.082,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Lobster',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          '$nom $prenoms',
                          style: TextStyle(
                            color: c.homeAccent,
                            fontSize: screenW * 0.046,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Merci pour votre confiance !",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: screenW * 0.031,
                            fontFamily: 'Lobster',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Corps ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.05,
                    vertical: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Titre section ────────────────────────────────────
                      Text(
                        'Informations personnelles',
                        style: TextStyle(
                          color: c.homeTextPrimary.withValues(alpha: 0.5),
                          fontSize: screenW * 0.028,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Carte infos ──────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: c.homeCardBackground,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: c.homeButtonPrimary.withValues(
                                alpha: 0.07,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _infoTile(
                              icon: Icons.person_outline,
                              label: 'Nom',
                              value: nom,
                              c: c,
                              isFirst: true,
                            ),
                            _divider(c),
                            _infoTile(
                              icon: Icons.badge_outlined,
                              label: 'Prénoms',
                              value: prenoms,
                              c: c,
                            ),
                            _divider(c),
                            _infoTile(
                              icon: Icons.phone_outlined,
                              label: 'Téléphone',
                              value: telephone,
                              c: c,
                            ),
                            _divider(c),
                            _infoTile(
                              icon: Icons.location_on_outlined,
                              label: 'Résidence',
                              value: residence,
                              c: c,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Bouton modifier ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _ouvrirModification(userData),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: c.homeButtonPrimary,
                          ),
                          label: Text(
                            'Modifier le profil',
                            style: TextStyle(
                              color: c.homeButtonPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: c.homeButtonPrimary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required AppColors c,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 4 : 0, bottom: isLast ? 4 : 0),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.homeButtonPrimary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: c.homeButtonPrimary, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: c.homeTextPrimary.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value.isNotEmpty ? value : '—',
          style: TextStyle(
            color: c.homeTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _divider(AppColors c) {
    return Divider(
      height: 1,
      thickness: 0.6,
      indent: 68,
      endIndent: 16,
      color: c.homeTextPrimary.withValues(alpha: 0.07),
    );
  }
}

Future<void> editerDocument(
  BuildContext ctx,
  String idUtilisateur,
  String nom,
  String prenoms,
  String telephone,
  String residence,
) async {
  try {
    final resp = await ApiClient.instance.post(
      'update_utilisateur.php',
      body: {
        'idUtilisateur': idUtilisateur,
        'nom': nom,
        'prenoms': prenoms,
        'residence': residence,
      },
      timeout: const Duration(seconds: 8),
    );
    if (resp.statusCode != 200) return;
    final data = jsonDecode(resp.body);
    if (data['success'] == true && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: Config.colors.homeButtonPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Profil mis à jour',
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
  } catch (_) {}
}
