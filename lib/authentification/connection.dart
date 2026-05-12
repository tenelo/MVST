// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/authentification/pin_forgot.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/home.dart';

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

  void _passerAuPin() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _telephone = _telephoneController.text.trim();
      _etape = 1;
      _pin = '';
      _erreur = null;
    });
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
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, keyboardH + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: sh * 0.10),
            _Logo(colors: c, sw: sw),
            SizedBox(height: sh * 0.04),
            Text(
              'Connexion',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.06,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: sh * 0.008),
            Text(
              'Entrez votre numéro pour continuer',
              style: TextStyle(
                color: c.authTextSecondary,
                fontSize: sw * 0.033,
              ),
            ),
            SizedBox(height: sh * 0.045),
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
                  contentPadding: EdgeInsets.symmetric(vertical: sh * 0.018),
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
            SizedBox(height: sh * 0.03),
            SizedBox(
              width: double.infinity,
              height: sh * 0.058,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButton,
                  foregroundColor: c.authTextPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _passerAuPin,
                child: Text(
                  'Continuer',
                  style: TextStyle(
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: sh * 0.04),
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
            SizedBox(height: sh * 0.03),
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
  }

  // ── Étape 2 : saisie PIN ──────────────────────────────────────────────────

  Widget _buildEtapePin(dynamic c, double sw, double sh) {
    return Column(
      children: [
        // Retour à l'étape numéro
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
        SizedBox(height: sh * 0.03),
        _Logo(colors: c, sw: sw),
        SizedBox(height: sh * 0.03),
        Text(
          'Entrez votre Code Secret',
          style: TextStyle(
            color: c.authTextPrimary,
            fontSize: sw * 0.052,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.01),
        Text(
          '+225 $_telephone',
          style: TextStyle(
            color: c.authAccent,
            fontSize: sw * 0.032,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.05),
        _PinDots(longueur: _pin.length, erreur: _erreur != null, colors: c),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Text(
            _erreur!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        const Spacer(),
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: CircularProgressIndicator(color: c.authAccent),
          )
        else
          _Clavier(
            onChiffre: _onChiffre,
            onSupprimer: _onSupprimer,
            colors: c,
            sw: sw,
          ),
        SizedBox(height: sh * 0.025),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PinForgot()),
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
        SizedBox(height: sh * 0.04),
      ],
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

class _Clavier extends StatelessWidget {
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double sw;
  const _Clavier({
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final touches = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
      child: Column(
        children: touches
            .map(
              (ligne) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ligne.map((t) {
                  if (t.isEmpty) return SizedBox(width: sw * 0.22, height: 60);
                  return GestureDetector(
                    onTap: () => t == '⌫' ? onSupprimer() : onChiffre(t),
                    child: Container(
                      width: sw * 0.22,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.authCardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: t == '⌫'
                          ? Icon(
                              Icons.backspace_outlined,
                              color: c.authTextPrimary,
                              size: 22,
                            )
                          : Text(
                              t,
                              style: TextStyle(
                                color: c.authTextPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}
