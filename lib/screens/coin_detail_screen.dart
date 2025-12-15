// lib/screens/coin_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/coin_model.dart';
import '../services/coin_chart_service.dart';
import '../widgets/trading_view.dart';
import '../widgets/orderbook_view.dart';

class CoinDetailScreen extends StatefulWidget {
  final Coin coin;

  const CoinDetailScreen({super.key, required this.coin});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = '1D';
  String _selectedInterval = '1m';
  List<FlSpot> _chartData = [];
  bool _isLoading = true;
  bool _useRealtimeData = true;

  final _timeframes = ['1H', '1D', '1W', '1M', '1Y'];
  final _binanceIntervals = ['1m', '5m', '15m', '1h', '4h', '1d'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChartData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChartData() async {
    if (!_useRealtimeData) {
      setState(() => _isLoading = true);
      
      final data = await CoinChartService.fetchChartData(
        widget.coin.id,
        _selectedTimeframe,
      );
      
      if (mounted) {
        setState(() {
          _chartData = data;
          _isLoading = false;
        });
      }
    }
  }

  String _convertToBinanceSymbol(String coinId) {
    final map = {
      'bitcoin': 'BTCUSDT',
      'ethereum': 'ETHUSDT',
      'cardano': 'ADAUSDT',
      'solana': 'SOLUSDT',
      'ripple': 'XRPUSDT',
      'polkadot': 'DOTUSDT',
      'dogecoin': 'DOGEUSDT',
      'avalanche-2': 'AVAXUSDT',
      'polygon': 'MATICUSDT',
      'chainlink': 'LINKUSDT',
    };
    return map[coinId] ?? 'BTCUSDT';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F1419) : const Color(0xFFF8F9FA);
    final cardColor = isDark ? const Color(0xFF1A1F26) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        title: Row(
          children: [
            Hero(
              tag: 'coin_${widget.coin.id}',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    widget.coin.symbol,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.coin.name,
                  style: TextStyle(fontSize: 16, color: textColor),
                ),
                Text(
                  widget.coin.symbol.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.coin.starred ? Icons.star : Icons.star_outline,
              color: widget.coin.starred ? Colors.amber : subtextColor,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.coin.change >= 0
                    ? [Colors.green.shade400, Colors.green.shade700]
                    : [Colors.red.shade400, Colors.red.shade700],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Price',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  "\$${widget.coin.price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      widget.coin.change >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "${widget.coin.change >= 0 ? '+' : ''}${widget.coin.change.toStringAsFixed(2)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '24h Change',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: textColor,
              unselectedLabelColor: subtextColor,
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(text: "Chart"),
                Tab(text: "Order Book"),
                Tab(text: "Stats"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChartTab(isDark, cardColor, textColor, subtextColor),
                OrderBookView(symbol: _convertToBinanceSymbol(widget.coin.id)),
                _buildStatsTab(isDark, cardColor, textColor, subtextColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: cardColor,
          child: Row(
            children: [
              Text(
                _useRealtimeData ? '🔴 Live Data' : '📊 Historical',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _useRealtimeData,
                onChanged: (value) {
                  setState(() {
                    _useRealtimeData = value;
                    if (!value) _loadChartData();
                  });
                },
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          height: 60,
          color: cardColor,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _useRealtimeData ? _binanceIntervals.length : _timeframes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (_useRealtimeData) {
                final interval = _binanceIntervals[index];
                final isSelected = interval == _selectedInterval;
                return ChoiceChip(
                  label: Text(interval.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedInterval = interval);
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              } else {
                final tf = _timeframes[index];
                final isSelected = tf == _selectedTimeframe;
                return ChoiceChip(
                  label: Text(tf),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedTimeframe = tf);
                      _loadChartData();
                    }
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }
            },
          ),
        ),
        Expanded(
          child: _useRealtimeData
              ? TradingView(
                  symbol: _convertToBinanceSymbol(widget.coin.id),
                  interval: _selectedInterval,
                )
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chartData.isEmpty
                      ? const Center(child: Text('No chart data available'))
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey.withOpacity(0.1),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '\$${value.toInt()}',
                                        style: TextStyle(fontSize: 10, color: subtextColor),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _chartData,
                                  isCurved: true,
                                  color: widget.coin.change >= 0 ? Colors.green : Colors.red,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: (widget.coin.change >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildStatsTab(bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Price Statistics',
          [
            _buildStatRow("24h High", "\$${(widget.coin.price * 1.05).toStringAsFixed(2)}", textColor, subtextColor),
            _buildStatRow("24h Low", "\$${(widget.coin.price * 0.95).toStringAsFixed(2)}", textColor, subtextColor),
            _buildStatRow("All Time High", "\$${(widget.coin.price * 2).toStringAsFixed(2)}", textColor, subtextColor),
            _buildStatRow("Price Change 24h", "${widget.coin.change >= 0 ? '+' : ''}${widget.coin.change.toStringAsFixed(2)}%", textColor, subtextColor),
          ],
          isDark,
          cardColor,
          textColor,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Market Data',
          [
            _buildStatRow("Market Cap", "\$${((widget.coin.price * 1000000000) / 1000000000).toStringAsFixed(2)}B", textColor, subtextColor),
            _buildStatRow("24h Volume", "\$${((widget.coin.price * 100000000) / 1000000).toStringAsFixed(2)}M", textColor, subtextColor),
            _buildStatRow("Circulating Supply", "19.5M ${widget.coin.symbol.toUpperCase()}", textColor, subtextColor),
            _buildStatRow("Total Supply", "21M ${widget.coin.symbol.toUpperCase()}", textColor, subtextColor),
          ],
          isDark,
          cardColor,
          textColor,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'About ${widget.coin.name}',
          [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '${widget.coin.name} is a cryptocurrency with real-time price updates and live trade streaming powered by Binance WebSocket.',
                style: TextStyle(
                  color: subtextColor,
                  height: 1.5,
                ),
              ),
            ),
          ],
          isDark,
          cardColor,
          textColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, List<Widget> children, bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color textColor, Color subtextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: subtextColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}