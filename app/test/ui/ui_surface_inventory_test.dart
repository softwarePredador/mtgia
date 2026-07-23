import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final inventory = _loadInventory();

  test('every inventory domain declares the complete UX contract', () {
    expect(inventory.schemaVersion, 1);
    expect(inventory.inventoryId, isNotEmpty);
    expect(inventory.requiredContractFields, isNotEmpty);

    final findings = <String>[];
    for (final entry in inventory.domainContracts.entries) {
      final domain = entry.key;
      final contract = entry.value;
      for (final field in inventory.requiredContractFields) {
        final value = contract[field];
        final isEmptyString = value is String && value.trim().isEmpty;
        final isEmptyList = value is List && value.isEmpty;
        if (value == null || isEmptyString || isEmptyList) {
          findings.add('$domain is missing $field');
        }
      }

      final states = contract['states'];
      if (states is! List || states.any((state) => state is! String)) {
        findings.add('$domain states must be a non-empty string list');
      }
      final criticality = contract['criticality'];
      if (criticality != 'P0' && criticality != 'P1' && criticality != 'P2') {
        findings.add('$domain has invalid criticality $criticality');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Todo domínio precisa declarar job, owner, source of truth, estados, '
          'stable key, criticidade, ação, sucesso, recuperação e deep link:\n'
          '${findings.join('\n')}',
    );
  });

  test('all GoRouter routes are explicitly classified in source order', () {
    final source = File('lib/main.dart').readAsStringSync();
    final actualPaths = _extractGoRoutePaths(source);
    final expectedPaths = inventory.routeSurfaces
        .map((route) => route.declaredPath)
        .toList(growable: false);

    expect(actualPaths, expectedPaths);
    expect(actualPaths.length, inventory.expectedTotals['go_route']);

    final ids = <String>{};
    final canonicalPaths = <String>{};
    final findings = <String>[];
    for (final route in inventory.routeSurfaces) {
      if (!ids.add(route.id)) findings.add('duplicate id ${route.id}');
      if (!canonicalPaths.add(route.canonicalPath)) {
        findings.add('duplicate canonical path ${route.canonicalPath}');
      }
      if (!route.canonicalPath.startsWith('/')) {
        findings.add('${route.id} canonical path must start with /');
      }
      if (route.screen.isEmpty) findings.add('${route.id} has no screen');
      if (!inventory.domainContracts.containsKey(route.domain)) {
        findings.add('${route.id} references unknown domain ${route.domain}');
      }
      if (!const {
        'active',
        'deferred_by_scope',
        'compatibility_redirect',
      }.contains(route.scope)) {
        findings.add('${route.id} has invalid scope ${route.scope}');
      }
    }

    expect(
      findings,
      isEmpty,
      reason:
          'Rotas precisam de identidade, destino e escopo únicos:\n'
          '${findings.join('\n')}',
    );
  });

  test('all dialogs, sheets, menus, tabs and transients are inventoried', () {
    final actual = _scanSourceSurfaces(Directory(inventory.sourceRoot));
    final expected = <String, Map<String, int>>{};
    final findings = <String>[];

    for (final surface in inventory.sourceSurfaces) {
      if (expected.containsKey(surface.source)) {
        findings.add('duplicate source contract ${surface.source}');
      }
      if (!File(surface.source).existsSync()) {
        findings.add('missing source file ${surface.source}');
      }
      if (!inventory.domainContracts.containsKey(surface.domain)) {
        findings.add(
          '${surface.source} references unknown domain ${surface.domain}',
        );
      }
      for (final occurrence in surface.occurrences.entries) {
        if (!_surfacePatterns.containsKey(occurrence.key)) {
          findings.add('${surface.source} has unknown kind ${occurrence.key}');
        }
        if (occurrence.value <= 0) {
          findings.add('${surface.source} ${occurrence.key} must be positive');
        }
      }
      expected[surface.source] = surface.occurrences;
    }

    expect(
      findings,
      isEmpty,
      reason: 'Contratos de superfície inválidos:\n${findings.join('\n')}',
    );
    expect(
      actual,
      expected,
      reason:
          'Uma superfície foi adicionada, removida ou trocada sem classificação. '
          'Atualize o código e ui_surface_inventory.json na mesma mudança.',
    );
  });

  test('inventory totals remain internally consistent', () {
    final totals = <String, int>{'go_route': inventory.routeSurfaces.length};
    for (final surface in inventory.sourceSurfaces) {
      for (final occurrence in surface.occurrences.entries) {
        totals.update(
          occurrence.key,
          (value) => value + occurrence.value,
          ifAbsent: () => occurrence.value,
        );
      }
    }

    expect(totals, inventory.expectedTotals);
    expect(
      totals.values.reduce((a, b) => a + b),
      237,
      reason: 'A baseline corrente classifica exatamente 237 superfícies.',
    );
  });
}

final Map<String, RegExp> _surfacePatterns = {
  'shell_route': RegExp(r'\bShellRoute\s*\('),
  'material_page_route': RegExp(r'\bMaterialPageRoute(?:<[^>]+>)?\s*\('),
  'dialog': RegExp(
    r'\b(?:showDialog|showGeneralDialog|showAdaptiveDialog)'
    r'(?:<[^>]+>)?\s*\(',
  ),
  'bottom_sheet': RegExp(
    r'\b(?:showModalBottomSheet|showBottomSheet)(?:<[^>]+>)?\s*\(',
  ),
  'menu': RegExp(
    r'\b(?:showMenu(?:<[^>]+>)?|PopupMenuButton(?:<[^>]+>)?|MenuAnchor)'
    r'\s*\(',
  ),
  'tabs': RegExp(r'\bTabBar\s*\('),
  'navigation': RegExp(
    r'\b(?:NavigationRail|NavigationBar|BottomNavigationBar|Drawer|'
    r'NavigationDrawer)\s*\(',
  ),
  'transient': RegExp(r'\bSnackBar\s*\('),
};

_Inventory _loadInventory() {
  final file = File('test/ui/fixtures/ui_surface_inventory.json');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return _Inventory.fromJson(decoded);
}

List<String> _extractGoRoutePaths(String source) {
  final paths = <String>[];
  final constructor = RegExp(r'\bGoRoute\s*\(');
  var offset = 0;

  while (true) {
    final match = constructor.firstMatch(source.substring(offset));
    if (match == null) break;
    final start = offset + match.start;
    final openParen = source.indexOf('(', start);
    final end = _findMatchingParen(source, openParen);
    if (end == null) {
      throw FormatException('Unclosed GoRoute at source offset $start');
    }
    final block = source.substring(start, end + 1);
    final pathMatch = RegExp(
      r'''\bpath:\s*(?:'([^']+)'|"([^"]+)"|([A-Za-z_][A-Za-z0-9_]*))''',
    ).firstMatch(block);
    if (pathMatch == null) {
      throw FormatException('GoRoute without a supported path at $start');
    }
    paths.add(pathMatch.group(1) ?? pathMatch.group(2) ?? pathMatch.group(3)!);
    offset = start + match.group(0)!.length;
  }
  return paths;
}

int? _findMatchingParen(String source, int openParen) {
  var depth = 0;
  var quote = '';
  var escaped = false;
  for (var index = openParen; index < source.length; index++) {
    final character = source[index];
    if (quote.isNotEmpty) {
      if (escaped) {
        escaped = false;
      } else if (character == r'\') {
        escaped = true;
      } else if (character == quote) {
        quote = '';
      }
      continue;
    }
    if (character == "'" || character == '"') {
      quote = character;
      continue;
    }
    if (character == '(') depth++;
    if (character == ')') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return null;
}

Map<String, Map<String, int>> _scanSourceSurfaces(Directory root) {
  final result = <String, Map<String, int>>{};
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final source = file.readAsStringSync();
    final occurrences = <String, int>{};
    for (final pattern in _surfacePatterns.entries) {
      final count = pattern.value.allMatches(source).length;
      if (count > 0) occurrences[pattern.key] = count;
    }
    if (occurrences.isNotEmpty) {
      result[file.path] = occurrences;
    }
  }
  return result;
}

class _Inventory {
  const _Inventory({
    required this.schemaVersion,
    required this.inventoryId,
    required this.sourceRoot,
    required this.requiredContractFields,
    required this.expectedTotals,
    required this.domainContracts,
    required this.routeSurfaces,
    required this.sourceSurfaces,
  });

  factory _Inventory.fromJson(Map<String, dynamic> json) {
    return _Inventory(
      schemaVersion: json['schema_version'] as int,
      inventoryId: json['inventory_id'] as String,
      sourceRoot: json['source_root'] as String,
      requiredContractFields:
          (json['required_contract_fields'] as List<dynamic>).cast<String>(),
      expectedTotals: (json['expected_totals'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
      domainContracts: (json['domain_contracts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as Map<String, dynamic>),
      ),
      routeSurfaces: (json['route_surfaces'] as List<dynamic>)
          .map((value) => _RouteSurface.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      sourceSurfaces: (json['source_surfaces'] as List<dynamic>)
          .map(
            (value) => _SourceSurface.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final int schemaVersion;
  final String inventoryId;
  final String sourceRoot;
  final List<String> requiredContractFields;
  final Map<String, int> expectedTotals;
  final Map<String, Map<String, dynamic>> domainContracts;
  final List<_RouteSurface> routeSurfaces;
  final List<_SourceSurface> sourceSurfaces;
}

class _RouteSurface {
  const _RouteSurface({
    required this.id,
    required this.declaredPath,
    required this.canonicalPath,
    required this.screen,
    required this.domain,
    required this.scope,
  });

  factory _RouteSurface.fromJson(Map<String, dynamic> json) {
    return _RouteSurface(
      id: json['id'] as String,
      declaredPath: json['declared_path'] as String,
      canonicalPath: json['canonical_path'] as String,
      screen: json['screen'] as String,
      domain: json['domain'] as String,
      scope: json['scope'] as String,
    );
  }

  final String id;
  final String declaredPath;
  final String canonicalPath;
  final String screen;
  final String domain;
  final String scope;
}

class _SourceSurface {
  const _SourceSurface({
    required this.source,
    required this.domain,
    required this.occurrences,
  });

  factory _SourceSurface.fromJson(Map<String, dynamic> json) {
    return _SourceSurface(
      source: json['source'] as String,
      domain: json['domain'] as String,
      occurrences: (json['occurrences'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }

  final String source;
  final String domain;
  final Map<String, int> occurrences;
}
