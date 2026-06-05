import 'package:flutter/material.dart';

/// ManaLoom Theme: "Obsidian + Brass + Frost Blue"
/// Dark, premium, low-noise UI — card artwork remains the main visual focus.
///
/// VISUAL BASELINE:
///   docs/MANALOOM_VISUAL_EXECUTION_BASE_2026-04-19.md
///
/// DESIGN RULES:
///   1. Brass is the primary action color.
///   2. Frost blue supports (filters, info, technical indicators) but does not lead.
///   3. Large background regions stay within the obsidian/slate family.
///   4. Gradients only for hero sections and primary buttons.
///
/// COLOR BUDGET (24 tokens):
///   10 brand/layout + 5 semantic + 6 WUBRG + 1 hint + 2 format extras = 24
///   Qualquer cor fora deste arquivo é violação.
///
/// RADIUS SCALE: radiusXs(4) / radiusSm(8) / radiusMd(12) / radiusLg(16) / radiusXl(20)
/// FONT SCALE:   fontMicro(8) / fontTiny(9) / fontXs(10) / fontSm(12) / fontMd(14) / fontLg(16) / fontXl(18) / fontXxl(20) / fontDisplay(32)
class AppTheme {
  static const String uiFontFamily = 'Inter';
  static const String displayFontFamily = 'Fraunces';

  // Explicit token to avoid using a hardcoded transparent color at call-sites.
  static const Color transparent = Color(0x00000000);

  // ── Brand palette (layout) ──────────────────────────────────
  // Core surfaces
  static const Color backgroundAbyss = Color(0xFF0F1115); // obsidian-950
  static const Color surfaceSlate = Color(0xFF171A21); // obsidian-900
  static const Color surfaceElevated = Color(0xFF232735); // slate-800

  // Product accents
  static const Color brass500 = Color(0xFFC58B2A);
  static const Color brass400 = Color(0xFFE0A93B);
  static const Color brass700 = Color(0xFF8E641B);

  static const Color frost400 = Color(0xFF6FA8DC);
  static const Color frost600 = Color(0xFF3E5F8A);

  // Back-compat brand tokens (keep call-sites stable)
  // NOTE: kept without @Deprecated to avoid analyzer noise across the app.
  static const Color manaViolet = brass500; // legacy name: primary action
  static const Color primarySoft = frost400; // legacy name: secondary/support
  static const Color mythicGold = brass400; // legacy name: gold accent

  // Text
  static const Color textPrimary = Color(0xFFF3EFE3); // ivory-100
  static const Color textSecondary = Color(0xFFB8C0CC); // mist-300
  static const Color textHint = Color(
    0xFF8A93A3,
  ); // mist-500 (hints/placeholders)
  static const Color outlineMuted = Color(0xFF2B3142); // slate-700

  // ── Deprecated aliases (backward compat) ────────────────────
  @Deprecated('Use primarySoft instead')
  static const Color loomCyan = primarySoft;
  @Deprecated('Use surfaceElevated instead')
  static const Color surfaceSlate2 = surfaceElevated;

  // ── Semantic (feedback) ─────────────────────────────────────
  static const Color success = Color(0xFF4FAF7A);
  static const Color warning = Color(0xFFD28B2C);
  static const Color error = Color(0xFFC65A46);
  static const Color disabled = textHint;

  // ── Gradients ───────────────────────────────────────────────
  // Gradients reserved for hero sections and primary buttons only.
  // Cards/lists use flat surfaceSlate or surfaceElevated.
  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundAbyss, surfaceSlate, backgroundAbyss],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceElevated, surfaceSlate, backgroundAbyss],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brass500, brass400],
  );

  /// Intentionally flat — no visible gradient on cards/list items.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceSlate, surfaceSlate],
  );

  static const LinearGradient goldAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brass400, brass700],
  );

  // ── Border Radius Scale (5 tokens) ────────────────────────
  static const double radiusXs = 4; // chips, badges, indicators
  static const double radiusSm = 8; // buttons, small containers
  static const double radiusMd = 12; // cards, panels, dialogs
  static const double radiusLg = 16; // large containers, scanner
  static const double radiusXl = 20; // pills, bottom sheets

  // ── Font Size Scale (9 tokens) ────────────────────────────
  static const double fontMicro = 8; // dense metadata, compact helper text
  static const double fontTiny = 9; // compact deck/card metadata
  static const double fontXs = 10; // badges, chips, mini-labels
  static const double fontSm = 12; // captions, labels, metadata
  static const double fontMd = 14; // body text, list items
  static const double fontLg = 16; // section titles, buttons
  static const double fontXl = 18; // section headers
  static const double fontXxl = 20; // screen titles
  static const double fontDisplay = 32; // hero / avatar placeholder

  // ── MTG WUBRG + Colorless ──────────────────────────────────
  static const Color manaW = Color(0xFFF0F2C0);
  static const Color manaU = Color(0xFFB3CEEA);
  static const Color manaB = Color(0xFFA69F9D); // Visível em gráficos
  static const Color manaR = Color(0xFFEB9F82);
  static const Color manaG = Color(0xFFC4D3CA);
  static const Color manaC = Color(0xFFB8C0CC);

  static const Map<String, Color> wubrg = {
    'W': manaW,
    'U': manaU,
    'B': manaB,
    'R': manaR,
    'G': manaG,
    'C': manaC,
  };

  // ── Format accent colors (deck card frames) ───────────────
  // Keep these restrained; avoid adding new loud accents.
  static const Color formatCommander = brass500;
  static const Color formatStandard = frost400;
  static const Color formatModern = frost600;
  static const Color formatPioneer = success;
  static const Color formatLegacy = textHint;
  static const Color formatVintage = warning;
  static const Color formatPauper = textSecondary;

  // ── Helpers derivados (sem cores novas) ────────────────────

  /// Cor de condição (NM/LP/MP/HP/DMG) — usa palette existente.
  static Color conditionColor(String condition) {
    switch (condition.toUpperCase()) {
      case 'NM':
        return success;
      case 'LP':
        return primarySoft;
      case 'MP':
        return mythicGold;
      case 'HP':
        return warning;
      case 'DMG':
        return error;
      default:
        return textSecondary;
    }
  }

  /// Cores base para fallback de pips / símbolos de mana.
  static Color manaPipBackground(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'W':
        return manaW;
      case 'U':
        return manaU;
      case 'B':
        return manaB;
      case 'R':
        return manaR;
      case 'G':
        return manaG;
      case 'C':
        return manaC;
      default:
        return textSecondary;
    }
  }

  static Color manaPipForeground(String symbol) {
    switch (symbol.toUpperCase()) {
      case 'W':
        return const Color(0xFF3D3000);
      case 'U':
        return const Color(0xFF0A2340);
      case 'B':
        return const Color(0xFF1A1A1A);
      case 'R':
        return const Color(0xFF3D1005);
      case 'G':
        return const Color(0xFF0C2E1A);
      case 'C':
        return const Color(0xFF2A2A2A);
      default:
        return textPrimary;
    }
  }

  static Color rarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return textHint;
      case 'uncommon':
        return const Color(0xFFC0C0C0);
      case 'rare':
        return const Color(0xFFFFD700);
      case 'mythic':
        return mythicGold;
      default:
        return textHint;
    }
  }

  /// Cor de score/synergy (0-100) — usa palette existente.
  static Color scoreColor(int score) {
    if (score >= 80) return success;
    if (score >= 60) return mythicGold;
    return error;
  }

  static Color identityColor(Set<String> identity) {
    if (identity.isEmpty) return manaC;
    final normalized = identity.map((e) => e.toUpperCase()).toSet();
    if (normalized.length == 1) {
      return wubrg[normalized.first] ?? manaC;
    }
    // Multi-color: keep it quiet/technical; callers can render multi-badges.
    return frost600;
  }

  static TextTheme _buildTextTheme() {
    final base = ThemeData.dark().textTheme.apply(
      fontFamily: uiFontFamily,
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    TextStyle? ui(
      TextStyle? s, {
      double? fontSize,
      FontWeight? fontWeight,
      double? height,
      double? letterSpacing,
    }) => s?.copyWith(
      fontFamily: uiFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );

    TextStyle? display(
      TextStyle? s, {
      double? fontSize,
      FontWeight? fontWeight,
      double? height,
      double? letterSpacing,
    }) => s?.copyWith(
      fontFamily: displayFontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
    );

    return base.copyWith(
      displayLarge: display(
        base.displayLarge,
        fontWeight: FontWeight.w800,
        height: 1.04,
        letterSpacing: -0.6,
      ),
      displayMedium: display(
        base.displayMedium,
        fontWeight: FontWeight.w800,
        height: 1.04,
        letterSpacing: -0.4,
      ),
      displaySmall: display(
        base.displaySmall,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: -0.3,
      ),
      headlineLarge: display(
        base.headlineLarge,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.2,
      ),
      headlineMedium: display(
        base.headlineMedium,
        fontSize: 26,
        fontWeight: FontWeight.w800,
        height: 1.08,
        letterSpacing: -0.15,
      ),
      headlineSmall: display(
        base.headlineSmall,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.08,
      ),
      titleLarge: display(
        base.titleLarge,
        fontSize: fontXl,
        fontWeight: FontWeight.w800,
        height: 1.12,
      ),
      titleMedium: ui(
        base.titleMedium,
        fontSize: fontLg,
        fontWeight: FontWeight.w700,
        height: 1.22,
        letterSpacing: -0.05,
      ),
      titleSmall: ui(
        base.titleSmall,
        fontSize: fontMd,
        fontWeight: FontWeight.w700,
        height: 1.20,
      ),
      bodyLarge: ui(
        base.bodyLarge,
        fontSize: fontLg,
        fontWeight: FontWeight.w500,
        height: 1.38,
      ),
      bodyMedium: ui(
        base.bodyMedium,
        fontSize: fontMd,
        fontWeight: FontWeight.w500,
        height: 1.36,
      ),
      bodySmall: ui(
        base.bodySmall,
        fontSize: fontSm,
        fontWeight: FontWeight.w500,
        height: 1.32,
      ),
      labelLarge: ui(
        base.labelLarge,
        fontSize: fontMd,
        fontWeight: FontWeight.w700,
        height: 1.16,
        letterSpacing: 0.05,
      ),
      labelMedium: ui(
        base.labelMedium,
        fontSize: fontSm,
        fontWeight: FontWeight.w700,
        height: 1.14,
        letterSpacing: 0.05,
      ),
      labelSmall: ui(
        base.labelSmall,
        fontSize: fontXs,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: 0.08,
      ),
    );
  }

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: brass500,
      secondary: frost400,
      tertiary: brass400,
      surface: surfaceSlate,
      surfaceContainerHighest: surfaceElevated,
      outline: outlineMuted,
      onPrimary: backgroundAbyss,
      onSecondary: backgroundAbyss,
      onTertiary: backgroundAbyss,
      onSurface: textPrimary,
    ),
    scaffoldBackgroundColor: backgroundAbyss,
    textTheme: _buildTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundAbyss,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      shadowColor: transparent,
      surfaceTintColor: transparent,
      iconTheme: IconThemeData(color: textSecondary, size: 22),
      actionsIconTheme: IconThemeData(color: textSecondary, size: 22),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontFamily: displayFontFamily,
        fontSize: fontLg + 1,
        fontWeight: FontWeight.w700,
      ),
      shape: Border(bottom: BorderSide(color: outlineMuted, width: 0.5)),
    ),
    cardTheme: CardThemeData(
      color: surfaceSlate,
      elevation: 0,
      shadowColor: transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: outlineMuted, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brass500,
        foregroundColor: backgroundAbyss,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 0,
        shadowColor: transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brass500,
        foregroundColor: backgroundAbyss,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brass400,
        side: const BorderSide(color: outlineMuted, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brass400,
        textStyle: const TextStyle(
          fontFamily: uiFontFamily,
          fontSize: fontMd,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: textSecondary,
        disabledForegroundColor: textHint,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: brass500,
      foregroundColor: backgroundAbyss,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radiusMd)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceSlate,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: outlineMuted, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: outlineMuted, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: brass400, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: outlineMuted, width: 0.5),
      ),
      elevation: 8,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceElevated,
      surfaceTintColor: transparent,
      modalBackgroundColor: surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceElevated,
      contentTextStyle: const TextStyle(
        color: textPrimary,
        fontFamily: uiFontFamily,
        fontSize: fontMd,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: outlineMuted, width: 0.5),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: brass500,
      circularTrackColor: outlineMuted,
    ),
    dividerTheme: const DividerThemeData(
      color: outlineMuted,
      thickness: 0.5,
      space: 1,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceSlate,
      selectedItemColor: brass500,
      unselectedItemColor: textSecondary,
      selectedLabelStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontXs,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontXs,
        fontWeight: FontWeight.w500,
      ),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceSlate,
      indicatorColor: brass500.withValues(alpha: 0.15),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: uiFontFamily,
            fontSize: fontXs,
            fontWeight: FontWeight.w600,
            color: brass500,
          );
        }
        return const TextStyle(
          fontFamily: uiFontFamily,
          fontSize: fontXs,
          color: textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: brass500, size: 22);
        }
        return const IconThemeData(color: textSecondary, size: 22);
      }),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surfaceElevated,
      surfaceTintColor: transparent,
      elevation: 0,
      textStyle: const TextStyle(
        color: textPrimary,
        fontFamily: uiFontFamily,
        fontSize: fontMd,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        side: const BorderSide(color: outlineMuted, width: 0.5),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        color: textPrimary,
        fontFamily: uiFontFamily,
        fontSize: fontMd,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSlate,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: outlineMuted, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: outlineMuted, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: brass400, width: 1.2),
        ),
      ),
      menuStyle: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(surfaceElevated),
        surfaceTintColor: const WidgetStatePropertyAll(transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: const BorderSide(color: outlineMuted, width: 0.5),
          ),
        ),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(surfaceElevated),
        surfaceTintColor: const WidgetStatePropertyAll(transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
            side: const BorderSide(color: outlineMuted, width: 0.5),
          ),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: textSecondary,
      textColor: textPrimary,
      selectedColor: brass400,
      selectedTileColor: surfaceSlate,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontFamily: uiFontFamily,
        fontSize: fontMd,
        fontWeight: FontWeight.w700,
      ),
      subtitleTextStyle: TextStyle(
        color: textSecondary,
        fontFamily: uiFontFamily,
        fontSize: fontSm,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brass400;
        if (states.contains(WidgetState.disabled)) return textHint;
        return textSecondary;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return brass500.withValues(alpha: 0.26);
        }
        return outlineMuted;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(outlineMuted),
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: const WidgetStatePropertyAll(backgroundAbyss),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brass500;
        return transparent;
      }),
      side: const BorderSide(color: outlineMuted, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXs),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return brass400;
        return textHint;
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brass400.withValues(alpha: 0.16);
          }
          return transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return brass400;
          return textSecondary;
        }),
        side: const WidgetStatePropertyAll(
          BorderSide(color: outlineMuted, width: 0.5),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: uiFontFamily,
            fontSize: fontSm,
            fontWeight: FontWeight.w700,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceSlate,
      selectedColor: brass400.withValues(alpha: 0.16),
      labelStyle: const TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontSm,
        color: textPrimary,
      ),
      side: const BorderSide(color: outlineMuted, width: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXs),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: surfaceElevated,
        borderRadius: BorderRadius.circular(radiusSm),
        border: Border.all(color: outlineMuted, width: 0.5),
      ),
      textStyle: const TextStyle(
        color: textPrimary,
        fontFamily: uiFontFamily,
        fontSize: fontSm,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: brass400,
      selectionColor: brass400.withValues(alpha: 0.28),
      selectionHandleColor: brass400,
    ),
    tabBarTheme: const TabBarThemeData(
      dividerColor: transparent,
      indicatorColor: brass400,
      labelColor: brass400,
      unselectedLabelColor: textSecondary,
      labelStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontMd,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: uiFontFamily,
        fontSize: fontMd,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
