import 'package:flutter/material.dart';
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

      /// 🔥 LISTEN to BOTH providers: coins + portfolio
      body: AnimatedBuilder(
        animation: Listenable.merge([
          CoinProvider.instance,
          PortfolioProvider.instance,
        ]),
        builder: (context, _) {
          final coins = CoinProvider.instance.coins;
          final isLoading = CoinProvider.instance.isLoading;

          final totalValue = PortfolioProvider.instance.totalValue;
          final profit = PortfolioProvider.instance.totalProfit;

          double changePercent = 0;
          if (totalValue > 0) {
            final initialValue = totalValue - profit;
            if (initialValue != 0) {
              changePercent = (profit / initialValue) * 100;
            }
          }

          if (isLoading && coins.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => CoinProvider.instance.fetchCoins(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// 🔥 DYNAMIC PortfolioCard
                PortfolioCard(
                  totalValue: totalValue,
                  changePercent: changePercent,
                ),

                const SizedBox(height: 20),

                /// Stat Cards
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

                /// Coins list
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
