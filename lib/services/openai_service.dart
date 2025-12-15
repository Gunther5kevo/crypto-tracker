// lib/services/openai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class OpenAIService {
  static const String _historyKey = 'chat_history';
  
  static String get _apiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (e) {
      debugPrint('⚠️ Error accessing .env: $e');
      return '';
    }
  }
  
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Store conversation history
  final List<ChatMessage> _conversationHistory = [];
  
  List<ChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  
  void clearHistory() {
    _conversationHistory.clear();
  }

  // Load chat history from persistent storage
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _conversationHistory.clear();
        _conversationHistory.addAll(
          decoded.map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
        );
        debugPrint('✅ Loaded ${_conversationHistory.length} messages from history');
      } else {
        debugPrint('ℹ️ No chat history found');
      }
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
      // Don't rethrow - just start with empty history
    }
  }

  // Save chat history to persistent storage
  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _conversationHistory.map((msg) => msg.toJson()).toList()
      );
      await prefs.setString(_historyKey, historyJson);
      debugPrint('✅ Saved ${_conversationHistory.length} messages to history');
    } catch (e) {
      debugPrint('❌ Error saving chat history: $e');
      // Don't rethrow - history saving is non-critical
    }
  }

  // Original market analysis method - now returns parsed data directly
  Future<Map<String, dynamic>> getMarketAnalysis({
    required List<String> symbols,
    required List<double> prices,
    required List<double> changes,
  }) async {
    debugPrint('═══════════════════════════════════════');
    debugPrint('🤖 OpenAI Service - Starting Analysis');
    debugPrint('═══════════════════════════════════════');
    
    if (_apiKey.isEmpty) {
      debugPrint('❌ ERROR: API key is empty');
      return _getFallbackData('API key not configured. Please add OPENAI_API_KEY to .env file and restart the app.');
    }
    
    debugPrint('✅ API Key found (length: ${_apiKey.length})');
    debugPrint('📊 Analyzing ${symbols.length} coins: ${symbols.join(', ')}');

    final marketData = List.generate(symbols.length, (i) {
      return '${symbols[i]}: \$${prices[i].toStringAsFixed(2)} (${changes[i] >= 0 ? '+' : ''}${changes[i].toStringAsFixed(2)}%)';
    }).join(', ');

    final prompt = """
You are an expert crypto market analyst. Analyze the following cryptocurrency market data and provide insights.

CURRENT MARKET DATA (${symbols.length} coins):
$marketData

Provide a comprehensive analysis in JSON format with the following structure:
{
  "market_summary": "2-3 sentence overview of current market conditions and trends",
  "top_picks": ["Coin1", "Coin2", "Coin3"],
  "risk_score": 65,
  "sentiment": "Fear",
  "opportunities": "Key opportunities in the market right now",
  "risks": "Main risks to watch out for",
  "key_insight": "One actionable insight for traders/investors"
}

IMPORTANT: Respond ONLY with the JSON object. No markdown, no code blocks, no extra text. Just pure JSON.
""";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a concise crypto market analyst. Always respond with valid JSON only, no markdown formatting, no code blocks, just pure JSON.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 600,
        }),
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString();
        
        debugPrint('📄 Raw AI Response (first 200 chars):');
        debugPrint(content.substring(0, content.length > 200 ? 200 : content.length));
        
        // More aggressive cleaning
        String cleanContent = content.trim();
        
        // Remove ALL markdown code blocks
        cleanContent = cleanContent.replaceAll(RegExp(r'```[a-z]*\s*'), '');
        cleanContent = cleanContent.replaceAll(RegExp(r'```'), '');
        
        // Remove any leading/trailing whitespace and newlines
        cleanContent = cleanContent.trim();
        
        // Find the first { and last }
        final firstBrace = cleanContent.indexOf('{');
        final lastBrace = cleanContent.lastIndexOf('}');
        
        if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
          cleanContent = cleanContent.substring(firstBrace, lastBrace + 1);
        }
        
        debugPrint('🧹 Cleaned content length: ${cleanContent.length}');
        
        try {
          final result = jsonDecode(cleanContent) as Map<String, dynamic>;
          
          // Validate required fields
          final requiredFields = ['market_summary', 'top_picks', 'risk_score', 'sentiment', 'key_insight'];
          
          for (final field in requiredFields) {
            if (!result.containsKey(field)) {
              throw Exception('Missing required field: $field');
            }
          }
          
          debugPrint('✅ Successfully parsed and validated AI analysis');
          debugPrint('═══════════════════════════════════════');
          
          return result;
        } catch (e) {
          debugPrint('❌ JSON Parse Error: $e');
          debugPrint('Problematic content:');
          debugPrint(cleanContent);
          
          // Try to extract JSON using regex as last resort
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleanContent);
          if (jsonMatch != null) {
            final extractedJson = jsonMatch.group(0)!;
            debugPrint('🔧 Attempting to parse extracted JSON...');
            return jsonDecode(extractedJson) as Map<String, dynamic>;
          }
          
          rethrow;
        }
      } else {
        _handleHttpError(response);
      }
    } catch (e) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('❌ EXCEPTION CAUGHT');
      debugPrint('Error: $e');
      debugPrint('═══════════════════════════════════════');
      rethrow;
    }
    
    // This should never be reached, but Dart requires a return
    throw Exception('Unexpected code path');
  }

  // Conversational chat method with auto-save option
  Future<String> sendChatMessage({
    required String message,
    required List<String> symbols,
    required List<double> prices,
    required List<double> changes,
    bool autoSave = true,
  }) async {
    debugPrint('💬 Sending chat message: $message');
    
    if (_apiKey.isEmpty) {
      throw Exception('API key not configured');
    }

    // Build market context
    final marketData = List.generate(symbols.length, (i) {
      return '${symbols[i]}: \$${prices[i].toStringAsFixed(2)} (${changes[i] >= 0 ? '+' : ''}${changes[i].toStringAsFixed(2)}%)';
    }).join('\n');

    // Add user message to history
    _conversationHistory.add(ChatMessage(role: 'user', content: message));

    // Build messages array with context
    final messages = [
      {
        'role': 'system',
        'content': '''You are an expert crypto market analyst assistant. You have access to current market data and can answer questions about it conversationally.

CURRENT MARKET DATA:
$marketData

Guidelines:
- Be conversational and helpful
- Reference specific coins and prices when relevant
- Keep responses concise (2-3 sentences for simple questions, longer for complex analysis)
- Use emojis sparingly but naturally
- If asked about a specific coin, provide its current price and change
- Be honest if you don't have enough information
- Never give direct financial advice, always say "do your own research"'''
      },
      ..._conversationHistory.map((msg) => msg.toJson()),
    ];

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'temperature': 0.8,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['choices'][0]['message']['content'].toString().trim();
        
        // Add assistant response to history
        _conversationHistory.add(ChatMessage(role: 'assistant', content: assistantMessage));
        
        // Auto-save history if enabled
        if (autoSave) {
          await saveHistory();
        }
        
        debugPrint('✅ Chat response received');
        return assistantMessage;
      } else {
        _handleHttpError(response);
      }
    } catch (e) {
      debugPrint('❌ Chat error: $e');
      rethrow;
    }
    
    throw Exception('Unexpected code path');
  }

  void _handleHttpError(http.Response response) {
    debugPrint('❌ API Error: Status ${response.statusCode}');
    
    if (response.statusCode == 401) {
      throw Exception('Invalid OpenAI API key. Please check your .env file.');
    } else if (response.statusCode == 429) {
      throw Exception('OpenAI rate limit exceeded. Please try again in a moment.');
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']['message'] ?? 'Unknown error';
        throw Exception('OpenAI API error: $errorMessage');
      } catch (e) {
        throw Exception('API returned ${response.statusCode}');
      }
    }
  }

  Map<String, dynamic> _getFallbackData(String message) {
    return {
      "market_summary": message,
      "top_picks": ["BTC", "ETH", "SOL"],
      "risk_score": 50,
      "sentiment": "Neutral",
      "opportunities": "Market data temporarily unavailable",
      "risks": "Unable to assess current risks",
      "key_insight": "Configure API key to get live analysis"
    };
  }
}