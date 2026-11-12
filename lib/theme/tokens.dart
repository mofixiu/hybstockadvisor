import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for HybStockAdvisor.
///
/// The look is a printed finance page: off-white paper, near-black ink, one
/// navy, hairline rules instead of cards. Headings are Source Serif 4; body
/// copy and every figure are IBM Plex Sans with tabular figures, so columns of
/// numbers line up. Up and down always carry a sign and a ▲/▼ glyph as well as
/// a colour, so they read without colour vision.
///
/// Read colours with `context.pal`, text styles with `context.text`.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.rule,
    required this.ruleStrong,
    required this.accent,
    required this.accentFill,
    required this.onAccentFill,
    required this.accentWash,
    required this.up,
    required this.down,
    required this.warn,
    required this.skeleton,
    required this.skeletonHighlight,
  });

  /// Page background.
  final Color paper;

  /// Sheets, dialogs and text fields: a touch lighter than the page.
  final Color surface;

  /// Body text and figures.
  final Color ink;

  /// Secondary text.
  final Color inkMuted;

  /// Captions and axis labels. Still meets 4.5:1 on [paper].
  final Color inkFaint;

  /// Hairline rules between rows.
  final Color rule;

  /// Heavy section rules.
  final Color ruleStrong;

  /// The one navy: links, selected tab, kickers.
  final Color accent;

  /// Primary button fill.
  final Color accentFill;
  final Color onAccentFill;

  /// Very light navy for a selected row.
  final Color accentWash;

  final Color up;
  final Color down;

  /// Stale data and other cautions.
  final Color warn;

  final Color skeleton;
  final Color skeletonHighlight;

  static const navy = Color(0xFF0A3D62);

  static const light = Palette(
    paper: Color(0xFFF7F5F0),
    surface: Color(0xFFFCFBF8),
    ink: Color(0xFF15181C),
    inkMuted: Color(0xFF4A4F57),
    inkFaint: Color(0xFF666A71),
    rule: Color(0xFFD8D4CA),
    ruleStrong: Color(0xFF15181C),
    accent: navy,
    accentFill: navy,
    onAccentFill: Color(0xFFFFFFFF),
    accentWash: Color(0xFFE7ECF0),
    up: Color(0xFF1B6A3A),
    down: Color(0xFFA6291F),
    warn: Color(0xFF875200),
    skeleton: Color(0xFFEAE7E0),
    skeletonHighlight: Color(0xFFF3F1EC),
  );

  static const dark = Palette(
    paper: Color(0xFF111315),
    surface: Color(0xFF181B1E),
    ink: Color(0xFFECEAE4),
    inkMuted: Color(0xFFB7B4AD),
    inkFaint: Color(0xFF94928C),
    rule: Color(0xFF2D3135),
    ruleStrong: Color(0xFFECEAE4),
    accent: Color(0xFF94B9DD),
    accentFill: Color(0xFF94B9DD),
    onAccentFill: Color(0xFF0B1A26),
    accentWash: Color(0xFF1B2733),
    up: Color(0xFF6DC48D),
    down: Color(0xFFF2897D),
    warn: Color(0xFFE2B15A),
    skeleton: Color(0xFF1E2226),
    skeletonHighlight: Color(0xFF282D32),
  );

  /// Colour for a signed value: up, down, or plain ink for zero and unknown.
  Color signed(num? value) {
    if (value == null || value == 0) return ink;
    return value > 0 ? up : down;
  }

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: l(paper, other.paper),
      surface: l(surface, other.surface),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkFaint: l(inkFaint, other.inkFaint),
      rule: l(rule, other.rule),
      ruleStrong: l(ruleStrong, other.ruleStrong),
      accent: l(accent, other.accent),
      accentFill: l(accentFill, other.accentFill),
      onAccentFill: l(onAccentFill, other.onAccentFill),
      accentWash: l(accentWash, other.accentWash),
      up: l(up, other.up),
      down: l(down, other.down),
      warn: l(warn, other.warn),
      skeleton: l(skeleton, other.skeleton),
      skeletonHighlight: l(skeletonHighlight, other.skeletonHighlight),
    );
  }
}

/// Corner radii. Print does not round much.
class Radii {
  Radii._();
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double sheet = 12;
}

/// Spacing scale.
class Gap {
  Gap._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Page side margin.
  static const double page = 20;
}

/// Line weights.
class Stroke {
  Stroke._();
  static const double hairline = 0.7;
  static const double heavy = 1.6;
}

/// Type families and helpers.
class AppType {
  AppType._();

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle serif({
    double size = 20,
    FontWeight weight = FontWeight.w600,
    double height = 1.2,
    Color? color,
    double letterSpacing = -0.2,
  }) => GoogleFonts.sourceSerif4(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    double height = 1.4,
    Color? color,
    double letterSpacing = 0,
    bool figures = true,
  }) => GoogleFonts.ibmPlexSans(
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
    letterSpacing: letterSpacing,
    fontFeatures: figures ? tabular : null,
  );

  /// Large figure, e.g. a price or a portfolio total.
  static TextStyle figure({double size = 30, Color? color}) => sans(
    size: size,
    weight: FontWeight.w500,
    height: 1.1,
    color: color,
    letterSpacing: -0.6,
  );
}

TextTheme _textTheme(Palette p) {
  final serif = AppType.serif;
  final sans = AppType.sans;
  return TextTheme(
    displaySmall: serif(size: 30, color: p.ink, height: 1.15),
    headlineMedium: serif(size: 27, color: p.ink, height: 1.15),
    headlineSmall: serif(size: 23, color: p.ink, height: 1.2),
    titleLarge: serif(size: 19, color: p.ink, height: 1.25),
    titleMedium: sans(size: 15, weight: FontWeight.w600, color: p.ink),
    titleSmall: sans(size: 13.5, weight: FontWeight.w600, color: p.ink),
    bodyLarge: sans(size: 15.5, color: p.ink, height: 1.5),
    bodyMedium: sans(size: 14, color: p.ink, height: 1.45),
    bodySmall: sans(size: 12.5, color: p.inkFaint, height: 1.4),
    labelLarge: sans(size: 14.5, weight: FontWeight.w600, color: p.ink),
    labelMedium: sans(size: 12, weight: FontWeight.w600, color: p.inkMuted),
    labelSmall: sans(
      size: 11,
      weight: FontWeight.w600,
      color: p.inkFaint,
      letterSpacing: 0.9,
    ),
  );
}

/// Builds the app theme for a brightness from the tokens above.
ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
  final text = _textTheme(p);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accentFill,
    onPrimary: p.onAccentFill,
    secondary: p.accent,
    onSecondary: p.onAccentFill,
    error: p.down,
    onError: p.paper,
    surface: p.paper,
    onSurface: p.ink,
    onSurfaceVariant: p.inkMuted,
    outline: p.rule,
    outlineVariant: p.rule,
    surfaceContainerLowest: p.surface,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.surface,
    inverseSurface: p.ink,
    onInverseSurface: p.paper,
  );
  final shape4 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.sm),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    canvasColor: p.paper,
    fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    textTheme: text,
    extensions: [p],
    splashFactory: NoSplash.splashFactory,
    highlightColor: p.accentWash,
    iconTheme: IconThemeData(color: p.inkMuted, size: 20),
    dividerTheme: DividerThemeData(
      color: p.rule,
      thickness: Stroke.hairline,
      space: Stroke.hairline,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
      iconTheme: IconThemeData(color: p.ink, size: 22),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: p.accentFill,
        foregroundColor: p.onAccentFill,
        disabledBackgroundColor: p.rule,
        disabledForegroundColor: p.inkFaint,
        elevation: 0,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: shape4,
        textStyle: text.labelLarge,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accentFill,
        foregroundColor: p.onAccentFill,
        minimumSize: const Size(64, 48),
        shape: shape4,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.ink, width: 1),
        minimumSize: const Size(64, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: shape4,
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: shape4,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: text.bodyMedium?.copyWith(color: p.inkFaint),
      labelStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
      floatingLabelStyle: text.bodySmall?.copyWith(color: p.accent),
      prefixIconColor: p.inkFaint,
      suffixIconColor: p.inkFaint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: p.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: p.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: p.down),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: p.down, width: 1.4),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onAccentFill : p.inkFaint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accentFill : p.surface,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accentFill : p.rule,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xs)),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.accentFill : Colors.transparent,
      ),
      checkColor: WidgetStateProperty.all(p.onAccentFill),
      side: BorderSide(color: p.inkMuted, width: 1.4),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.rule,
      circularTrackColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surface,
      elevation: 0,
      modalElevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: p.rule),
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.inkMuted),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: p.paper),
      actionTextColor: p.paper,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.sm)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.inkMuted,
      textColor: p.ink,
      titleTextStyle: text.bodyLarge,
      subtitleTextStyle: text.bodySmall,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.25),
      selectionHandleColor: p.accent,
    ),
  );
}

extension ThemeTokens on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
