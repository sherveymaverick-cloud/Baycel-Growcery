import 'package:flutter/material.dart';

// Baycel Growcery Design System Tokens
// Based on docs/DESIGN.md and UIsamples-for-all-dashboard/

/// Color palette
class BaycelColors {
  // Primary — Crimson (Action & Status)
  static const crimson = Color(0xFFC62828);
  static const crimsonLight = Color(0xFFEF5350);
  static const crimsonDark = Color(0xFF8E0000);
  static const crimsonWithAlpha = Color(0x1FC62828);

  // Secondary — Marigold (Warning)
  static const marigold = Color(0xFFFEB300);
  static const marigoldDark = Color(0xFFF57F17);

  // Tertiary — Blue (Info)
  static const blue = Color(0xFF006AB8);

  // Semantic
  static const surface = Color(0xFFF8F9FA);
  static const card = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1C1B1F);
  static const textSecondary = Color(0xFF5B403D);
  static const textMuted = Color(0xFF616161);
  static const textDisabled = Color(0xFF9E9E9E);
  static const divider = Color(0xFFE0E0E0);
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFBA1A1A);

  // Data viz palette (stat icon tints, charts)
  static const viz1 = crimson; // products
  static const viz2 = marigold; // sales
  static const viz3 = blue; // stock value
  static const viz4 = Color(0xFF7B1FA2); // deliveries
  static const viz5 = Color(0xFF00838F); // employees
  static const viz6 = success; // payroll

  // Dark theme variations
  static const darkSurface = Color(0xFF1C1B1F);
  static const darkCard = Color(0xFF2C2C2C);
  static const darkBorder = Color(0xFF3C3C3C);
  static const primaryOnDark = crimsonLight;
  static const textOnDark = Color(0xFFFFFFFF);
  static const textSecondaryOnDark = Color(0x70FFFFFF);
}

/// Typography scale (based on Inter)
class BaycelTypography {
  // Display LG (Hero)
  static final TextStyle display = TextStyle(
    fontFamily: 'Inter',
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
    color: BaycelColors.textPrimary,
  );

  // Headline LG
  static final TextStyle headline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.01,
    color: BaycelColors.textPrimary,
  );

  // Headline MD
  static final TextStyle headlineMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: BaycelColors.textPrimary,
  );

  // Title MD
  static final TextStyle title = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: BaycelColors.textPrimary,
  );

  // Body MD (default)
  static final TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: BaycelColors.textPrimary,
  );

  // Body SM
  static final TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: BaycelColors.textPrimary,
  );

  // Label MD
  static final TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.02,
    color: BaycelColors.textPrimary,
  );

  // Label SM (table headers, chips)
  static final TextStyle labelSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.03,
    color: BaycelColors.textPrimary,
  );

  // Data Mono (SKU, prices, timestamps, RFID)
  static final TextStyle dataMono = TextStyle(
    fontFamily: 'Roboto Mono', // or Inter with tabular-nums via CSS
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.01,
    color: BaycelColors.textPrimary,
  );
}

/// Layout tokens
class BaycelSpacing {
  static const xxs = 2.0; // 2px
  static const xs = 4.0; // 4px
  static const sm = 8.0; // 8px
  static const md = 12.0; // 12px
  static const base = 16.0; // 16px
  static const lg = 24.0; // 24px
  static const xl = 32.0; // 32px
  static const xxl = 48.0; // 48px
}

class BaycelRadius {
  static const sm = 2.0; // 2px (micro controls, badges)
  static const md = 4.0; // 4px (inputs, small buttons)
  static const lg = 8.0; // 8px (cards, modals)
  static const xl = 12.0; // 12px (avatars)
  static const full = 9999.0; // round-full
}

/// Shadow vocabulary (4-level ambient only)
class BaycelShadows {
  static const shadowSm = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0x04),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const shadowMd = BoxShadow(
    color: Color.fromRGBO(28, 27, 31, 0x08),
    blurRadius: 12,
    offset: Offset(0, 4),
  );
  static const shadowXl = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0x14),
    blurRadius: 32,
    offset: Offset(0, 12),
  );
}

/// Component tokens (derived from design system)
class BaycelComponents {
  static final buttonPrimary = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(BaycelColors.crimson),
    foregroundColor: WidgetStatePropertyAll(Colors.white),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BaycelRadius.md),
    )),
    textStyle: WidgetStatePropertyAll(BaycelTypography.label),
  );

  static final buttonOutlined = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(Colors.transparent),
    foregroundColor: WidgetStatePropertyAll(BaycelColors.textPrimary),
    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BaycelRadius.md),
      side: BorderSide(color: BaycelColors.divider),
    )),
    textStyle: WidgetStatePropertyAll(BaycelTypography.label),
  );

  static final card = BoxDecoration(
    color: BaycelColors.card,
    borderRadius: BorderRadius.circular(BaycelRadius.lg),
    border: Border.all(color: BaycelColors.divider.withValues(alpha: 0.5)),
    boxShadow: [BaycelShadows.shadowSm],
  );

  static final input = InputDecoration(
    filled: true,
    fillColor: BaycelColors.card,
    hintStyle: BaycelTypography.bodySm.copyWith(color: BaycelColors.textDisabled),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BaycelRadius.md),
      borderSide: BorderSide(color: BaycelColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BaycelRadius.md),
      borderSide: BorderSide(color: BaycelColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(BaycelRadius.md),
      borderSide: BorderSide(color: BaycelColors.crimson, width: 2),
    ),
  );
}

/// Theme data builder
ThemeData buildBaycelTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: BaycelColors.crimson,
      brightness: Brightness.light,
    ),
    textTheme: TextTheme(
      displayLarge: BaycelTypography.display,
      headlineLarge: BaycelTypography.headline,
      headlineMedium: BaycelTypography.headlineMd,
      titleLarge: BaycelTypography.title,
      bodyLarge: BaycelTypography.body,
      bodyMedium: BaycelTypography.bodySm,
      labelLarge: BaycelTypography.label,
      labelSmall: BaycelTypography.labelSm,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.all(BaycelSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BaycelRadius.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: BaycelComponents.buttonPrimary),
    outlinedButtonTheme: OutlinedButtonThemeData(style: BaycelComponents.buttonOutlined),
  );
}