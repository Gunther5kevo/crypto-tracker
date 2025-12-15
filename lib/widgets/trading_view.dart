import 'package:flutter/material.dart';
import '../services/binance_stream_service.dart';

class TradingView extends StatefulWidget {
  final String symbol;
  final String interval;
  
  const TradingView({
    super.key, 
    required this.symbol,
    this.interval = '1m',
  });

  @override
  State<TradingView> createState() => _TradingViewState();
}

class _TradingViewState extends State<TradingView> {
  final _service = BinanceService();
  late String _interval;
  PriceData? _currentPrice;
  List<Trade> _trades = [];
  
  @override
  void initState() {
    super.initState();
    _interval = widget.interval;
    _connect();
  }
  
  @override
  void didUpdateWidget(TradingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol || oldWidget.interval != widget.interval) {
      _interval = widget.interval;
      _connect();
    }
  }
  
  void _connect() {
    _service.connect(widget.symbol, _interval);
    
    _service.priceStream.listen((price) {
      if (mounted) setState(() => _currentPrice = price);
    });
    
    _service.tradesStream.listen((trades) {
      if (mounted) setState(() => _trades = trades);
    });
  }
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF0B0E11) : Colors.grey[100],
      child: Row(
        children: [
          // Main chart area
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildPriceHeader(isDark),
                Expanded(child: _buildChart(isDark)),
              ],
            ),
          ),
          
          // Recent trades panel
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2329) : Colors.white,
              border: Border(
                left: BorderSide(
                  color: isDark ? const Color(0xFF2B3139) : Colors.grey[300]!,
                ),
              ),
            ),
            child: _buildTradesPanel(isDark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceHeader(bool isDark) {
    if (_currentPrice == null) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        color: isDark ? const Color(0xFF1E2329) : Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2329) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2B3139) : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${_currentPrice!.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'H: \$${_currentPrice!.high.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'L: \$${_currentPrice!.low.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Vol: ${(_currentPrice!.volume / 1000).toStringAsFixed(1)}K',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChart(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2329) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2B3139) : Colors.grey[300]!,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Live Price: \$${_currentPrice?.price.toStringAsFixed(2) ?? '---'}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interval: $_interval',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Streaming real-time data from Binance',
              style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTradesPanel(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF2B3139) : Colors.grey[300]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Recent Trades',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_trades.length}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _trades.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading trades...',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _trades.length,
                  itemBuilder: (context, i) {
                    final trade = _trades[i];
                    final isBuy = !trade.isBuyerMaker;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isBuy 
                            ? Colors.green.withOpacity(0.03)
                            : Colors.red.withOpacity(0.03),
                        border: Border(
                          bottom: BorderSide(
                            color: (isDark ? const Color(0xFF2B3139) : Colors.grey[300]!)
                                .withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '\$${trade.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isBuy ? Colors.green : Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              trade.quantity.toStringAsFixed(4),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${trade.time.hour}:${trade.time.minute.toString().padLeft(2, '0')}:${trade.time.second.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: isDark ? Colors.grey[600] : Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}