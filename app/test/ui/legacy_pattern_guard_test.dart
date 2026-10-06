import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard of docs/design/ui-kit-spec.md §9 (BT-UX-KIT-001).
///
/// Each old Material pattern below has a kit piece that replaces it
/// (docs/design/ui-kit-spec.md §8). The exemption list shrinks with every
/// wave converted in docs/design/sequencia-e-esforco.md, and the ratchet in
/// the second test makes sure it can only shrink.
const _forbidden = <String, String>{
  r'\bshowModalBottomSheet\b': 'AppTileOverlay(veil: folha)',
  r'\bshowDialog\b': 'AppTileOverlay ou azulejo armado (2 toques)',
  r'\bAlertDialog\b': 'AppTileOverlay ou azulejo armado (2 toques)',
  r'\bDropdownButton(FormField|HideUnderline)?\b': 'fileira de AppChoicePiece',
  // §9.3 item 4: the old `(?<!Animated)` lookbehind had no effect and was
  // dropped; `AnimatedSwitcher(` never matches `\bSwitch\(`.
  r'\bSwitchListTile\b|\bSwitch\.adaptive\b|\bSwitch\(': 'AppRuleTile',
  r'\bCheckboxListTile\b|\bCheckbox\(|\bRadioListTile\b|\bRadio<':
      'AppRuleTile / AppChoicePiece',
  r'\bSegmentedButton<': 'AppNumeralPiece / AppShapeTile',
  r'\bExpansionTile\b': 'AppTile que abre AppTileOverlay',
  r'\bSlider\(': 'AppNumeralPiece ou AppLiveBlock',
  r'\bPopupMenuButton<': 'AppTileOverlay pequeno',
  r'\bTabBar\(': 'fileira de AppTile (a atual em latão)',
  r'\bListTile\(': 'AppTile / AppScoreRow / AppChoicePiece',
  r'\b(Filter|Action|Input|Choice)?Chip\(': 'AppTile pequeno ou AppLogPills',
  r'\bTextFormField\(|\bTextField\(': 'AppPlaque',
  r'\bOutlineInputBorder\b|filled:\s*true': 'AppPlaque: campo sem caixa',
};

/// Path prefixes that still speak the old language. Ordered by the waves of
/// docs/design/sequencia-e-esforco.md; each converted wave removes its lines
/// and lowers [_ratchet] in the same change.
const _exempt = <String>[
  // ── The theme itself: `inputDecorationTheme` (filled + OutlineInputBorder)
  //    lives here until revocation (4) of §7.1 lands with the UI capture
  //    batch (BT-UIEV-001). The token test exempts this file for the same
  //    reason.
  'lib/core/theme/app_theme.dart',

  // ── The kit's own plaque is the one legitimate host of a text field: it
  //    is the AppPlaque that every other TextField converts to (§6).
  'lib/core/widgets/app_plaque.dart',

  // ── Independent visual systems (already exempt in the token test) ──
  'lib/features/scanner/',
  'lib/features/home/lotus/',
  'lib/features/home/lotus_life_counter_screen.dart',

  // ── Native life-counter sheets: converted by the prototype session.
  'lib/features/home/life_counter/',

  // ── Wave 1 — entry door (leaves first). The decks file is covered by
  //    'lib/features/decks/' below and stays listed only as the record of
  //    the wave. The spec (§9.2) also named `ai_usage_gate.dart` and
  //    `ai_usage_meter.dart`, which do not exist in this tree.
  'lib/features/home/onboarding_core_flow_screen.dart',
  'lib/features/decks/screens/deck_generate_screen.dart',
  'lib/features/home/home_screen.dart',

  // ── Wave 2 — core (decks) ──
  'lib/features/decks/',

  // ── Wave 3 — collection ──
  'lib/features/binder/',
  'lib/features/collection/',

  // ── Wave 4 — social and trades ──
  'lib/features/trades/',
  'lib/features/social/',
  'lib/features/community/',
  'lib/features/messages/',

  // ── Wave 5 — battle ──
  'lib/features/battle/',

  // ── Wave 6 — account, plans and entry. Forms are legitimate in
  //    login/password/legal; only the non-field patterns leave.
  'lib/features/auth/',
  'lib/features/profile/',
  'lib/features/commercial/',

  // ── Rides along with the kit, without a dedicated redesign ──
  'lib/features/cards/',
  'lib/features/retention/',
  'lib/features/notifications/',
];

/// The ratchet: born equal to the exemption list length and only goes down.
/// The spec (§9.1) proposed 24; measured on this tree it is 23: the 24 paths
/// of §9.2 minus the two `ai_usage_*` files that do not exist, plus the
/// kit's own `app_plaque.dart`.
const _ratchet = 23;

bool _isExempt(String path) => _exempt.any(path.startsWith);

void main() {
  test('converted features do not fall back to the old language', () {
    final offenders = <String>[];
    final rules = {
      for (final entry in _forbidden.entries) RegExp(entry.key): entry.value,
    };

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path.replaceAll('\\', '/');
      if (_isExempt(path)) continue;

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final rule in rules.entries) {
          if (rule.key.hasMatch(line)) {
            offenders.add(
              '$path:${i + 1}: ${line.trim()}  ->  use ${rule.value}',
            );
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use the kit pieces (docs/design/ui-kit-spec.md §8). A screen that '
          'is not converted yet must be in _exempt, and leave it when its '
          'wave is done.',
    );
  });

  test('the exemption list only shrinks', () {
    expect(_exempt.toSet().length, _exempt.length, reason: 'duplicate path');
    expect(_exempt.length, lessThanOrEqualTo(_ratchet));
  });

  test('every exempt path still exists', () {
    final missing = [
      for (final path in _exempt)
        if (!File(path).existsSync() && !Directory(path).existsSync()) path,
    ];
    expect(
      missing,
      isEmpty,
      reason: 'An exempt path that no longer exists must leave the list.',
    );
  });
}
