import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notificationModel.dart';

class NotificationDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _notificationsCollection;
  
  // Singleton pattern
  static final NotificationDatabaseService _instance = NotificationDatabaseService._internal();
  
  factory NotificationDatabaseService() {
    return _instance;
  }
  
  NotificationDatabaseService._internal() 
      : _notificationsCollection = FirebaseFirestore.instance.collection('notifications');
  
  // Get notifications for a specific role
  Stream<List<NotificationItem>> getNotificationsForRole(String role) {
    return _notificationsCollection
        .where('userRole', whereIn: [role, 'all'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationItem.fromFirestore(doc))
              .toList();
        });
  }
  
  // Get notifications for a specific user
  Stream<List<NotificationItem>> getNotificationsForUser(String userId, String role) {
    return _notificationsCollection
        .where('userRole', whereIn: [role, 'all'])
        .where('userId', whereIn: [userId, ''])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationItem.fromFirestore(doc))
              .toList();
        });
  }
  
  // Add a new notification
  Future<void> addNotification(NotificationItem notification) async {
    await _notificationsCollection.add(notification.toMap());
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'read': true});
  }
  
  // Mark all notifications as read for a role
  Future<void> markAllAsRead(String role) async {
    final batch = _firestore.batch();
    final snapshots = await _notificationsCollection
        .where('userRole', whereIn: [role, 'all'])
        .where('read', isEqualTo: false)
        .get();
    
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'read': true});
    }
    
    await batch.commit();
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsCollection.doc(notificationId).delete();
  }
  
  // Get current user role from shared preferences
  Future<String> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole') ?? 'customer';
  }
  
  // Get current user ID from shared preferences
  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? '';
  }
  
  // Get unread notifications count for a role
  Future<int> getUnreadNotificationsCount(String role) async {
    final snapshot = await _notificationsCollection
        .where('userRole', whereIn: [role, 'all'])
        .where('read', isEqualTo: false)
        .get();
    
    return snapshot.docs.length;
  }
  
  // Get unread notifications count for a specific user
  Future<int> getUnreadNotificationsCountForUser(String userId, String role) async {
    final snapshot = await _notificationsCollection
        .where('userRole', whereIn: [role, 'all'])
        .where('userId', whereIn: [userId, ''])
        .where('read', isEqualTo: false)
        .get();
    
    return snapshot.docs.length;
  }
}