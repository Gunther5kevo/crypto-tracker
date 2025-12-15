import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';

class BinanceService {
  WebSocketChannel? _channel;
  WebSocketChannel? _tradeChannel;
  final _priceController = StreamController<PriceData>.broadcast();
  final _tradesController = StreamController<List<Trade>>.broadcast();
  
  Stream<PriceData> get priceStream => _priceController.stream;
  Stream<List<Trade>> get tradesStream => _tradesController.stream;
  
  final List<Trade> _recentTrades = [];
  
  void connect(String symbol, String interval) {
    disconnect();
    
    final ws = 'wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@kline_$interval';
    final tradeWs = 'wss://stream.binance.com:9443/ws/${symbol.toLowerCase()}@trade';
    
    // Price stream
    _channel = WebSocketChannel.connect(Uri.parse(ws));
    _channel!.stream.listen((msg) {
      try {
        final data = json.decode(msg);
        final k = data['k'];
        _priceController.add(PriceData(
          price: double.parse(k['c']),
          high: double.parse(k['h']),
          low: double.parse(k['l']),
          volume: double.parse(k['v']),
        ));
      } catch (e) {
        debugPrint('Price error: $e');
      }
    });
    
    // Trade stream
    _tradeChannel = WebSocketChannel.connect(Uri.parse(tradeWs));
    _tradeChannel!.stream.listen((msg) {
      try {
        final data = json.decode(msg);
        final trade = Trade(
          price: double.parse(data['p']),
          quantity: double.parse(data['q']),
          isBuyerMaker: data['m'],
          time: DateTime.fromMillisecondsSinceEpoch(data['T']),
        );
        
        _recentTrades.insert(0, trade);
        if (_recentTrades.length > 50) _recentTrades.removeLast();
        _tradesController.add(List.from(_recentTrades));
      } catch (e) {
        debugPrint('Trade error: $e');
      }
    });
  }
  
  void disconnect() {
    _channel?.sink.close();
    _tradeChannel?.sink.close();
    _channel = null;
    _tradeChannel = null;
    _recentTrades.clear();
  }
  
  void dispose() {
    disconnect();
    _priceController.close();
    _tradesController.close();
  }
}

class PriceData {
  final double price;
  final double high;
  final double low;
  final double volume;
  
  PriceData({
    required this.price,
    required this.high,
    required this.low,
    required this.volume,
  });
}

class Trade {
  final double price;
  final double quantity;
  final bool isBuyerMaker;
  final DateTime time;
  
  Trade({
    required this.price,
    required this.quantity,
    required this.isBuyerMaker,
    required this.time,
  });
}
