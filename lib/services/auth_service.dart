// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  User? get currentUser {
    print('AuthService.currentUser called: ${_auth.currentUser?.email}');
    return _auth.currentUser;
  }
  
  bool get isAuthenticated => currentUser != null;
  
  Stream<User?> get authStateChanges {
    print('AuthService.authStateChanges getter called');
    return _auth.authStateChanges();
  }
  
  // Sign up with email and password
  Future<String?> signUp(String email, String password) async {
    print('SignUp started for: $email');
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('User created: ${credential.user?.email}');
      print('Current user after creation: ${_auth.currentUser?.email}');
      
      // Force refresh to ensure auth state updates
      await credential.user?.reload();
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('After reload - Current user: ${_auth.currentUser?.email}');
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return e.message ?? 'An error occurred';
    } catch (e) {
      print('General Exception: $e');
      return 'An unexpected error occurred: $e';
    }
  }
  
  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    print('SignIn started for: $email');
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful: ${_auth.currentUser?.email}');
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      return e.message ?? 'An error occurred';
    } catch (e) {
      print('General Exception: $e');
      return 'An unexpected error occurred: $e';
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    print('Sign out called');
    await _auth.signOut();
    print('Sign out complete');
  }
}