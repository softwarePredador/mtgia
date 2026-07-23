import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

enum FcmDeliveryOutcome { delivered, invalidRegistration, failed }

typedef FcmMessageSender =
    Future<FcmDeliveryOutcome> Function({
      required String projectId,
      required String token,
      required String title,
      String? body,
      Map<String, String>? data,
    });

/// Serviço para enviar push notifications via Firebase Cloud Messaging (FCM).
///
/// Usa FCM HTTP v1 API com Service Account (OAuth2).
/// Requer arquivo `firebase-service-account.json` na raiz do server.
///
/// Doc: https://firebase.google.com/docs/cloud-messaging/send-message
class PushNotificationService {
  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;
  static Map<String, dynamic>? _serviceAccount;

  /// Carrega o Service Account JSON
  static Map<String, dynamic>? _loadServiceAccount() {
    if (_serviceAccount != null) return _serviceAccount;

    // Tenta vários caminhos possíveis
    final paths = [
      'firebase-service-account.json',
      '/app/firebase-service-account.json',
      '../firebase-service-account.json',
    ];

    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          _serviceAccount =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          print('[FCM] Service Account carregado de: $path');
          return _serviceAccount;
        } catch (e) {
          print('[FCM] Falha ao ler Service Account: ${e.runtimeType}');
        }
      }
    }

    // Também aceita via variável de ambiente (base64 encoded)
    final envSa = Platform.environment['FIREBASE_SERVICE_ACCOUNT_BASE64'];
    if (envSa != null && envSa.isNotEmpty) {
      try {
        final decoded = utf8.decode(base64Decode(envSa));
        _serviceAccount = jsonDecode(decoded) as Map<String, dynamic>;
        print('[FCM] Service Account carregado de env var');
        return _serviceAccount;
      } catch (e) {
        print('[FCM] Falha ao decodificar Service Account: ${e.runtimeType}');
      }
    }

    print('[FCM] Service Account não encontrado - push desabilitado');
    return null;
  }

  /// Gera JWT para autenticação OAuth2
  static String _createJwt(Map<String, dynamic> sa) {
    final now = DateTime.now().toUtc();
    final exp = now.add(const Duration(hours: 1));

    final header = {'alg': 'RS256', 'typ': 'JWT'};

    final payload = {
      'iss': sa['client_email'],
      'sub': sa['client_email'],
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': exp.millisecondsSinceEpoch ~/ 1000,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
    };

    final headerB64 = base64Url.encode(utf8.encode(jsonEncode(header)));
    final payloadB64 = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final signInput = '$headerB64.$payloadB64';

    // Assinar com RSA-SHA256 usando a private_key
    final privateKeyPem = sa['private_key'] as String;
    final signature = _signWithRsa256(signInput, privateKeyPem);

    return '$signInput.$signature';
  }

  /// Assina dados com RSA-SHA256 usando PEM private key
  static String _signWithRsa256(String data, String privateKeyPem) {
    Directory? tempDir;
    try {
      tempDir = Directory.systemTemp.createTempSync('fcm_');
      final keyFile = File('${tempDir.path}/key.pem')
        ..writeAsStringSync(privateKeyPem);
      if (!Platform.isWindows) {
        Process.runSync('chmod', ['600', keyFile.path]);
      }
      final dataFile = File('${tempDir.path}/data.txt')
        ..writeAsStringSync(data);
      final sigFile = File('${tempDir.path}/sig.bin');

      final result = Process.runSync('openssl', [
        'dgst',
        '-sha256',
        '-sign',
        keyFile.path,
        '-out',
        sigFile.path,
        dataFile.path,
      ]);

      if (result.exitCode != 0) {
        print('[FCM] Falha ao assinar JWT com OpenSSL');
        return '';
      }

      final signature = sigFile.readAsBytesSync();
      final sigB64 = base64Url.encode(signature).replaceAll('=', '');
      return sigB64;
    } catch (e) {
      print('[FCM] Falha ao assinar JWT: ${e.runtimeType}');
      return '';
    } finally {
      if (tempDir?.existsSync() == true) {
        try {
          tempDir!.deleteSync(recursive: true);
        } catch (_) {
          print('[FCM] Falha ao remover material temporário de assinatura');
        }
      }
    }
  }

  /// Obtém Access Token OAuth2 (com cache)
  static Future<String?> _getAccessToken() async {
    final sa = _loadServiceAccount();
    if (sa == null) return null;

    // Usar token em cache se ainda válido (com margem de 5 min)
    if (_cachedAccessToken != null && _tokenExpiry != null) {
      if (DateTime.now().toUtc().isBefore(
        _tokenExpiry!.subtract(const Duration(minutes: 5)),
      )) {
        return _cachedAccessToken;
      }
    }

    try {
      final jwt = _createJwt(sa);
      if (jwt.isEmpty) return null;

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedAccessToken = data['access_token'] as String?;
        final expiresIn = data['expires_in'] as int? ?? 3600;
        _tokenExpiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
        print('[FCM] Access Token obtido (expira em ${expiresIn}s)');
        return _cachedAccessToken;
      } else {
        print(
          '[FCM] Falha ao obter access token: status=${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      print('[FCM] Falha ao obter access token: ${e.runtimeType}');
      return null;
    }
  }

  /// Envia push notification para um usuário específico.
  /// Busca o fcm_token do usuário no banco.
  /// Silencioso: nunca lança exceção.
  static Future<void> sendToUser({
    required Pool pool,
    required String userId,
    String? actorUserId,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    await _sendToUser(
      pool: pool,
      userId: userId,
      actorUserId: actorUserId,
      title: title,
      body: body,
      data: data,
    );
  }

  @visibleForTesting
  static Future<void> sendToUserForTesting({
    required Pool pool,
    required String userId,
    String? actorUserId,
    required String title,
    String? body,
    Map<String, String>? data,
    required FcmMessageSender sender,
  }) {
    return _sendToUser(
      pool: pool,
      userId: userId,
      actorUserId: actorUserId,
      title: title,
      body: body,
      data: data,
      sender: sender,
    );
  }

  static Future<void> _sendToUser({
    required Pool pool,
    required String userId,
    String? actorUserId,
    required String title,
    String? body,
    Map<String, String>? data,
    FcmMessageSender? sender,
  }) async {
    final sa = sender == null ? _loadServiceAccount() : null;
    if (sender == null && sa == null) return;

    try {
      // Busca FCM token do usuário
      final result = await pool.execute(
        Sql.named('''
          SELECT recipient.fcm_token
          FROM users recipient
          WHERE recipient.id = @id
            AND recipient.deleted_at IS NULL
            AND (
              CAST(@actorUserId AS uuid) IS NULL
              OR EXISTS (
                SELECT 1
                FROM users actor
                WHERE actor.id = CAST(@actorUserId AS uuid)
                  AND actor.deleted_at IS NULL
              )
            )
          LIMIT 1
        '''),
        parameters: {'id': userId, 'actorUserId': actorUserId},
      );

      if (result.isEmpty) return;
      final fcmToken = result.first.toColumnMap()['fcm_token'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) return;

      final outcome = await (sender ?? _sendFcmMessageV1)(
        projectId: sa?['project_id'] as String? ?? 'test',
        token: fcmToken,
        title: title,
        body: body,
        data: data,
      );
      if (outcome == FcmDeliveryOutcome.invalidRegistration) {
        await pool.execute(
          Sql.named('''
            UPDATE users
            SET fcm_token = NULL,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = @id
              AND fcm_token = @token
          '''),
          parameters: {'id': userId, 'token': fcmToken},
        );
        print('[FCM] Token inválido removido do usuário');
      }
    } catch (e) {
      print('[FCM] Falha ao enviar push: ${e.runtimeType}');
    }
  }

  /// Envia mensagem FCM via HTTP v1 API
  static Future<FcmDeliveryOutcome> _sendFcmMessageV1({
    required String projectId,
    required String token,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      print('[FCM] Sem access token, envio abortado');
      return FcmDeliveryOutcome.failed;
    }

    final payload = {
      'message': {
        'token': token,
        'notification': {'title': title, if (body != null) 'body': body},
        if (data != null) 'data': data,
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            'channel_id': 'manaloom_notifications',
          },
        },
        'apns': {
          'payload': {
            'aps': {'sound': 'default', 'badge': 1},
          },
        },
      },
    };

    try {
      final url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('[FCM] Push enviado com sucesso');
        return FcmDeliveryOutcome.delivered;
      }
      final outcome = classifyDeliveryResponse(
        statusCode: response.statusCode,
        body: response.body,
      );
      print(
        '[FCM] Envio recusado: status=${response.statusCode} '
        'outcome=${outcome.name}',
      );
      return outcome;
    } catch (e) {
      print('[FCM] Falha na request v1: ${e.runtimeType}');
      return FcmDeliveryOutcome.failed;
    }
  }

  @visibleForTesting
  static FcmDeliveryOutcome classifyDeliveryResponse({
    required int statusCode,
    required String body,
  }) {
    if (statusCode == HttpStatus.ok) {
      return FcmDeliveryOutcome.delivered;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return FcmDeliveryOutcome.failed;
      }
      final error = decoded['error'];
      if (error is! Map<String, dynamic>) {
        return FcmDeliveryOutcome.failed;
      }
      if (statusCode == HttpStatus.notFound &&
          error['status'] == 'UNREGISTERED') {
        return FcmDeliveryOutcome.invalidRegistration;
      }

      final details = error['details'];
      if (details is! List) return FcmDeliveryOutcome.failed;
      for (final detail in details) {
        if (detail is! Map) continue;
        final type = detail['@type']?.toString() ?? '';
        final code = detail['errorCode']?.toString();
        final isFcmError = type.endsWith('google.firebase.fcm.v1.FcmError');
        if (code == 'UNREGISTERED' ||
            (code == 'INVALID_ARGUMENT' && isFcmError)) {
          return FcmDeliveryOutcome.invalidRegistration;
        }
      }
    } catch (_) {
      return FcmDeliveryOutcome.failed;
    }
    return FcmDeliveryOutcome.failed;
  }

  /// Envia push para múltiplos tokens (batch)
  static Future<void> sendToMultipleTokens({
    required List<String> tokens,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    final sa = _loadServiceAccount();
    if (sa == null) return;

    final projectId = sa['project_id'] as String;

    // FCM v1 não tem envio em batch direto, então enviamos um por um
    // mas em paralelo com limite de 10 simultâneos
    final futures = <Future<FcmDeliveryOutcome>>[];
    for (final token in tokens) {
      futures.add(
        _sendFcmMessageV1(
          projectId: projectId,
          token: token,
          title: title,
          body: body,
          data: data,
        ),
      );

      // Limitar paralelismo
      if (futures.length >= 10) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}
