import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mvst/config/config.dart';
import 'package:mvst/services/token_storage.dart';

/// Couche réseau centralisée. Non branchée sur les écrans existants pour
/// l'instant : ils continuent d'appeler `http.get`/`http.post` directement.
/// Une fois le login Laravel disponible, un écran migrera vers ceci pour
/// bénéficier automatiquement de l'en-tête Authorization.
///
/// Exemple d'utilisation future :
/// ```dart
/// final api = ApiClient.instance;
/// final res = await api.post('ajouterTickets.php', body: payload);
/// final data = jsonDecode(res.body); // parsing inchangé, comme aujourd'hui
/// if (data['success'] == true) { ... }
/// ```
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Timeout appliqué quand aucun n'est passé explicitement à get()/post().
  /// Le code existant utilise 5, 8 ou 10s selon les écrans ; 15s ici est une
  /// valeur par défaut large, à surcharger au cas par cas lors de la
  /// migration de chaque écran pour retrouver son timeout d'origine.
  static const Duration _timeoutParDefaut = Duration(seconds: 15);

  /// Instance partagée, pratique pour un appel ponctuel depuis un écran
  /// sans avoir à gérer soi-même le cycle de vie d'un http.Client.
  static final ApiClient instance = ApiClient();

  final http.Client _client;

  Uri _uri(String path) {
    final chemin = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$kBaseUrl/$chemin');
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await TokenStorage.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Note : en cas de dépassement, .timeout() lève une TimeoutException,
  // exactement comme le .timeout() déjà utilisé partout dans l'app
  // aujourd'hui — les try/catch existants continueront de la capturer tels
  // quels une fois un écran migré sur ApiClient.
  Future<http.Response> get(String path, {Duration? timeout}) async {
    return _client
        .get(_uri(path), headers: await _headers())
        .timeout(timeout ?? _timeoutParDefaut);
  }

  Future<http.Response> post(
    String path, {
    Object? body,
    Duration? timeout,
  }) async {
    return _client
        .post(
          _uri(path),
          headers: await _headers(),
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(timeout ?? _timeoutParDefaut);
  }

  void close() => _client.close();
}
