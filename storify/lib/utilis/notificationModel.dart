import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String userRole; // 'admin', 'supplier', 'customer', or 'all'
  final String userId; // Optional: specific user ID if needed
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId; // Order ID, product ID, etc.

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.userRole,
    this.userId = '',
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      message: data['message'] ?? '',
      userRole: data['userRole'] ?? 'all',
      userId: data['userId'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['read'] ?? false,
      relatedId: data['relatedId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'userRole': userRole,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': isRead,
      'relatedId': relatedId,
    };
  }
}
