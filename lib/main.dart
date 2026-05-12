import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mvst/authentification/connection.dart';
import 'package:mvst/screens/home.dart';
import 'package:mvst/bloc/bloc.dart';
import 'package:mvst/config/config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:mvst/firebase_options.dart';
import 'package:mvst/models/mesFonctions.dart';
import 'package:mvst/screens/termesDutilisation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Config.chargerTheme();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late ReceivePort receivePort;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isolationDeTaches();
  }

  Future<void> _isolationDeTaches() async {
    receivePort = ReceivePort();
    try {
      await Isolate.spawn(_tachesArrierePlan, receivePort.sendPort);
    } catch (e) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    receivePort.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      suppressionPlacesTemporaires();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        supportedLocales: const [Locale('fr', '')],
        navigatorObservers: [
          routeObserver,
          CustomNavigatorObserver(onPageChange: () {}),
        ],
        // ── Calcul taille écran au démarrage ────────────────────────────
        builder: (context, child) {
          final size = MediaQuery.of(context).size;
          final dpr = MediaQuery.of(context).devicePixelRatio;
          final ppi = dpr * 160;
          final double wPhysique = size.width * dpr;
          final double hPhysique = size.height * dpr;
          final double diagonaleInches =
              sqrt(wPhysique * wPhysique + hPhysique * hPhysique) / ppi;
          petitEcran = diagonaleInches <= 5.5; // ← seuil 5.5 pouces
          return child!;
        },
        home: const MonSplashScreen(),
      ),
    );
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
    await Future.delayed(const Duration(seconds: 2));    _checkTermsAcceptance(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  color: Config.colors.bleuFonce2,
                  width: 2.10,
                ),
              ),
              child: Center(
                child: Text(
                  'MVST',
                  style: TextStyle(
                    color: Config.colors.bleuFonce2,
                    fontSize: 24,
                    fontFamily: 'Lobster',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SpinKitThreeBounce(color: Config.colors.bleuFonce2),
          ],
        ),
      ),
    );
  }
}

// ── Navigation après splash ────────────────────────────────────────────────────
Future<void> _checkTermsAcceptance(BuildContext ctx) async {
  final prefs = await SharedPreferences.getInstance();
  final termsAccepted = prefs.getBool('termesAccepté') ?? false;

  if (!termsAccepted) {
    if (ctx.mounted) {
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccepterTermesDutilisations()),
      );
    }
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    if (ctx.mounted) {
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
    return;
  }

  // Session Firebase active — vérifier que le PIN local est présent
  const storage = FlutterSecureStorage();
  final pin = await storage.read(key: 'user_pin');

  if (pin == null) {
    // Ancien utilisateur sans PIN (avant mise à jour) → déconnexion propre
    await FirebaseAuth.instance.signOut();
    if (ctx.mounted) {
      Navigator.of(ctx).pushReplacement(
        MaterialPageRoute(builder: (_) => const Login()),
      );
    }
    return;
  }

  // Session Firebase active + PIN présent → Home directement, sans code secret
  if (ctx.mounted) {
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }
}

// ── Tâches en arrière-plan ─────────────────────────────────────────────────────
void _tachesArrierePlan(SendPort sendPort) async {
  try {
    await suppressionPlacesTemporaires();
  } catch (e) {}
}
