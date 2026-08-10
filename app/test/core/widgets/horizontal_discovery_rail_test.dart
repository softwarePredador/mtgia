import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';
import 'package:manaloom/core/widgets/horizontal_discovery_rail.dart';

void main() {
  Widget subject({required int itemCount, double width = 320}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: HorizontalDiscoveryRail(
              semanticLabel: 'Cartas da revisão',
              hintText: 'Deslize para revisar todas as cartas.',
              forwardSemanticLabel: 'Ver próximas cartas',
              backwardSemanticLabel: 'Voltar às cartas anteriores',
              hintKey: const Key('rail-hint'),
              forwardButtonKey: const Key('rail-forward'),
              backwardButtonKey: const Key('rail-backward'),
              builder: (context, controller) => SizedBox(
                height: 72,
                child: ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => SizedBox(
                    key: Key('rail-item-$index'),
                    width: 96,
                    child: Text('Carta $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows an external cue only when the content overflows', (
    tester,
  ) async {
    await tester.pumpWidget(subject(itemCount: 6));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('rail-hint')), findsOneWidget);
    expect(find.byKey(const Key('rail-forward')), findsOneWidget);
    expect(find.byKey(const Key('rail-backward')), findsNothing);
    expect(
      tester.getSemantics(find.byType(HorizontalDiscoveryRail)).label,
      contains('Cartas da revisão'),
    );
    expect(
      tester.getSemantics(find.byKey(const Key('rail-forward'))).label,
      contains('Ver próximas cartas'),
    );

    expect(find.byKey(const Key('rail-item-0')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rail-forward')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rail-item-0')), findsNothing);
    final controller = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      controller.position.pixels,
      closeTo(controller.position.maxScrollExtent, 0.1),
    );

    expect(find.byKey(const Key('rail-forward')), findsNothing);
    expect(find.byKey(const Key('rail-backward')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(subject(itemCount: 2, width: 520));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('rail-hint')), findsNothing);
    expect(find.byKey(const Key('rail-forward')), findsNothing);
    expect(find.byKey(const Key('rail-backward')), findsNothing);
  });
}
