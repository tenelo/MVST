import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/authentification/pin_forgot.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/clavier_numerique.dart';
import 'package:mvst/screens/home.dart';

class PinUnlock extends StatefulWidget {
  const PinUnlock({super.key, this.apresAuthentification});
  final VoidCallback? apresAuthentification;

  @override
  State<PinUnlock> createState() => _PinUnlockState();
}

class _PinUnlockState extends State<PinUnlock> {
  static const _storage = FlutterSecureStorage();

  String _pin = '';
  String? _erreur;
  int _tentatives = 0;
  int _nbBlocages = 0;
  bool _estBloque = false;
  int _secondesRestantes = 0;
  Timer? _timerBloquage;

  bool _biometriqueDisponible = false;
  bool _biometriqueActivee = false;
  String _nomUtilisateur = '';

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _timerBloquage?.cancel();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    final nom = await _storage.read(key: 'user_name') ?? '';
    final bioActivee = await _storage.read(key: 'biometric_enabled') ?? 'false';

    // Récupérer le nombre de blocages précédents
    final nbBlocagesStr = await _storage.read(key: 'nb_blocages_pin') ?? '0';
    _nbBlocages = int.tryParse(nbBlocagesStr) ?? 0;

    // Vérifier si l'utilisateur est sur liste noire
    final listeNoire = await _storage.read(key: 'liste_noire') ?? 'false';

    final auth = LocalAuthentication();
    final bioDispo = await auth.canCheckBiometrics;

    if (!mounted) return;

    if (listeNoire == 'true') {
      _afficherListeNoire();
      return;
    }

    setState(() {
      _nomUtilisateur = nom.split(' ').first;
      _biometriqueActivee = bioActivee == 'true';
      _biometriqueDisponible = bioDispo;
    });

    if (_biometriqueActivee && _biometriqueDisponible) {
      await Future.delayed(const Duration(milliseconds: 400));
      _authentifierParEmpreinte();
    }
  }

  void _onChiffre(String chiffre) {
    if (_pin.length >= 4 || _estBloque) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == 4) _verifierPin();
  }

  void _onSupprimer() {
    if (_pin.isEmpty || _estBloque) return;
    setState(() {
      _erreur = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  // ═══════════════════════════════════════════════
  // VÉRIFICATION AVEC SÉCURITÉ PROGRESSIVE
  // ═══════════════════════════════════════════════
  Future<void> _verifierPin() async {
    if (_estBloque) return;

    final pinStocke = await _storage.read(key: 'user_pin');

    if (_pin == pinStocke) {
      //Code Secret correct → réinitialiser les compteurs
      _tentatives = 0;
      _nbBlocages = 0;
      await _storage.write(key: 'nb_blocages_pin', value: '0');
      await _storage.write(key: 'tentatives_pin', value: '0');
      _naviguerVersHome();
    } else {
      //Code Secret incorrect
      _tentatives++;
      await _storage.write(
        key: 'tentatives_pin',
        value: _tentatives.toString(),
      );

      if (_tentatives >= 3) {
        _nbBlocages++;
        await _storage.write(
          key: 'nb_blocages_pin',
          value: _nbBlocages.toString(),
        );

        if (_nbBlocages >= 4) {
          // 4ème blocage → Liste noire définitive
          await _mettreSurListeNoire();
        } else {
          // Blocage temporaire selon le nombre de blocages
          int dureeBlocage;
          String messageDuree;

          switch (_nbBlocages) {
            case 1:
              dureeBlocage = 30 * 60; // 30 minutes
              messageDuree = '30 minutes';
              break;
            case 2:
              dureeBlocage = 60 * 60; // 1 heure
              messageDuree = '1 heure';
              break;
            case 3:
              dureeBlocage = 24 * 60 * 60; // 24 heures
              messageDuree = '24 heures';
              break;
            default:
              dureeBlocage = 30 * 60;
              messageDuree = '30 minutes';
          }

          _bloquerTemporairement(dureeBlocage, messageDuree);
        }
      } else {
        setState(() {
          _erreur = 'Code Secret incorrect ($_tentatives/3)';
          _pin = '';
        });
      }
    }
  }

  void _bloquerTemporairement(int dureeSecondes, String messageDuree) {
    setState(() {
      _estBloque = true;
      _secondesRestantes = dureeSecondes;
      _pin = '';
      _erreur =
          'Trop de tentatives incorrectes.\n'
          'Réessayez dans $messageDuree.';
    });

    _timerBloquage?.cancel();
    _timerBloquage = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondesRestantes > 0) {
        setState(() {
          _secondesRestantes--;
          _erreur =
              'Trop de tentatives incorrectes.\n'
              'Réessayez dans ${_formaterTemps(_secondesRestantes)}.';
        });
      } else {
        timer.cancel();
        setState(() {
          _estBloque = false;
          _tentatives = 0;
          _erreur = null;
        });
        _storage.write(key: 'tentatives_pin', value: '0');
      }
    });
  }

  String _formaterTemps(int secondes) {
    if (secondes < 60) return '$secondes secondes';
    final minutes = secondes ~/ 60;
    final secondesRestantes = secondes % 60;
    if (minutes < 60) {
      return '$minutes min ${secondesRestantes > 0 ? '${secondesRestantes}s' : ''}';
    }
    final heures = minutes ~/ 60;
    final minutesRestantes = minutes % 60;
    return '$heures h ${minutesRestantes > 0 ? '${minutesRestantes}min' : ''}';
  }

  // ═══════════════════════════════════════════════
  // MISE SUR LISTE NOIRE
  // ═══════════════════════════════════════════════
  Future<void> _mettreSurListeNoire() async {
    final userId = await _storage.read(key: 'user_id') ?? '';
    final telephone = await _storage.read(key: 'user_phone') ?? '';

    // Bloquer localement
    await _storage.write(key: 'liste_noire', value: 'true');
    await _storage.write(key: 'telephone_bloque', value: telephone);

    // Envoyer la mise à zéro des points au serveur
    try {
      await http
          .post(
            Uri.parse('$kBaseUrl/decrementerPoints.php'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idUtilisateur': userId, 'mettreAZero': true}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Erreur mise à zéro points : $e');
    }

    // Déconnecter
    await FirebaseAuth.instance.signOut();
    await _storage.deleteAll();
    await _storage.write(key: 'liste_noire', value: 'true');
    await _storage.write(key: 'telephone_bloque', value: telephone);

    if (mounted) {
      _afficherListeNoire();
    }
  }

  void _afficherListeNoire() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Config.colors.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.gpp_bad, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(
              'Accès bloqué',
              style: TextStyle(
                color: Config.colors.authTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Votre compte a été bloqué pour des raisons de sécurité.\n\n'
          'Trop de tentatives de connexion incorrectes ont été détectées.\n\n'
          'Veuillez contacter les administrateurs MVST pour assistance.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Config.colors.authTextSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Quitter ou retourner à la page de connexion
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // EMPREINTE DIGITALE
  // ═══════════════════════════════════════════════
  Future<void> _authentifierParEmpreinte() async {
    if (_estBloque) return;

    final auth = LocalAuthentication();
    try {
      final authentifie = await auth.authenticate(
        localizedReason: 'Utilisez votre empreinte pour accéder à MVST',
        biometricOnly: true,
      );
      if (authentifie && mounted) {
        _tentatives = 0;
        _nbBlocages = 0;
        await _storage.write(key: 'nb_blocages_pin', value: '0');
        await _storage.write(key: 'tentatives_pin', value: '0');
        _naviguerVersHome();
      }
    } catch (_) {}
  }

  Future<void> _activerEmpreinte() async {
    final auth = LocalAuthentication();
    try {
      final authentifie = await auth.authenticate(
        localizedReason:
            'Confirmez votre identité pour activer l\'empreinte digitale',
        biometricOnly: true,
      );
      if (authentifie && mounted) {
        await _storage.write(key: 'biometric_enabled', value: 'true');
        setState(() => _biometriqueActivee = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: const Text(
              'Empreinte digitale activée avec succès !',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            content: const Text('Erreur lors de l\'activation de l\'empreinte'),
          ),
        );
      }
    }
  }

  Future<void> _naviguerVersHome() async {
    await _storage.write(
      key: 'last_unlock_time',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    if (!mounted) return;

    if (widget.apresAuthentification != null) {
      widget.apresAuthentification!();
      Navigator.pop(context);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
        (route) => false,
      );
    }
  }

  Future<void> _seDeconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Config.colors.authCardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Se déconnecter ?',
          style: TextStyle(
            color: Config.colors.authTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Vous devrez entrer votre numéro et votre Code Secret pour vous reconnecter.',
          style: TextStyle(
            color: Config.colors.authTextSecondary,
            fontSize: 13,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: TextStyle(color: Config.colors.authTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Déconnecter',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmer == true) {
      await FirebaseAuth.instance.signOut();
      await _storage.deleteAll();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Login()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    // Facteur d'échelle basé sur une hauteur de référence (iPhone SE = 667px)
    final scale = (sh / 667).clamp(0.75, 1.4);

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 12 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ──────────────────────────────────────────────
                _Logo(colors: c, sw: sw, scale: scale),
                SizedBox(height: 16 * scale),
                // ── Nom utilisateur ────────────────────────────────────
                if (_nomUtilisateur.isNotEmpty) ...[
                  Text(
                    'Bonjour, $_nomUtilisateur',
                    style: TextStyle(
                      color: c.authTextPrimary,
                      fontSize: 17 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                ],
                // ── Sous-titre ─────────────────────────────────────────
                Text(
                  _estBloque
                      ? 'Accès temporairement bloqué'
                      : 'Entrez votre Code Secret',
                  style: TextStyle(
                    color: _estBloque ? Colors.red : c.authTextSecondary,
                    fontSize: 12 * scale,
                  ),
                ),
                SizedBox(height: 28 * scale),
                // ── Points du PIN ──────────────────────────────────────
                _PinDots(
                  longueur: _pin.length,
                  erreur: _erreur != null,
                  colors: c,
                  scale: scale,
                ),
                if (_erreur != null) ...[
                  SizedBox(height: 10 * scale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
                    child: Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _estBloque ? Colors.orange : Colors.red,
                        fontSize: 12 * scale,
                        fontWeight: _estBloque
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
                // ── Espacement flexible proportionnel ──────────────────
                SizedBox(height: 24 * scale),
                // ── Empreinte digitale ─────────────────────────────────
                if (!_estBloque && _biometriqueDisponible) ...[
                  if (_biometriqueActivee)
                    GestureDetector(
                      onTap: _authentifierParEmpreinte,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12 * scale),
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.authAccent,
                            width: 1.5 * scale,
                          ),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          color: c.authAccent,
                          size: 32 * scale,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _activerEmpreinte,
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12 * scale),
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.authAccent.withValues(alpha: 0.4),
                            width: 1.5 * scale,
                          ),
                        ),
                        child: Icon(
                          Icons.fingerprint,
                          color: c.authAccent.withValues(alpha: 0.4),
                          size: 32 * scale,
                        ),
                      ),
                    ),
                ],
                // ── Clavier numérique ──────────────────────────────────
                ClavierNumerique(
                  onChiffre: _onChiffre,
                  onSupprimer: _onSupprimer,
                  colors: c,
                  sw: sw,
                  desactive: _estBloque,
                  scale: scale,
                ),
                SizedBox(height: 16 * scale),
                // ── Code Secret oublié ─────────────────────────────────
                if (!_estBloque)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PinForgot()),
                    ),
                    child: Text(
                      'Code Secret oublié ?',
                      style: TextStyle(
                        color: c.authAccent,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: c.authAccent,
                      ),
                    ),
                  ),
                SizedBox(height: 10 * scale),
                // ── Se déconnecter ─────────────────────────────────────
                GestureDetector(
                  onTap: _seDeconnecter,
                  child: Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: 11 * scale,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final dynamic colors;
  final double sw;
  final double scale;
  const _Logo({required this.colors, required this.sw, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final size = (sw * 0.18).clamp(60.0, 100.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.authAccent, width: 2),
        color: c.authCardBackground,
      ),
      child: Center(
        child: Text(
          'MVST',
          style: TextStyle(
            color: c.authAccent,
            fontSize: size * 0.35,
            fontFamily: 'Lobster',
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int longueur;
  final bool erreur;
  final dynamic colors;
  final double scale;
  const _PinDots({
    required this.longueur,
    required this.erreur,
    required this.colors,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final dotSize = 15 * scale;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final rempli = i < longueur;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 10 * scale),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rempli ? c.authAccent : Colors.transparent,
            border: Border.all(
              color: erreur ? Colors.red : c.authAccent,
              width: 1.8 * scale,
            ),
          ),
        );
      }),
    );
  }
}

Future<bool> sessionValide() async {
  const storage = FlutterSecureStorage();
  final lastUnlock = await storage.read(key: 'last_unlock_time');
  if (lastUnlock == null) return false;
  final last = DateTime.fromMillisecondsSinceEpoch(int.parse(lastUnlock));
  final diff = DateTime.now().difference(last);
  //return diff.inSeconds < 5;
  return diff.inMinutes < 15;
}
