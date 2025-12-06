import 'package:flutter/material.dart';
import 'services/theme_service.dart';
import 'screens/main_navigation.dart';

void main() {
  runApp(const CryptoApp());
}

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Crypto UI Kit",
          themeMode: ThemeService.instance.themeMode,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          home: const MainNavigation(),
        );
      },
    );
  }
}