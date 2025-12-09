import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PortfolioProvider extends ChangeNotifier {
  static final PortfolioProvider instance = PortfolioProvider._();
  PortfolioProvider._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, Map<String, dynamic>> _holdings = {};

  Map<String, Map<String, dynamic>> get holdings => _holdings;

  double get totalValue {
    return _holdings.values.fold(0.0, (sum, h) => sum + (h['value'] as double));
  }

  double get totalProfit {
    return _holdings.values.fold(0.0, (sum, h) => sum + (h['profit'] as double));
  }

  // Load user's portfolio from Firestore
  Future<void> loadPortfolio() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _holdings = {};
      notifyListeners();
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('portfolios')
          .doc(userId)
          .collection('holdings')
          .get();

      _holdings = {};
      for (var doc in snapshot.docs) {
        _holdings[doc.id] = doc.data();
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading portfolio: $e');
    }
  }

  // Add or update holding in Firestore
  Future<void> addHolding(String symbol, double amount, double buyPrice) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final currentPrice = buyPrice * 1.05; // Mock 5% gain
    final value = amount * currentPrice;
    final profit = value - (amount * buyPrice);
    
    final holdingData = {
      'amount': amount,
      'buyPrice': buyPrice,
      'currentPrice': currentPrice,
      'value': value,
      'profit': profit,
    };

    try {
      await _firestore
          .collection('portfolios')
          .doc(userId)
          .collection('holdings')
          .doc(symbol)
          .set(holdingData);

      _holdings[symbol] = holdingData;
      notifyListeners();
    } catch (e) {
      print('Error adding holding: $e');
    }
  }

  // Remove holding from Firestore
  Future<void> removeHolding(String symbol) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore
          .collection('portfolios')
          .doc(userId)
          .collection('holdings')
          .doc(symbol)
          .delete();

      _holdings.remove(symbol);
      notifyListeners();
    } catch (e) {
      print('Error removing holding: $e');
    }
  }

  // Clear portfolio (for logout)
  void clearPortfolio() {
    _holdings = {};
    notifyListeners();
  }
}