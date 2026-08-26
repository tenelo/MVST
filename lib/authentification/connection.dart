// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/authentification/pin_forgot.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/models/clavier_numerique.dart';
import 'package:mvst/screens/home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Résultat de la vérification du numéro
class VerificationResult {
  final bool bloque;
  final bool existe;
  final int points;

  VerificationResult({
    required this.bloque,
    required this.existe,
    required this.points,
  });
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  static const _storage = FlutterSecureStorage();

  final _telephoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // 0 = saisie numéro, 1 = saisie PIN
  int _etape = 0;
  String _telephone = '';
  String _pin = '';
  bool _isLoading = false;
  String? _erreur;

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _erreur = null;
    });

    FocusScope.of(context).unfocus();
    final numero = _telephoneController.text.trim();
    final resultat = await _verifierNumero(numero);
    setState(() => _isLoading = false);
    if (resultat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur de vérification. Veuillez réessayer.'),
        ),
      );
      return;
    }
    // Cas 1 : Compte bloqué
    if (resultat.bloque) {
      return; // Le dialogue est déjà affiché dans _verifierNumero
    }
    // Cas 2 : Le numéro n'existe pas → rediriger vers l'inscription
    if (!resultat.existe) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PageDAuthentification()),
        );
      }
      return;
    }
    // Cas 3 : Le numéro existe et n'est pas bloqué → passer au code secret
    setState(() {
      _telephone = numero;
      _etape = 1;
      _pin = '';
      _erreur = null;
    });
  }

  Future<VerificationResult?> _verifierNumero(String numero) async {
    try {
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/verifierTelephone.php'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'telephone': numero}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          return VerificationResult(
            bloque: data['bloque'] == true,
            existe: data['existe'] == true,
            points: data['points'] ?? 0,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _onChiffre(String chiffre) {
    if (_pin.length >= 4) return;
    setState(() {
      _erreur = null;
      _pin += chiffre;
    });
    if (_pin.length == 4) _seConnecter();
  }

  void _onSupprimer() {
    if (_pin.isEmpty) return;
    setState(() {
      _erreur = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _seConnecter() async {
    setState(() => _isLoading = true);
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: '$_telephone@gmail.com',
        password: '${_pin}mv',
      );

      final user = result.user;
      if (user == null) throw Exception('Utilisateur introuvable');

      // Sauvegarde de la session locale
      await _storage.write(key: 'user_phone', value: _telephone);
      await _storage.write(key: 'user_pin', value: _pin);
      await _storage.write(key: 'user_id', value: user.uid);
      await _storage.write(key: 'user_name', value: user.displayName ?? '');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
          (route) => false,
        );
      }
    } on FirebaseAuthException {
      if (mounted) {
        setState(() {
          _erreur = 'Numéro ou Code Secret incorrect.';
          _pin = '';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erreur = 'Erreur de connexion. Réessayez.';
          _pin = '';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: _etape == 0
            ? _buildEtapeTelephone(c, sw, sh)
            : _buildEtapePin(c, sw, sh),
      ),
    );
  }

  // ── Étape 1 : numéro de téléphone ─────────────────────────────────────────

  Widget _buildEtapeTelephone(dynamic c, double sw, double sh) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final h = constraints.maxHeight;
        final keyboardH = MediaQuery.of(context).viewInsets.bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, keyboardH + 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: h * 0.10),
                _Logo(colors: c, sw: sw),
                SizedBox(height: h * 0.04),
                Text(
                  'Connexion',
                  style: TextStyle(
                    color: c.authTextPrimary,
                    fontSize: sw * 0.06,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: h * 0.008),
                Text(
                  'Entrez votre numéro pour continuer',
                  style: TextStyle(
                    color: c.authTextSecondary,
                    fontSize: sw * 0.033,
                  ),
                ),
                SizedBox(height: h * 0.045),
                Container(
                  decoration: BoxDecoration(
                    color: c.authCardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.authBorder, width: 1.5),
                  ),
                  child: TextFormField(
                    maxLength: 10,
                    cursorColor: c.authAccent,
                    style: TextStyle(
                      color: c.authTextPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      hintText: 'Ex: 0505050505',
                      hintStyle: TextStyle(
                        color: c.authTextSecondary,
                        fontSize: sw * 0.035,
                      ),
                      prefixIcon: Icon(Icons.phone_outlined, color: c.authAccent),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Veuillez entrer votre numéro';
                      }
                      if (v.length < 10) return 'Numéro invalide';
                      return null;
                    },
                  ),
                ),
                SizedBox(height: h * 0.03),
                SizedBox(
                  width: double.infinity,
                  height: sw * 0.13,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.authButton,
                      foregroundColor: c.authTextPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _continuer,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: c.authTextPrimary,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Vérification...',
                                style: TextStyle(
                                  color: c.authTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: sw * 0.038,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: h * 0.04),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Colors.white12, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.03),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: c.authTextSecondary,
                          fontSize: sw * 0.032,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Colors.white12, thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.03),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PageDAuthentification(),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pas de compte ? ',
                          style: TextStyle(
                            color: c.authTextSecondary,
                            fontSize: sw * 0.034,
                          ),
                        ),
                        TextSpan(
                          text: 'Créer un compte',
                          style: TextStyle(
                            color: c.authAccent,
                            fontSize: sw * 0.034,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: c.authAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Étape 2 : saisie PIN ──────────────────────────────────────────────────

  Widget _buildEtapePin(dynamic c, double sw, double sh) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // h = hauteur réelle disponible (tient compte AppBar, BottomNav, SafeArea)
        // sh = hauteur totale écran → ne pas l'utiliser ici pour éviter les overflows
        final h = constraints.maxHeight;
        return Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: c.authTextPrimary,
                  size: 20,
                ),
                onPressed: () => setState(() {
                  _etape = 0;
                  _pin = '';
                  _erreur = null;
                }),
              ),
            ),
            // ── Contenu scrollable : ne déborde jamais, même sur petit écran ──
            Expanded(
              child: LayoutBuilder(
                builder: (_, inner) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: inner.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Logo(colors: c, sw: sw),
                        SizedBox(height: h * 0.025),
                        Text(
                          'Entrez votre Code Secret',
                          style: TextStyle(
                            color: c.authTextPrimary,
                            fontSize: sw * 0.052,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: h * 0.01),
                        Text(
                          '+225 $_telephone',
                          style: TextStyle(
                            color: c.authAccent,
                            fontSize: sw * 0.032,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: h * 0.04),
                        _PinDots(
                          longueur: _pin.length,
                          erreur: _erreur != null,
                          colors: c,
                        ),
                        if (_erreur != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            _erreur!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        SizedBox(height: h * 0.05),
                        if (_isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: CircularProgressIndicator(
                              color: c.authAccent,
                            ),
                          )
                        else
                          ClavierNumerique(
                            onChiffre: _onChiffre,
                            onSupprimer: _onSupprimer,
                            colors: c,
                            sw: sw,
                          ),
                        SizedBox(height: h * 0.02),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PinForgot(),
                            ),
                          ),
                          child: Text(
                            'Code Secret oublié ?',
                            style: TextStyle(
                              color: c.authAccent,
                              fontSize: sw * 0.032,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: c.authAccent,
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  final dynamic colors;
  final double sw;
  const _Logo({required this.colors, required this.sw});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      width: sw * 0.20,
      height: sw * 0.20,
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
            fontSize: sw * 0.042,
            fontFamily: 'Lobster',
            letterSpacing: 1.5,
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
  const _PinDots({
    required this.longueur,
    required this.erreur,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final rempli = i < longueur;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rempli ? c.authAccent : Colors.transparent,
            border: Border.all(
              color: erreur ? Colors.red : c.authAccent,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
