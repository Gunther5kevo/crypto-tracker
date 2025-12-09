// lib/screens/portfolio_screen.dart
import 'package:flutter/material.dart';
import '../data/portfolio_provider.dart';
import '../data/coin_provider.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Portfolio"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddHoldingDialog(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: PortfolioProvider.instance,
        builder: (context, _) {
          final holdings = PortfolioProvider.instance.holdings;
          final totalValue = PortfolioProvider.instance.totalValue;
          final totalProfit = PortfolioProvider.instance.totalProfit;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF1A1F26), const Color(0xFF2A3340)]
                      : [Colors.white, Colors.grey.shade50],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      "Total Balance",
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$${totalValue.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: totalProfit >= 0 
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: totalProfit >= 0 ? Colors.green : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${totalProfit >= 0 ? '+' : ''}\$${totalProfit.abs().toStringAsFixed(2)}",
                            style: TextStyle(
                              color: totalProfit >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                "Holdings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              if (holdings.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text("No holdings yet"),
                        const SizedBox(height: 8),
                        Text(
                          "Tap + to add your first coin",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...holdings.entries.map((entry) {
                  final symbol = entry.key;
                  final data = entry.value;
                  final profit = data['profit'] as double;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              symbol,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                symbol,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${data['amount']} coins",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "\$${data['value'].toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: profit >= 0 ? Colors.green : Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove Holding'),
                                content: Text('Remove $symbol from portfolio?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      PortfolioProvider.instance.removeHolding(symbol);
                                      Navigator.pop(context);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  void _showAddHoldingDialog(BuildContext context) {
    final symbolController = TextEditingController();
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Holding"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(
                  labelText: "Symbol",
                  hintText: "BTC",
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text(
                "Buy price will use current market price",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final symbol = symbolController.text.toUpperCase();
              final amount = double.tryParse(amountController.text) ?? 0;
              
              if (symbol.isNotEmpty && amount > 0) {
                // Find current price from coin list
                final coin = CoinProvider.instance.coins.firstWhere(
                  (c) => c.symbol == symbol,
                  orElse: () => CoinProvider.instance.coins.first,
                );
                
                final buyPrice = coin.price;
                PortfolioProvider.instance.addHolding(symbol, amount, buyPrice);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}