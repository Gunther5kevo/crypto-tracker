// lib/services/chat_history_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'openai_service.dart';

class ChatHistoryService {
  static final ChatHistoryService instance = ChatHistoryService._();
  ChatHistoryService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get user's chat collection reference
  CollectionReference? get _chatCollection {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_chat_history');
  }

  // Save a single message
  Future<void> saveMessage(ChatMessage message) async {
    try {
      final collection = _chatCollection;
      if (collection == null) {
        debugPrint('⚠️ No user logged in, cannot save chat message');
        return;
      }

      await collection.add({
        'role': message.role,
        'content': message.content,
        'timestamp': FieldValue.serverTimestamp(),
        'localTimestamp': message.timestamp.toIso8601String(),
      });

      debugPrint('✅ Chat message saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving chat message: $e');
    }
  }

  // Save multiple messages (batch operation)
  Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final collection = _chatCollection;
      if (collection == null) {
        debugPrint('⚠️ No user logged in, cannot save chat messages');
        return;
      }

      if (messages.isEmpty) return;

      final batch = _firestore.batch();

      for (final message in messages) {
        final docRef = collection.doc();
        batch.set(docRef, {
          'role': message.role,
          'content': message.content,
          'timestamp': FieldValue.serverTimestamp(),
          'localTimestamp': message.timestamp.toIso8601String(),
        });
      }

      await batch.commit();
      debugPrint('✅ ${messages.length} chat messages saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving chat messages: $e');
    }
  }

  // Load chat history for current user
  Future<List<ChatMessage>> loadChatHistory() async {
    try {
      final collection = _chatCollection;
      if (collection == null) {
        debugPrint('⚠️ No user logged in, cannot load chat history');
        return [];
      }

      final snapshot = await collection
          .orderBy('timestamp', descending: false)
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Parse timestamp
        DateTime timestamp;
        if (data['timestamp'] != null) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['localTimestamp'] != null) {
          timestamp = DateTime.parse(data['localTimestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return ChatMessage(
          role: data['role'] as String,
          content: data['content'] as String,
          timestamp: timestamp,
        );
      }).toList();

      debugPrint('✅ Loaded ${messages.length} chat messages from Firestore');
      return messages;
    } catch (e) {
      debugPrint('❌ Error loading chat history: $e');
      return [];
    }
  }

  // Stream chat history (real-time updates)
  Stream<List<ChatMessage>> streamChatHistory() {
    final collection = _chatCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        DateTime timestamp;
        if (data['timestamp'] != null) {
          timestamp = (data['timestamp'] as Timestamp).toDate();
        } else if (data['localTimestamp'] != null) {
          timestamp = DateTime.parse(data['localTimestamp']);
        } else {
          timestamp = DateTime.now();
        }

        return ChatMessage(
          role: data['role'] as String,
          content: data['content'] as String,
          timestamp: timestamp,
        );
      }).toList();
    });
  }

  // Clear chat history for current user
  Future<void> clearChatHistory() async {
    try {
      final collection = _chatCollection;
      if (collection == null) {
        debugPrint('⚠️ No user logged in, cannot clear chat history');
        return;
      }

      final snapshot = await collection.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('✅ Chat history cleared from Firestore');
    } catch (e) {
      debugPrint('❌ Error clearing chat history: $e');
    }
  }

  // Delete a specific message
  Future<void> deleteMessage(String messageId) async {
    try {
      final collection = _chatCollection;
      if (collection == null) return;

      await collection.doc(messageId).delete();
      debugPrint('✅ Chat message deleted from Firestore');
    } catch (e) {
      debugPrint('❌ Error deleting chat message: $e');
    }
  }

  // Get chat statistics
  Future<Map<String, dynamic>> getChatStats() async {
    try {
      final collection = _chatCollection;
      if (collection == null) {
        return {
          'totalMessages': 0,
          'userMessages': 0,
          'aiMessages': 0,
          'lastMessageTime': null,
        };
      }

      final snapshot = await collection.get();
      final messages = snapshot.docs;

      final userMessages = messages.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'user';
      }).length;

      final aiMessages = messages.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] == 'assistant';
      }).length;

      DateTime? lastMessageTime;
      if (messages.isNotEmpty) {
        final lastDoc = messages.last.data() as Map<String, dynamic>;
        if (lastDoc['timestamp'] != null) {
          lastMessageTime = (lastDoc['timestamp'] as Timestamp).toDate();
        }
      }

      return {
        'totalMessages': messages.length,
        'userMessages': userMessages,
        'aiMessages': aiMessages,
        'lastMessageTime': lastMessageTime,
      };
    } catch (e) {
      debugPrint('❌ Error getting chat stats: $e');
      return {
        'totalMessages': 0,
        'userMessages': 0,
        'aiMessages': 0,
        'lastMessageTime': null,
      };
    }
  }

  // Export chat history as text
  Future<String> exportChatHistory() async {
    try {
      final messages = await loadChatHistory();
      final buffer = StringBuffer();
      
      buffer.writeln('=== AI Crypto Analyst Chat History ===');
      buffer.writeln('Exported: ${DateTime.now()}');
      buffer.writeln('Total Messages: ${messages.length}');
      buffer.writeln('');

      for (final message in messages) {
        final role = message.role == 'user' ? 'You' : 'AI';
        buffer.writeln('[$role] ${message.timestamp}');
        buffer.writeln(message.content);
        buffer.writeln('');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('❌ Error exporting chat history: $e');
      return '';
    }
  }
}