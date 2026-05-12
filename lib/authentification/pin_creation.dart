import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/home.dart';

class PinCreation extends StatefulWidget {
  final Future<void> Function(String pin) onPinConfirmed;

  const PinCreation({super.key, required this.onPinConfirmed});

  @override
  State<PinCreation> createState() => _PinCreationState();
}

class _PinCreationState extends State<PinCreation> {
  String _pin = '';
  String _pinConfirmation = '';
  bool _confirmStep = false;
  bool _isLoading = false;
  String? _erreur;

  void _onChiffre(String chiffre) {
    setState(() => _erreur = null);
    if (_confirmStep) {
      if (_pinConfirmation.length >= 4) return;
      _pinConfirmation += chiffre;
      if (_pinConfirmation.length == 4) _validerConfirmation();
    } else {
      if (_pin.length >= 4) return;
      _pin += chiffre;
      if (_pin.length == 4) setState(() => _confirmStep = true);
    }
    setState(() {});
  }

  void _onSupprimer() {
    setState(() {
      _erreur = null;
      if (_confirmStep) {
        if (_pinConfirmation.isEmpty) {
          _confirmStep = false;
        } else {
          _pinConfirmation = _pinConfirmation.substring(
            0,
            _pinConfirmation.length - 1,
          );
        }
      } else {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }
    });
  }

  Future<void> _validerConfirmation() async {
    if (_pin != _pinConfirmation) {
      setState(() {
        _erreur = 'Le Code Secret ne correspond pas. Réessayez.';
        _pinConfirmation = '';
        _confirmStep = false;
        _pin = '';
      });
      return;
    }
    setState(() => _isLoading = true);
    await widget.onPinConfirmed(_pin);
    if (!mounted) return;

    const storage = FlutterSecureStorage();
    await storage.write(
      key: 'last_unlock_time',
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final auth = LocalAuthentication();
    final bioDispo = await auth.canCheckBiometrics;
    if (!mounted) return;

    if (bioDispo) {
      final activer = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _DialogBiometrie(colors: Config.colors),
      );
      if (activer == true && mounted) {
        await storage.write(key: 'biometric_enabled', value: 'true');
      }
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;
    final pinCourant = _confirmStep ? _pinConfirmation : _pin;

    return Scaffold(
      backgroundColor: c.authBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: sh * 0.07),
            _Logo(colors: c, sw: sw),
            SizedBox(height: sh * 0.04),
            Text(
              _confirmStep
                  ? 'Confirmez votre Code Secret'
                  : 'Créez votre Code Secret',
              style: TextStyle(
                color: c.authTextPrimary,
                fontSize: sw * 0.055,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _confirmStep
                  ? 'Saisissez à nouveau votre Code Secret'
                  : 'Choisissez un code à 4 chiffres',
              style: TextStyle(
                color: c.authTextSecondary,
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.05),
            _PinDots(
              longueur: pinCourant.length,
              erreur: _erreur != null,
              colors: c,
            ),
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
            SizedBox(height: sh * 0.04),
          ],
        ),
      ),
    );
  }
}

// ── Dialog activation biométrie ──────────────────────────────────────────────

class _DialogBiometrie extends StatelessWidget {
  final dynamic colors;
  const _DialogBiometrie({required this.colors});

  @override
  Widget build(BuildContext context) {
    final c = colors;
    return AlertDialog(
      backgroundColor: c.authCardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(Icons.fingerprint, color: c.authAccent, size: 48),
          const SizedBox(height: 12),
          Text(
            'Activer l\'empreinte ?',
            style: TextStyle(
              color: c.authTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Text(
        'Déverrouillez l\'app plus rapidement avec votre empreinte digitale.',
        textAlign: TextAlign.center,
        style: TextStyle(color: c.authTextSecondary, fontSize: 13),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Non merci',
            style: TextStyle(color: c.authTextSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: c.authAccent,
            foregroundColor: c.authBackground,
          ),
          child: const Text(
            'Activer',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
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
        children: touches.map((ligne) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ligne.map((touche) {
              if (touche.isEmpty) return SizedBox(width: sw * 0.22, height: 60);
              return _AnimatedTouche(
                touche: touche,
                onChiffre: onChiffre,
                onSupprimer: onSupprimer,
                colors: c,
                sw: sw,
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _AnimatedTouche extends StatefulWidget {
  const _AnimatedTouche({
    required this.touche,
    required this.onChiffre,
    required this.onSupprimer,
    required this.colors,
    required this.sw,
  });
  final String touche;
  final void Function(String) onChiffre;
  final VoidCallback onSupprimer;
  final dynamic colors;
  final double sw;

  @override
  State<_AnimatedTouche> createState() => _AnimatedToucheState();
}

class _AnimatedToucheState extends State<_AnimatedTouche>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _highlighted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() => _highlighted = true);
    _ctrl.forward().then((_) {
      _ctrl.reverse();
      Future.delayed(const Duration(milliseconds: 130), () {
        if (mounted) setState(() => _highlighted = false);
      });
    });
    if (widget.touche == '⌫') {
      widget.onSupprimer();
    } else {
      widget.onChiffre(widget.touche);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.sw * 0.22,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _highlighted
                ? c.authAccent.withValues(alpha: 0.20)
                : c.authCardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _highlighted
                ? [
                    BoxShadow(
                      color: c.authAccent.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: widget.touche == '⌫'
              ? Icon(
                  Icons.backspace_outlined,
                  color: _highlighted ? c.authAccent : c.authTextPrimary,
                  size: 22,
                )
              : Text(
                  widget.touche,
                  style: TextStyle(
                    color: _highlighted ? c.authAccent : c.authTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
