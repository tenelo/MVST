import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/home.dart';

// Étapes du flux "PIN oublié"
enum _EtapePinForgot { telephone, otp, nouveauPin, confirmerPin }

class PinForgot extends StatefulWidget {
  const PinForgot({super.key});

  @override
  State<PinForgot> createState() => _PinForgotState();
}

class _PinForgotState extends State<PinForgot> {
  static const _storage = FlutterSecureStorage();
  final _telephoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _EtapePinForgot _etape = _EtapePinForgot.telephone;
  String _verificationId = '';
  String _telephone = '';
  String _nouveauPin = '';
  String _pin = '';
  bool _isLoading = false;
  String? _erreur;

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  // ── Étape 1 : envoi SMS ───────────────────────────────────────────────────

  Future<void> _envoyerSms() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _erreur = null;
    });

    _telephone = _telephoneController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+225$_telephone',
        timeout: const Duration(seconds: 180),
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) setState(() => _etape = _EtapePinForgot.nouveauPin);
          } catch (_) {}
        },
        verificationFailed: (e) {
          if (mounted) {
            setState(() {
              _erreur = 'Erreur d\'envoi du SMS. Vérifiez le numéro.';
              _isLoading = false;
            });
          }
        },
        codeSent: (verificationId, _) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _etape = _EtapePinForgot.otp;
              _isLoading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _erreur = 'Une erreur est survenue. Réessayez.';
          _isLoading = false;
        });
      }
    }
  }

  // ── Étape 2 : vérification OTP ────────────────────────────────────────────

  Future<void> _verifierOtp(String code) async {
    setState(() {
      _isLoading = true;
      _erreur = null;
      _pin = '';
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) setState(() => _etape = _EtapePinForgot.nouveauPin);
    } catch (e) {
      if (mounted) {
        String message = 'Code incorrect. Réessayez.';
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'session-expired':
              message = 'Le code a expiré. Redemandez un nouveau code.';
              break;
            case 'invalid-verification-code':
              message = 'Code incorrect. Vérifiez le SMS et réessayez.';
              break;
            case 'too-many-requests':
              message = 'Trop de tentatives. Réessayez plus tard.';
              break;
            case 'network-request-failed':
              message = 'Erreur réseau. Vérifiez votre connexion.';
              break;
          }
        }
        setState(() {
          _erreur = message;
          _pin = '';
        });
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ── Étape 3 & 4 : saisie + confirmation du nouveau Code Secret ───────────────────

  void _onChiffre(String chiffre) {
    if (_etape == _EtapePinForgot.nouveauPin) {
      if (_nouveauPin.length >= 4) return;
      setState(() {
        _erreur = null;
        _nouveauPin += chiffre;
      });
      if (_nouveauPin.length == 4) {
        setState(() => _etape = _EtapePinForgot.confirmerPin);
      }
    } else if (_etape == _EtapePinForgot.confirmerPin) {
      if (_pin.length >= 4) return;
      setState(() {
        _erreur = null;
        _pin += chiffre;
      });
      if (_pin.length == 4) _confirmerNouveauPin();
    }
  }

  void _onSupprimer() {
    setState(() {
      _erreur = null;
      if (_etape == _EtapePinForgot.confirmerPin) {
        if (_pin.isEmpty) {
          _etape = _EtapePinForgot.nouveauPin;
          _nouveauPin = '';
        } else {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_etape == _EtapePinForgot.nouveauPin) {
        if (_nouveauPin.isNotEmpty) {
          _nouveauPin = _nouveauPin.substring(0, _nouveauPin.length - 1);
        }
      }
    });
  }

  Future<void> _confirmerNouveauPin() async {
    if (_nouveauPin != _pin) {
      setState(() {
        _erreur = 'Le Code Secret ne correspond pas. Recommencez.';
        _pin = '';
        _nouveauPin = '';
        _etape = _EtapePinForgot.nouveauPin;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Appel serveur pour mettre à jour le mot de passe Firebase via Admin SDK
      final response = await http
          .post(
            Uri.parse('$kBaseUrl/reinitialiser_pin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'telephone': _telephone,
              'nouveauPin': _nouveauPin,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Reconnexion avec nouveau PIN
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: '$_telephone@gmail.com',
            password: '${_nouveauPin}mv',
          );

          // Mise à jour du PIN en local
          await _storage.write(key: 'user_pin', value: _nouveauPin);
          await _storage.write(key: 'user_phone', value: _telephone);

          final user = FirebaseAuth.instance.currentUser;
          if (user?.displayName != null) {
            await _storage.write(key: 'user_name', value: user!.displayName!);
          }
          if (user != null) {
            await _storage.write(key: 'user_id', value: user.uid);
          }

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Home()),
              (route) => false,
            );
          }
          return;
        }
      }
      if (mounted) {
        setState(
          () => _erreur =
              'Impossible de réinitialiser le PIN. Contactez le support.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = 'Erreur réseau. Vérifiez votre connexion.');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: c.authTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: switch (_etape) {
          _EtapePinForgot.telephone => _buildTelephone(c, sw, sh),
          _EtapePinForgot.otp => _buildOtp(c, sw, sh),
          _EtapePinForgot.nouveauPin ||
          _EtapePinForgot.confirmerPin => _buildNouveauPin(c, sw, sh),
        },
      ),
    );
  }

  // ── Écran téléphone ───────────────────────────────────────────────────────

  Widget _buildTelephone(dynamic c, double sw, double sh) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(sw * 0.08, 0, sw * 0.08, keyboardH + 20),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: sh * 0.04),
            Icon(Icons.lock_reset_outlined, color: c.authAccent, size: 56),
            SizedBox(height: sh * 0.03),
            Text(
              'Code Secret oublié ?',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.01),
            Text(
              'Entrez votre numéro pour recevoir un code SMS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.authTextSecondary,
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.05),
            Container(
              decoration: BoxDecoration(
                color: c.authCardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.authBorder, width: 1.5),
              ),
              child: TextFormField(
                controller: _telephoneController,
                maxLength: 10,
                keyboardType: TextInputType.phone,
                cursorColor: c.authAccent,
                style: TextStyle(
                  color: c.authTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Ex: 0505050505',
                  hintStyle: TextStyle(color: c.authTextSecondary),
                  prefixIcon: Icon(Icons.phone_outlined, color: c.authAccent),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                validator: (v) =>
                    (v == null || v.length < 10) ? 'Numéro invalide' : null,
              ),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 10),
              Text(
                _erreur!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            SizedBox(height: sh * 0.04),
            SizedBox(
              width: double.infinity,
              height: sh * 0.058,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _envoyerSms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.authButton,
                  foregroundColor: c.authTextPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: c.authTextPrimary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Recevoir le code SMS',
                        style: TextStyle(
                          fontSize: sw * 0.038,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Écran OTP ─────────────────────────────────────────────────────────────

  Widget _buildOtp(dynamic c, double sw, double sh) {
    return Column(
      children: [
        SizedBox(height: sh * 0.04),
        Icon(Icons.sms_outlined, color: c.authAccent, size: 56),
        SizedBox(height: sh * 0.03),
        Text(
          'Code de vérification',
          style: TextStyle(
            color: c.authTextPrimary,
            fontSize: sw * 0.052,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.01),
        Text(
          'Code envoyé au +225 $_telephone',
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
          _ClavierOtp(
            pin: _pin,
            onChiffre: (chiffre) {
              if (_pin.length < 6) {
                setState(() {
                  _erreur = null;
                  _pin += chiffre;
                });
                if (_pin.length == 6) _verifierOtp(_pin);
              }
            },
            onSupprimer: () {
              if (_pin.isNotEmpty) {
                setState(() => _pin = _pin.substring(0, _pin.length - 1));
              }
            },
            colors: c,
            sw: sw,
          ),
        SizedBox(height: sh * 0.04),
      ],
    );
  }

  // ── Écran nouveau PIN ─────────────────────────────────────────────────────

  Widget _buildNouveauPin(dynamic c, double sw, double sh) {
    final enConfirmation = _etape == _EtapePinForgot.confirmerPin;
    final pinCourant = enConfirmation ? _pin : _nouveauPin;

    return Column(
      children: [
        SizedBox(height: sh * 0.07),
        Icon(Icons.lock_outline, color: c.authAccent, size: 48),
        SizedBox(height: sh * 0.03),
        Text(
          enConfirmation
              ? 'Confirmez votre Code Secret'
              : 'Nouveau Code Secret',
          style: TextStyle(
            color: c.authTextPrimary,
            fontSize: sw * 0.055,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sh * 0.01),
        Text(
          enConfirmation
              ? 'Saisissez à nouveau votre Code Secret'
              : 'Choisissez un nouveau code à 4 chiffres',
          style: TextStyle(color: c.authTextSecondary, fontSize: sw * 0.032),
        ),
        SizedBox(height: sh * 0.05),
        _PinDots(
          longueur: pinCourant.length,
          erreur: _erreur != null,
          colors: c,
        ),
        if (_erreur != null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
            child: Text(
              _erreur!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
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
        SizedBox(height: sh * 0.04),
      ],
    );
  }
}

// ── Clavier OTP (6 chiffres) ──────────────────────────────────────────────────

class _ClavierOtp extends StatelessWidget {
  final String pin;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double sw;

  const _ClavierOtp({
    required this.pin,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.sw,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    // Affichage 6 cases OTP
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final rempli = i < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: sw * 0.11,
              height: sw * 0.13,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rempli
                    ? c.authAccent.withValues(alpha: 0.15)
                    : c.authCardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: rempli ? c.authAccent : c.authBorder,
                  width: 1.5,
                ),
              ),
              child: rempli
                  ? Text(
                      '•',
                      style: TextStyle(
                        color: c.authAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            );
          }),
        ),
        const SizedBox(height: 24),
        _Clavier(
          onChiffre: onChiffre,
          onSupprimer: onSupprimer,
          colors: c,
          sw: sw,
        ),
      ],
    );
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

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
        children: touches.map((ligne) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ligne.map((touche) {
              if (touche.isEmpty) return SizedBox(width: sw * 0.22, height: 60);
              return GestureDetector(
                onTap: () => touche == '⌫' ? onSupprimer() : onChiffre(touche),
                child: Container(
                  width: sw * 0.22,
                  height: 60,
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.authCardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: touche == '⌫'
                      ? Icon(
                          Icons.backspace_outlined,
                          color: c.authTextPrimary,
                          size: 22,
                        )
                      : Text(
                          touche,
                          style: TextStyle(
                            color: c.authTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
