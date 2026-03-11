import 'package:hive/hive.dart';
import 'package:hybstockadvisor/providers/theme_provider.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/widgets/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:hive/hive.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hybstockadvisor/themes/theme.dart';

// import 'request.dart';
// import 'providers/theme_provider.dart';
// import 'providers/user_provider.dart';
// import 'widgets/splash_screen.dart';
// import 'themes/theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Hive.initFlutter();
  final notificationProvider = NotificationProvider();
  await notificationProvider.loadNotifications();

  final themeProvider = ThemeProvider();
  await themeProvider.loadFromHive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        // ChangeNotifierProvider(create: (context) => UserProvider()),
        // ChangeNotifierProvider(create: (_) => HotelProvider()),
        // ChangeNotifierProvider(create: (_) => BookmarkProvider()),
        // ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HybStockAdvisor',
          navigatorKey: ApiService.navigatorKey,
          theme: HybStockAdvisor.lightTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(
              HybStockAdvisor.lightTheme.textTheme,
            ),
          ),
          darkTheme: HybStockAdvisor.darkTheme.copyWith(
            textTheme: GoogleFonts.montserratTextTheme(
              HybStockAdvisor.darkTheme.textTheme,
            ),
          ),
          themeMode: themeProvider.themeMode,

          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
