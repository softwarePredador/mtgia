import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/widgets/player_identity_name.dart';

void main() {
  testWidgets('clamps visually and preserves the complete accessible name', (
    tester,
  ) async {
    const longName = 'Marina — Arquivista de Comandantes do Litoral Paulista';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: PlayerIdentityName(
              key: Key('identity-name'),
              name: longName,
              style: TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(longName));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      tester.getSemantics(find.byKey(const Key('identity-name'))).label,
      'Nome do jogador: $longName',
    );
    expect(tester.takeException(), isNull);
  });
}
