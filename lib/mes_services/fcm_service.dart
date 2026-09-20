import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mvst/main.dart';
import 'package:mvst/mes_services/auth_service.dart';
import 'package:mvst/screens/suggestions.dart';
import 'package:mvst/services/api_client.dart';
import 'package:mvst/mes_services/annonces_store.dart';
import 'package:mvst/screens/annonces_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _canal = AndroidNotificationChannel(
    'mvst_client_canal',
    'Notifications MVST',
    description: 'Notifications de suggestions',
    importance: Importance.high,
  );

  static Future<void> initialiser() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          // Le payload embarque deja titre/message avec fallback applique
          // (voir onMessage.listen) ; si jamais absent, _sauvegarderAnnonceSiDiffusion
          // retombe sur des valeurs par defaut et AnnoncesStore.ajouter
          // deduplique par id avec l'annonce deja sauvegardee a la reception.
          final data = Map<String, dynamic>.from(jsonDecode(payload));
          _gererTapData(data);
        } catch (_) {}
      },
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_canal);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        final data = Map<String, dynamic>.from(message.data);
        // Fallback titre/message depuis notification si absents du data —
        // reutilise pour le payload de la notif locale, afin qu'un tap
        // dessus (onDidReceiveNotificationResponse) recupere les memes
        // valeurs plutot que de retomber sur les defauts de _sauvegarderAnnonceSiDiffusion.
        data['titre'] ??= notif.title;
        data['message'] ??= notif.body;

        _localNotif.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _canal.id,
              _canal.name,
              channelDescription: _canal.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(data),
        );

        // Sauvegarde immediate de l'annonce des la reception (premier plan),
        // independamment d'un tap eventuel sur la notif locale. La dedup
        // par id dans AnnoncesStore.ajouter empeche tout doublon si
        // l'utilisateur tape ensuite dessus (-> _gererTapData rappelle
        // le meme id).
        _sauvegarderAnnonceSiDiffusion(data);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _gererTap(message);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gererTap(initial);
      });
    }
  }

  static void _ouvrirSuggestions() {
    final nav = navigatorKeyClient.currentState;
    if (nav == null) return;
    final uid = AuthService.getUid();
    if (uid == null || uid.isEmpty) return;
    nav.push(MaterialPageRoute(builder: (_) => Suggestions(idUtilisateur: uid, ongletInitial: 1)));
  }

  static Future<void> _gererTap(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    // Fallback titre/message depuis notification si absents du data.
    data['titre'] ??= message.notification?.title;
    data['message'] ??= message.notification?.body;
    await _gererTapData(data);
  }

  /// Construit et persiste l'annonce si data decrit une diffusion.
  /// Partagee entre la reception premier plan (onMessage.listen) et le tap
  /// (onMessageOpenedApp / getInitialMessage / onDidReceiveNotificationResponse) ;
  /// AnnoncesStore.ajouter deduplique par id, donc l'appeler deux fois pour
  /// la meme annonce (reception puis tap) est sans effet de bord.
  static Future<void> _sauvegarderAnnonceSiDiffusion(
    Map<String, dynamic> data,
  ) async {
    if (data['type'] != 'diffusion') return;
    final annonce = Annonce(
      id: data['idAnnonce']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}',
      titre: data['titre']?.toString() ?? 'Annonce',
      message: data['message']?.toString() ?? '',
      date: DateTime.now(),
    );
    await AnnoncesStore.ajouter(annonce);
  }

  static Future<void> _gererTapData(Map<String, dynamic> data) async {
    if (data['type'] == 'diffusion') {
      // Sauvegarde deja faite a la reception si le premier plan l'a vue
      // passer ; ce rappel couvre le tap arriere-plan/cold-start et sert
      // de filet (dedup par id) sinon.
      await _sauvegarderAnnonceSiDiffusion(data);
      _ouvrirAnnonces();
    } else {
      _ouvrirSuggestions();
    }
  }

  static void _ouvrirAnnonces() {
    final nav = navigatorKeyClient.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(builder: (_) => const AnnoncesScreen()));
  }

  static Future<void> enregistrerTokenSiConnecte() async {
    final id = AuthService.getUid();
    if (id == null || id.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await ApiClient.instance.post(
        'device-tokens/enregistrer',
        body: {
          'type_compte': 'utilisateur',
          'id_compte': id,
          'token': token,
          'plateforme': 'android',
        },
      );
    } catch (e) {
    }
  }
}
