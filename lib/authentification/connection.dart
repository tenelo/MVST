// ignore_for_file: library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mvst/authentification/authentification.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/screens/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> sauthentifier(BuildContext context, String telephone) async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "$telephone@gmail.com",
        password: telephone,
      );

      if (context.mounted) {
        FocusScope.of(context).unfocus();
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color.fromARGB(255, 249, 54, 6),
            content: Text(
              'Numéro incorrect ou compte inexistant.',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = Config.colors;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: c.authBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Logo ──────────────────────────────────────────────────
                  Container(
                    width: screenWidth * 0.22,
                    height: screenWidth * 0.22,
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
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Lobster',
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // ── Titre ─────────────────────────────────────────────────
                  Text(
                    'Connexion',
                    style: TextStyle(
                      color: c.authTextPrimary,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.008),

                  Text(
                    'Entrez votre numéro pour continuer',
                    style: TextStyle(
                      color: c.authTextSecondary,
                      fontSize: screenWidth * 0.033,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.045),

                  // ── Champ téléphone ───────────────────────────────────────
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
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        hintText: 'Ex: 0505050505',
                        hintStyle: TextStyle(
                          color: c.authTextSecondary,
                          fontSize: screenWidth * 0.035,
                        ),
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: c.authAccent,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.018,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre numéro';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ── Bouton connexion ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.058,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.authButton,
                        foregroundColor: c.authTextPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _isLoading = true);
                                await sauthentifier(
                                    context, _phoneNumberController.text);
                              }
                            },
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
                              'Se connecter',
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: Divider(color: Colors.white12, thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: c.authTextSecondary,
                            fontSize: screenWidth * 0.032,
                          ),
                        ),
                      ),
                      const Expanded(
                          child: Divider(color: Colors.white12, thickness: 1)),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // ── Créer un compte ───────────────────────────────────────
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PageDAuthentification(),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Pas de compte ? ',
                            style: TextStyle(
                              color: c.authTextSecondary,
                              fontSize: screenWidth * 0.034,
                            ),
                          ),
                          TextSpan(
                            text: 'Créer un compte',
                            style: TextStyle(
                              color: c.authAccent,
                              fontSize: screenWidth * 0.034,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: c.authAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
