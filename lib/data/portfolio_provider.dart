import 'package:flutter/material.dart';

class PortfolioProvider extends ChangeNotifier {
  static final PortfolioProvider instance = PortfolioProvider._();
  PortfolioProvider._();

  final Map<String, Map<String, dynamic>> _holdings = {};

  Map<String, Map<String, dynamic>> get holdings => _holdings;

  double get totalValue {
    return _holdings.values.fold(0.0, (sum, h) => sum + (h['value'] as double));
  }

  double get totalProfit {
    return _holdings.values.fold(0.0, (sum, h) => sum + (h['profit'] as double));
  }

  void addHolding(String symbol, double amount, double buyPrice) {
    final currentPrice = buyPrice * 1.05; // Mock 5% gain
    final value = amount * currentPrice;
    final profit = value - (amount * buyPrice);
    
    _holdings[symbol] = {
      'amount': amount,
      'buyPrice': buyPrice,
      'currentPrice': currentPrice,
      'value': value,
      'profit': profit,
    };
    notifyListeners();
  }
}