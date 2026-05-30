import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HybStockAdvisor {
  HybStockAdvisor._();

  // Common theme colors and values
  static const Color darkBackground = Color(0xFF1E293B);
  static const Color darkCardBackground = Color(0xFF131D2D);
  static const Color darkBorderColor = Color(0xFF4B5563);
  static const Color darkButtonBackground = Color(0xFF334155);
  
  static const Color lightBackground = Color.fromRGBO(252, 242, 232, 1);
    // static const Color lightBackground = Colors.white;

  static const Color lightCardBackground = Color.fromRGBO(252, 242, 232, 1);
  static const Color lightAppBarBackground = Color.fromRGBO(255, 249, 233, 1);
  static const Color lightBorderColor = Colors.black;
  static const Color lightButtonBackground = Color(0xFF0A3D62);
  
  static const Color accentColor = Color(0xFF1E293B);
  
  // Dropdown specific colors
  static const Color darkDropdownBackground = Color(0xFF131D2D);
  static const Color lightDropdownBackground = Color.fromRGBO(252, 242, 232, 1);
  static const Color darkDropdownItemHover = Color(0xFF334155);
  static const Color lightDropdownItemHover = Color(0xFFE5E7EB);

  // Get theme-specific colors based on brightness
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkCardBackground 
        : lightCardBackground;
  }
  
  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Color(0xFF1E293B);
  }
  
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorderColor 
        : lightBorderColor;
  }
  
  static Color getButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkButtonBackground 
        : lightButtonBackground;
  }
  
  // Add these new methods for dropdown styling
  static Color getDropdownBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkDropdownBackground 
        : lightDropdownBackground;
  }
  
  static Color getDropdownItemColor(BuildContext context) {
    return getTextColor(context);
  }
  
  static Color getDropdownIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? Colors.white70 
        : Color(0xFF1E293B);
  }
  
  static Color getDropdownHoverColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkDropdownItemHover 
        : lightDropdownItemHover;
  }
  
  static BoxShadow getBoxShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.2),
      spreadRadius: 1,
      blurRadius: 4,
      offset: Offset(0, 2),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    brightness: Brightness.light,
    primaryColor: Colors.black,
    iconTheme: const IconThemeData(color: Colors.grey),
    indicatorColor: const Color(0xFFF5F5F5),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: lightAppBarBackground,
      elevation: 2,
      scrolledUnderElevation: 2,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      fillColor: WidgetStateProperty.all(accentColor),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: accentColor, width: 2),
    ),
    canvasColor: Colors.white,
    // Add dropdown theme settings
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(lightDropdownBackground),
      ),
      textStyle: TextStyle(color: Color(0xFF1E293B)),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.white),
    indicatorColor: const Color(0xFFF5F5F5),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: darkCardBackground,
      elevation: 2,
      scrolledUnderElevation: 2,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      fillColor: MaterialStateProperty.all(accentColor),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: BorderSide(color: accentColor, width: 2),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    canvasColor: Colors.white,
    // Add dropdown theme settings
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(darkDropdownBackground),
      ),
      textStyle: TextStyle(color: Colors.white),
    ),
  );
}
