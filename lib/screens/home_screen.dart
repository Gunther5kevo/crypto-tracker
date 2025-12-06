import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';
import '../widgets/coin_item.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';
import '../data/coin_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    CoinProvider.instance.fetchCoins();
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
        animation: CoinProvider.instance,
        builder: (context, _) {
          final coins = CoinProvider.instance.coins;
          final isLoading = CoinProvider.instance.isLoading;
          
          if (isLoading && coins.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return RefreshIndicator(
            onRefresh: () => CoinProvider.instance.fetchCoins(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PortfolioCard(
                  totalValue: 12540.80,
                  changePercent: 4.32,
                ),
                
                const SizedBox(height: 20),
                
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
                
                const SectionHeader(
                  title: "Trending Coins",
                  actionLabel: "Live",
                ),
                
                ...coins.map((coin) => CoinItem(
                  coin: coin,
                  showStar: true,
                  onToggleStar: () => CoinProvider.instance.toggleStar(coin.id),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}