import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'coin_provider.dart'; // Import to access live prices

class PortfolioProvider extends ChangeNotifier {
  static final PortfolioProvider instance = PortfolioProvider._();
  PortfolioProvider._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, Map<String, dynamic>> _holdings = {};

  Map<String, Map<String, dynamic>> get holdings {
    // Recalculate with live prices before returning
    return _getHoldingsWithLivePrices();
  }

  double get totalValue {
    return _getHoldingsWithLivePrices().values.fold(
      0.0, 
      (sum, h) => sum + (h['value'] as double)
    );
  }

  double get totalProfit {
    return _getHoldingsWithLivePrices().values.fold(
      0.0, 
      (sum, h) => sum + (h['profit'] as double)
    );
  }

  // Calculate holdings with current live prices
  Map<String, Map<String, dynamic>> _getHoldingsWithLivePrices() {
    final updatedHoldings = <String, Map<String, dynamic>>{};
    
    for (var entry in _holdings.entries) {
      final symbol = entry.key;
      final storedData = entry.value;
      
      // Find current price from CoinProvider
      final coin = CoinProvider.instance.coins.firstWhere(
        (c) => c.symbol == symbol,
        orElse: () => CoinProvider.instance.coins.firstWhere(
          (c) => c.id == symbol.toLowerCase(),
          orElse: () => CoinProvider.instance.coins.first, // Fallback
        ),
      );
      
      final amount = storedData['amount'] as double;
      final buyPrice = storedData['buyPrice'] as double;
      final currentPrice = coin.price; // LIVE PRICE from API
      
      final value = amount * currentPrice;
      final profit = value - (amount * buyPrice);
      
      updatedHoldings[symbol] = {
        'amount': amount,
        'buyPrice': buyPrice,
        'currentPrice': currentPrice,
        'value': value,
        'profit': profit,
      };
    }
    
    return updatedHoldings;
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
        // Only store amount and buyPrice - current price comes from API
        _holdings[doc.id] = {
          'amount': doc.data()['amount'],
          'buyPrice': doc.data()['buyPrice'],
        };
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

    // Only store static data (amount, buyPrice) - not current price
    final holdingData = {
      'amount': amount,
      'buyPrice': buyPrice,
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

  // Call this when CoinProvider updates prices
  void updatePrices() {
    notifyListeners();
  }
}