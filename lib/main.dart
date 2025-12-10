// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Warning: Could not load .env file: $e');
    debugPrint('💡 Create a .env file in your project root with OPENAI_API_KEY=your_key');
  }
  
  runApp(const CryptoApp());
}

class CryptoApp extends StatelessWidget {
  const CryptoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Crypto UI Kit",
            themeMode: ThemeService.instance.themeMode,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('=== AUTH GATE DEBUG ===');
        print('Connection State: ${snapshot.connectionState}');
        print('Has Data: ${snapshot.hasData}');
        print('Data is null: ${snapshot.data == null}');
        print('User Email: ${snapshot.data?.email}');
        print('Has Error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
        }
        print('=====================');
        
        // Still loading Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        // User logged in → Go to Main Navigation
        if (snapshot.hasData && snapshot.data != null) {
          print('✓ USER AUTHENTICATED - Showing MainNavigation');
          return const MainNavigation();
        }

        // User logged out → Show Login screen
        print('✗ NO USER - Showing LoginScreen');
        return const LoginScreen();
      },
    );
  }
}