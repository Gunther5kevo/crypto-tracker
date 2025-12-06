// lib/screens/watchlist_screen.dart
import 'package:flutter/material.dart';
import '../widgets/coin_item.dart';
import '../widgets/section_header.dart';
import '../data/coin_provider.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Watchlist"),
      ),
      body: AnimatedBuilder(
        animation: CoinProvider.instance,
        builder: (context, _) {
          final watchlist = CoinProvider.instance.watchlist;
          
          if (watchlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text("No coins in watchlist"),
                  const SizedBox(height: 8),
                  Text(
                    "Star coins to add them here",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: "Your Watchlist"),
              ...watchlist.map((coin) => Dismissible(
                key: Key(coin.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (_) {
                  CoinProvider.instance.toggleStar(coin.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${coin.name} removed from watchlist"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: CoinItem(
                  coin: coin,
                  showStar: true,
                  onToggleStar: () => CoinProvider.instance.toggleStar(coin.id),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
