// lib/screens/ai_analyst_screen.dart
import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../data/coin_provider.dart';
import 'ai_chat_screen.dart';

class AIAnalystScreen extends StatefulWidget {
  const AIAnalystScreen({super.key});

  @override
  State<AIAnalystScreen> createState() => _AIAnalystScreenState();
}

class _AIAnalystScreenState extends State<AIAnalystScreen> {
  final _openAI = OpenAIService();
  Map<String, dynamic>? _analysis;
  bool _isLoading = false;
  String? _error;
  int _coinCount = 10;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final coins = CoinProvider.instance.coins;
      
      if (coins.isEmpty) {
        setState(() {
          _error = 'No coins available. Please refresh the home screen first.';
          _isLoading = false;
        });
        return;
      }

      final coinsToAnalyze = coins.take(_coinCount).toList();
      final symbols = coinsToAnalyze.map((c) => c.symbol).toList();
      final prices = coinsToAnalyze.map((c) => c.price).toList();
      final changes = coinsToAnalyze.map((c) => c.change).toList();
      
      debugPrint('📊 Getting analysis for ${symbols.length} coins: $symbols');

      final analysis = await _openAI.getMarketAnalysis(
        symbols: symbols,
        prices: prices,
        changes: changes,
      );
      
      debugPrint('✅ Analysis received: $analysis');

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadAnalysis: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showCoinCountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Coins to Analyze'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Top 5 coins'),
              leading: Radio<int>(
                value: 5,
                groupValue: _coinCount,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _coinCount = value!);
                  _loadAnalysis();
                },
              ),
            ),
            ListTile(
              title: const Text('Top 10 coins'),
              leading: Radio<int>(
                value: 10,
                groupValue: _coinCount,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _coinCount = value!);
                  _loadAnalysis();
                },
              ),
            ),
            ListTile(
              title: const Text('Top 20 coins'),
              leading: Radio<int>(
                value: 20,
                groupValue: _coinCount,
                onChanged: (value) {
                  Navigator.pop(context);
                  setState(() => _coinCount = value!);
                  _loadAnalysis();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Analyst"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _openChatScreen,
            tooltip: 'Chat with AI',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCoinCountDialog,
            tooltip: 'Select coins to analyze',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Analysis',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _loadAnalysis,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _openChatScreen,
                              icon: const Icon(Icons.chat),
                              label: const Text('Try Chat'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalysis,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header with chat button
                      Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 32,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "AI Market Analysis",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                Text(
                                  "Analyzing top $_coinCount coins • Powered by OpenAI",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _openChatScreen,
                            icon: const Icon(Icons.chat, size: 18),
                            label: const Text('Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Market Summary
                      _buildCard(
                        icon: Icons.newspaper,
                        title: "Market Summary",
                        content: _analysis?['market_summary'] ?? 'Loading...',
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 16),

                      // Sentiment & Risk Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.sentiment_satisfied_alt,
                              label: "Sentiment",
                              value: _analysis?['sentiment'] ?? '-',
                              color: _getSentimentColor(_analysis?['sentiment']),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              icon: Icons.warning_amber,
                              label: "Risk Score",
                              value: "${_analysis?['risk_score'] ?? '-'}/100",
                              color: _getRiskColor(_analysis?['risk_score']),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Top Picks
                      _buildCard(
                        icon: Icons.star,
                        title: "Top Picks",
                        content: (_analysis?['top_picks'] as List?)?.join(' • ') ??
                            'Loading...',
                        color: Colors.amber,
                      ),

                      const SizedBox(height: 16),

                      // Key Opportunities
                      if (_analysis?['opportunities'] != null)
                        _buildCard(
                          icon: Icons.trending_up,
                          title: "Key Opportunities",
                          content: _analysis!['opportunities'],
                          color: Colors.green,
                        ),

                      if (_analysis?['opportunities'] != null)
                        const SizedBox(height: 16),

                      // Key Risks
                      if (_analysis?['risks'] != null)
                        _buildCard(
                          icon: Icons.warning,
                          title: "Key Risks",
                          content: _analysis!['risks'],
                          color: Colors.red,
                        ),

                      if (_analysis?['risks'] != null)
                        const SizedBox(height: 16),

                      // Key Insight
                      _buildCard(
                        icon: Icons.lightbulb,
                        title: "Key Insight",
                        content: _analysis?['key_insight'] ?? 'Loading...',
                        color: Colors.purple,
                      ),

                      const SizedBox(height: 24),

                      // Chat CTA
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.1),
                              theme.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Have questions?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    'Chat with AI for personalized insights',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _openChatScreen,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Start Chat'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Disclaimer
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "AI analysis is for informational purposes only. Not financial advice. Always do your own research.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(String? sentiment) {
    if (sentiment == null) return Colors.grey;
    switch (sentiment.toLowerCase()) {
      case 'fear':
      case 'extreme fear':
        return Colors.red;
      case 'greed':
      case 'extreme greed':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  Color _getRiskColor(dynamic risk) {
    if (risk == null) return Colors.grey;
    final score = risk is int ? risk : int.tryParse(risk.toString()) ?? 50;
    if (score < 40) return Colors.green;
    if (score < 70) return Colors.orange;
    return Colors.red;
  }
}