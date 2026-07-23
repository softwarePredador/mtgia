import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/config/visual_fixture.dart';

void main() {
  test('visual fixture text is deterministic only after explicit opt-in', () {
    expect(
      visualFixtureStableText(
        'Atualizado há 17min',
        fixtureText: 'Atualizado agora',
        enabled: false,
      ),
      'Atualizado há 17min',
    );
    expect(
      visualFixtureStableText(
        'Atualizado há 17min',
        fixtureText: 'Atualizado agora',
        enabled: true,
      ),
      'Atualizado agora',
    );
  });
}
