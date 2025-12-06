// lib/data/coin_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'coin_model.dart';

class CoinProvider extends ChangeNotifier {
  static final CoinProvider instance = CoinProvider._();
  CoinProvider._();

  List<Coin> _coins = [];
  bool _isLoading = false;

  List<Coin> get coins => _coins;
  List<Coin> get watchlist => _coins.where((c) => c.starred).toList();
  bool get isLoading => _isLoading;

  // Fetch live data from CoinGecko API
  Future<void> fetchCoins() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&sparkline=true&price_change_percentage=24h'
      ));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _coins = data.map((coin) {
          // Safely parse sparkline data
          final sparklineData = coin['sparkline_in_7d']['price'] as List<dynamic>;
          final sparkList = sparklineData
              .take(20)
              .map((e) => (e as num).toDouble())
              .toList();
          
          return Coin(
            id: coin['id'],
            name: coin['name'],
            symbol: coin['symbol'].toUpperCase(),
            price: (coin['current_price'] as num).toDouble(),
            change: (coin['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
            spark: sparkList,
            starred: false,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching coins: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleStar(String id) {
    final index = _coins.indexWhere((c) => c.id == id);
    if (index != -1) {
      _coins[index] = _coins[index].copyWith(starred: !_coins[index].starred);
      notifyListeners();
    }
  }
}