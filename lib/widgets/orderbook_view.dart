// lib/widgets/orderbook_view.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class OrderBookView extends StatefulWidget {
  final String symbol;
  
  const OrderBookView({super.key, required this.symbol});

  @override
  State<OrderBookView> createState() => _OrderBookViewState();
}

class _OrderBookViewState extends State<OrderBookView> {
  WebSocketChannel? _channel;
  List<OrderBookLevel> _bids = [];
  List<OrderBookLevel> _asks = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _connectToOrderBook();
  }
  
  @override
  void didUpdateWidget(OrderBookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.symbol != widget.symbol) {
      _connectToOrderBook();
    }
  }
  
  void _connectToOrderBook() {
    _channel?.sink.close();
    setState(() {
      _isLoading = true;
      _bids.clear();
      _asks.clear();
    });
    
    final ws = 'wss://stream.binance.com:9443/ws/${widget.symbol.toLowerCase()}@depth20@100ms';
    _channel = WebSocketChannel.connect(Uri.parse(ws));
    
    _channel!.stream.listen((msg) {
      try {
        final data = json.decode(msg);
        
        final bids = (data['bids'] as List).map((bid) {
          return OrderBookLevel(
            price: double.parse(bid[0]),
            quantity: double.parse(bid[1]),
          );
        }).take(15).toList();
        
        final asks = (data['asks'] as List).map((ask) {
          return OrderBookLevel(
            price: double.parse(ask[0]),
            quantity: double.parse(ask[1]),
          );
        }).take(15).toList();
        
        if (mounted) {
          setState(() {
            _bids = bids;
            _asks = asks;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('OrderBook error: $e');
      }
    });
  }
  
  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E11) : Colors.grey[100]!;
    
    if (_isLoading) {
      return Container(
        color: bgColor,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final maxBidQty = _bids.isEmpty ? 1.0 : _bids.map((b) => b.quantity).reduce((a, b) => a > b ? a : b);
    final maxAskQty = _asks.isEmpty ? 1.0 : _asks.map((a) => a.quantity).reduce((a, b) => a > b ? a : b);
    final maxQty = maxBidQty > maxAskQty ? maxBidQty : maxAskQty;
    
    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Header
          Container(
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
                Text(
                  'Order Book',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2329) : Colors.grey[200],
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF2B3139) : Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Price (USDT)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Amount',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Order Book Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Asks (Sell Orders) - Reversed so lowest is at bottom
                ..._asks.reversed.map((ask) => _buildOrderRow(
                  ask,
                  Colors.red,
                  maxQty,
                  isDark,
                )),
                
                // Spread
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2329) : Colors.grey[300],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_flat,
                        size: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _asks.isNotEmpty && _bids.isNotEmpty
                            ? 'Spread: \$${(_asks.first.price - _bids.first.price).toStringAsFixed(2)}'
                            : 'Spread: --',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bids (Buy Orders)
                ..._bids.map((bid) => _buildOrderRow(
                  bid,
                  Colors.green,
                  maxQty,
                  isDark,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderRow(OrderBookLevel level, Color color, double maxQty, bool isDark) {
    final percentage = (level.quantity / maxQty).clamp(0.0, 1.0);
    final total = level.price * level.quantity;
    
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Background bar showing depth
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: percentage * 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.1 : 0.08),
                  ),
                ),
              ),
            ),
          ),
          
          // Text content
          Row(
            children: [
              Expanded(
                child: Text(
                  '\$${level.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  level.quantity.toStringAsFixed(4),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  total.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderBookLevel {
  final double price;
  final double quantity;
  
  OrderBookLevel({required this.price, required this.quantity});
}