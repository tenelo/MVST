import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/config/config.dart';
import 'package:mvst/firebase_options.dart';
import 'package:mvst/screens/home.dart';
import 'package:mvst/screens/petitsEcrans/home2.dart';
import 'package:mvst/screens/termesDutilisation.dart';
import 'package:shared_preferences/shared_preferences.dart';

int? tailleEcran;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Désactive la rotation de l'écran en mode paysage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // L'application est en arrière-plan ou fermée
      _handleAppClosed();
    }
  }

  void _handleAppClosed() {
    // Exécuter  fonction de nettoyage
    maFonction();
  }

  void maFonction() {}

  @override
  Widget build(BuildContext context) {
    tailleEcran = calculeTailleEcran(context).round();

    return BlocProvider(
      create: (context) => BlocCompteur(),
      child: MaterialApp(
        title: 'MVST',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Config.colors.bleuFonce),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
        ],
        navigatorObservers: [CustomNavigatorObserver(onPageChange: () {})],
        home: const MonSplashScreen(),
      ),
    );
  }
}

class CustomNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPageChange;

  CustomNavigatorObserver({required this.onPageChange});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    onPageChange();
  }
}

class MonSplashScreen extends StatefulWidget {
  const MonSplashScreen({super.key});

  @override
  State<MonSplashScreen> createState() => _MonSplashScreenState();
}

class _MonSplashScreenState extends State<MonSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnTermsAcceptance();
  }

  Future<void> _navigateBasedOnTermsAcceptance() async {
    await Future.delayed(Duration(seconds: 2));
    _checkTermsAcceptance(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.colors.bleuFonce2,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.0,
              height: 120.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Config.colors.jauneBlanc,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  'MVST',
                  style: TextStyle(
                    color: Config.colors.bleuClaire,
                    fontSize: 24,
                    fontFamily: 'Lobster',
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SpinKitThreeBounce(
              color: Config.colors.jauneBlanc,
            )
          ],
        ),
      ),
    );
  }
}

Future<void> _checkTermsAcceptance(BuildContext ctx) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool termsAccepted = prefs.getBool('termesAccepté') ?? false;

  if (termsAccepted) {
    if (tailleEcran! >= 6) {
      // Si les termes sont déjà acceptés, naviguez directement vers l'application principale
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } else {
      //petits écrans , moins de 6 pouces
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (context) => const Home2()),
      );
    }
  } else {
    // Si les termes ne sont pas acceptés, naviguez vers la page des termes d'utilisation
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const AccepterTermesDutilisations()),
    );
  }
}

double calculeTailleEcran(BuildContext ctx) {
  double screenWidth = MediaQuery.of(ctx).size.width;
  double screenHeight = MediaQuery.of(ctx).size.height;
  return sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) / 160.0;
  // RECUPERATION
  // int arrondi = calculateDiagonalInches().round();
}
