import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notification_fcm/models/message_model.dart';
import 'package:notification_fcm/models/user_model.dart';
import 'package:notification_fcm/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
  }

  // Get all users except current user
  Stream<List<UserModel>> getAllUsers(String currentUserId) {
    return _firestore
        .collection('users')
        .where('uid', isNotEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromDocument(doc))
            .toList()
          ..sort(
              (a, b) => b.lastSeen?.compareTo(a.lastSeen ?? DateTime(0)) ?? 0));
  }

  // Send message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    final chatId = MessageModel.createChatId(senderId, receiverId);
    final timestamp = DateTime.now();
    final messageId = _firestore.collection('chats').doc().id;

    final message = MessageModel(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
    );

    // Add message to chat collection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(message.toMap());

    // Update last message in both users' contact lists
    await Future.wait([
      _updateLastMessage(senderId, receiverId, content, timestamp),
      _updateLastMessage(receiverId, senderId, content, timestamp),
    ]);

    // Send notification to receiver
    // Note: You'll need to implement the notification sending logic
    // using your existing notification service
  }

  // Get messages stream for a chat
  Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    final chatId = MessageModel.createChatId(userId1, userId2);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(
      String currentUserId, String otherUserId) async {
    final chatId = MessageModel.createChatId(currentUserId, otherUserId);
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // Get unread messages count
  Stream<int> getUnreadMessagesCount(String userId) {
    return _firestore
        .collectionGroup('messages')
        .where('receiverId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Update last message in contacts
  Future<void> _updateLastMessage(
    String userId,
    String contactId,
    String lastMessage,
    DateTime timestamp,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .doc(
          contactId,
        )
        .set({
      'lastMessage': lastMessage,
      'timestamp': timestamp,
      'contactId': contactId,
    }, SetOptions(merge: true));
  }

  // Get user's contacts with last messages
  Stream<List<Map<String, dynamic>>> getUserContacts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('contacts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> contacts = [];
      for (var doc in snapshot.docs) {
        final contactId = doc.data()['contactId'] as String;
        final userDoc =
            await _firestore.collection('users').doc(contactId).get();
        if (userDoc.exists) {
          contacts.add({
            'user': UserModel.fromDocument(userDoc),
            'lastMessage': doc.data()['lastMessage'],
            'timestamp': (doc.data()['timestamp'] as Timestamp).toDate(),
          });
        }
      }
      return contacts;
    });
  }
}
