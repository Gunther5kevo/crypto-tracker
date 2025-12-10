// lib/data/coin_provider.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'coin_model.dart';

class CoinProvider extends ChangeNotifier {
  static final CoinProvider instance = CoinProvider._();
  CoinProvider._();

  List<Coin> _coins = [];
  List<Coin> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;

  // Store starred coin IDs to preserve across refreshes
  Set<String> _starredIds = {};
  
  static const String _watchlistKey = 'watchlist_coins';

  List<Coin> get coins => _coins;
  List<Coin> get searchResults => _searchResults;
  List<Coin> get watchlist => _coins.where((c) => c.starred).toList();
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  // Load starred coins from SharedPreferences
  Future<void> loadWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedIds = prefs.getStringList(_watchlistKey);
      if (savedIds != null) {
        _starredIds = savedIds.toSet();
        debugPrint('✅ Loaded ${_starredIds.length} starred coins from storage');
      }
    } catch (e) {
      debugPrint('❌ Error loading watchlist: $e');
    }
  }

  // Save starred coins to SharedPreferences
  Future<void> _saveWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchlistKey, _starredIds.toList());
      debugPrint('✅ Saved ${_starredIds.length} starred coins to storage');
    } catch (e) {
      debugPrint('❌ Error saving watchlist: $e');
    }
  }

  // Fetch top coins by market cap
  Future<void> fetchCoins() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=50&sparkline=true&price_change_percentage=24h'
      ));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _coins = data.map((coin) {
          final sparklineData = coin['sparkline_in_7d']['price'] as List<dynamic>;
          final sparkList = sparklineData
              .take(20)
              .map((e) => (e as num).toDouble())
              .toList();
          
          final coinId = coin['id'];
          
          return Coin(
            id: coinId,
            name: coin['name'],
            symbol: coin['symbol'].toUpperCase(),
            price: (coin['current_price'] as num).toDouble(),
            change: (coin['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
            spark: sparkList,
            starred: _starredIds.contains(coinId),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error fetching coins: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Search for any coin using CoinGecko search API
  Future<void> searchCoins(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // Use the markets endpoint with search parameter for better results
      final response = await http.get(Uri.parse(
        'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&sparkline=true&price_change_percentage=24h'
      ));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        final lowerQuery = query.toLowerCase().trim();
        
        // Filter coins by name or symbol
        final filtered = data.where((coin) {
          final name = (coin['name'] as String).toLowerCase();
          final symbol = (coin['symbol'] as String).toLowerCase();
          final id = (coin['id'] as String).toLowerCase();
          
          return name.contains(lowerQuery) || 
                 symbol.contains(lowerQuery) || 
                 id.contains(lowerQuery) ||
                 name.startsWith(lowerQuery) ||
                 symbol.startsWith(lowerQuery);
        }).toList();

        _searchResults = filtered.map((coin) {
          final sparklineData = coin['sparkline_in_7d']?['price'] as List<dynamic>? ?? [];
          final sparkList = sparklineData
              .take(20)
              .map((e) => (e as num).toDouble())
              .toList();
          
          // If sparkline is empty, create a flat line
          if (sparkList.isEmpty) {
            final price = (coin['current_price'] as num?)?.toDouble() ?? 0.0;
            sparkList.addAll(List.filled(20, price));
          }
          
          final coinId = coin['id'];
          
          return Coin(
            id: coinId,
            name: coin['name'],
            symbol: coin['symbol'].toUpperCase(),
            price: (coin['current_price'] as num?)?.toDouble() ?? 0.0,
            change: (coin['price_change_percentage_24h'] as num?)?.toDouble() ?? 0.0,
            spark: sparkList,
            starred: _starredIds.contains(coinId),
          );
        }).toList();

        debugPrint('🔍 Found ${_searchResults.length} results for "$query"');
      }
    } catch (e) {
      debugPrint('Error searching coins: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  void toggleStar(String id) {
    // Update the starred IDs set first
    if (_starredIds.contains(id)) {
      _starredIds.remove(id);
      debugPrint('⭐ Removed $id from watchlist');
    } else {
      _starredIds.add(id);
      debugPrint('⭐ Added $id to watchlist');
    }

    // Update in main coins list if present
    int index = _coins.indexWhere((c) => c.id == id);
    if (index != -1) {
      _coins[index] = _coins[index].copyWith(starred: _starredIds.contains(id));
    }

    // Update in search results if present
    index = _searchResults.indexWhere((c) => c.id == id);
    if (index != -1) {
      _searchResults[index] = _searchResults[index].copyWith(starred: _starredIds.contains(id));
    }
    
    // Save to storage
    _saveWatchlist();
    
    notifyListeners();
  }
}