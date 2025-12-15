// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/portfolio_card.dart';
import '../widgets/coin_item.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../data/coin_provider.dart';
import '../data/portfolio_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // In _initializeData()
Future<void> _initializeData() async {
  await CoinProvider.instance.loadWatchlist();
  await PortfolioProvider.instance.loadPortfolio();
  
  // Listen to price updates
  CoinProvider.instance.addListener(() {
    PortfolioProvider.instance.updatePrices();
  });
  
  CoinProvider.instance.fetchCoins();
}

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounce?.cancel();
    
    setState(() {
      _searchQuery = query;
    });

    if (query.trim().isEmpty) {
      CoinProvider.instance.clearSearch();
      return;
    }

    // Debounce the search to avoid too many API calls
    _debounce = Timer(const Duration(milliseconds: 500), () {
      CoinProvider.instance.searchCoins(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crypto Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => CoinProvider.instance.fetchCoins(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          CoinProvider.instance,
          PortfolioProvider.instance,
        ]),
        builder: (context, _) {
          final isLoading = CoinProvider.instance.isLoading;
          final isSearching = CoinProvider.instance.isSearching;
          
          // Use search results if searching, otherwise show main coins
          final coins = _searchQuery.isEmpty
              ? CoinProvider.instance.coins
              : CoinProvider.instance.searchResults;

          final totalValue = PortfolioProvider.instance.totalValue;
          final profit = PortfolioProvider.instance.totalProfit;

          double changePercent = 0;
          if (totalValue > 0) {
            final initialValue = totalValue - profit;
            if (initialValue != 0) {
              changePercent = (profit / initialValue) * 100;
            }
          }

          if (isLoading && CoinProvider.instance.coins.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => CoinProvider.instance.fetchCoins(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Portfolio Card
                PortfolioCard(
                  totalValue: totalValue,
                  changePercent: changePercent,
                ),

                const SizedBox(height: 20),

                // Stat Cards
                const Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: "24h Volume",
                        value: "\$2.4B",
                        icon: Icons.trending_up,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: "Market Cap",
                        value: "\$1.2T",
                        icon: Icons.account_balance,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search any coin...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                              CoinProvider.instance.clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1A1F26)
                        : Colors.grey.shade100,
                  ),
                  onChanged: _onSearchChanged,
                ),

                const SizedBox(height: 16),

                // Section Header
                SectionHeader(
                  title: _searchQuery.isEmpty
                      ? "Trending Coins"
                      : "Search Results (${coins.length})",
                  actionLabel: _searchQuery.isEmpty ? "Live" : null,
                ),

                // Loading indicator for search
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                // No results found
                else if (coins.isEmpty && _searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No coins found",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try a different search term",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                // Coins List
                else
                  ...coins.map(
                    (coin) => CoinItem(
                      coin: coin,
                      showStar: true,
                      onToggleStar: () =>
                          CoinProvider.instance.toggleStar(coin.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}