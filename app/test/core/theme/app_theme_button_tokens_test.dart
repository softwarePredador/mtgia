import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/theme/app_theme.dart';

void main() {
  test('primary and secondary button tokens use ManaLoom brass contrast', () {
    final theme = AppTheme.darkTheme;
    const states = <WidgetState>{};

    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve(states),
      AppTheme.brass500,
    );
    expect(
      theme.elevatedButtonTheme.style?.foregroundColor?.resolve(states),
      AppTheme.backgroundAbyss,
    );

    expect(
      theme.filledButtonTheme.style?.backgroundColor?.resolve(states),
      AppTheme.brass500,
    );
    expect(
      theme.filledButtonTheme.style?.foregroundColor?.resolve(states),
      AppTheme.backgroundAbyss,
    );

    expect(
      theme.outlinedButtonTheme.style?.foregroundColor?.resolve(states),
      AppTheme.brass400,
    );
    expect(
      theme.textButtonTheme.style?.foregroundColor?.resolve(states),
      AppTheme.brass400,
    );

    expect(theme.floatingActionButtonTheme.backgroundColor, AppTheme.brass500);
    expect(
      theme.floatingActionButtonTheme.foregroundColor,
      AppTheme.backgroundAbyss,
    );
  });
}
