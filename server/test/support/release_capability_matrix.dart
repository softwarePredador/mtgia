import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../lib/release_capability_policy.dart';

/// Capabilities do núcleo da beta (D-07): catálogo, decks e fichário abertos;
/// o resto, fechado. É a matriz em que as contenções precisam segurar.
const betaCoreCapabilities = <String>{
  'catalog_private',
  'decks_private',
  'collection_private',
};

/// Política válida com só [open] ligadas, lida da cópia do manifesto
/// canônico num diretório temporário (apagado ao fim do teste).
ReleaseCapabilityPolicy releaseCapabilityPolicyWith(Set<String> open) {
  final unknown = open.difference(releaseCapabilityKeys);
  if (unknown.isNotEmpty) {
    throw ArgumentError('capabilities desconhecidas: $unknown');
  }
  final decoded =
      jsonDecode(File(releaseCapabilitiesDefaultPath).readAsStringSync())
          as Map<String, dynamic>;
  final capabilities = decoded['capabilities'] as Map<String, dynamic>;
  for (final key in releaseCapabilityKeys) {
    final entry = capabilities[key] as Map<String, dynamic>;
    final allowed = open.contains(key);
    entry['allowed'] = allowed;
    entry['release_capability'] = allowed ? 'on' : 'off';
  }
  final directory = Directory.systemTemp.createTempSync(
    'brewtact-capability-matrix-',
  );
  addTearDown(() => directory.deleteSync(recursive: true));
  final file = File('${directory.path}/release_capabilities.json')
    ..writeAsStringSync(jsonEncode(decoded));
  final policy = ReleaseCapabilityPolicy.load(configPath: file.path);
  if (!policy.isValid) {
    throw StateError('a matriz de teste gerou uma política inválida');
  }
  return policy;
}
