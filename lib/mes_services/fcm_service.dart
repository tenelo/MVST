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
          payload: jsonEncode(message.data),
        );
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

  static Future<void> _gererTapData(Map<String, dynamic> data) async {
    if (data['type'] == 'diffusion') {
      // Sauvegarde locale de l'annonce (A3-a : au tap) puis ouverture de l'ecran.
      final annonce = Annonce(
        id: data['idAnnonce']?.toString() ??
            '${DateTime.now().millisecondsSinceEpoch}',
        titre: data['titre']?.toString() ?? 'Annonce',
        message: data['message']?.toString() ?? '',
        date: DateTime.now(),
      );
      await AnnoncesStore.ajouter(annonce);
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
