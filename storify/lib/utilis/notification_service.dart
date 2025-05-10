import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notificationModel.dart';
import 'notificationDatabaseService.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final NotificationDatabaseService _databaseService =
      NotificationDatabaseService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final List<Function(List<NotificationItem>)>
      _notificationsListChangedCallbacks = [];
  List<NotificationItem> _cachedNotifications = [];

  // Initialize the notification service
  Future<void> initialize() async {
    // Initialize Firebase if not already initialized
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Firebase already initialized or error: $e');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permission for push notifications
    await _requestNotificationPermissions();

    // Listen for notifications based on user role
    _listenForNotifications();

    // Set up Firebase Messaging handlers
    _setupFirebaseMessaging();
  }

  Future<void> _requestNotificationPermissions() async {
    // Request permission for Firebase Messaging
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print(
          'User granted notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  void _listenForNotifications() async {
    final userRole = await _databaseService.getCurrentUserRole();

    // Listen for notifications from Firestore
    _databaseService.getNotificationsForRole(userRole).listen((notifications) {
      _cachedNotifications = notifications;

      // Notify all registered callbacks
      for (var callback in _notificationsListChangedCallbacks) {
        callback(notifications);
      }
    });
  }

  void _setupFirebaseMessaging() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showFirebaseNotification(message);
      }
    });

    // Handle notification tap when app is in background but open
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A notification was tapped: ${message.data}');
      // Navigate to specific screen if needed
    });

    // Get FCM token and save it
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Save token to shared preferences or database
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', token);
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _showFirebaseNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'storify_notifications',
      'Storify Notifications',
      channelDescription: 'Notifications from Storify app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Register a callback to be notified when the notifications list changes
  void registerNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.add(callback);

    // Immediately call with cached notifications if available
    if (_cachedNotifications.isNotEmpty) {
      callback(_cachedNotifications);
    }
  }

  // Unregister a callback
  void unregisterNotificationsListChangedCallback(
      Function(List<NotificationItem>) callback) {
    _notificationsListChangedCallbacks.remove(callback);
  }

  // Get all notifications for the current user
  List<NotificationItem> getNotifications() {
    return _cachedNotifications;
  }

  // Show a local notification
  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'storify_notifications',
      'Storify Notifications',
      channelDescription: 'Notifications from Storify app',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Send notification when an order is created (admin to supplier)
  Future<void> sendOrderCreatedNotification(
    String supplierId,
    String orderId,
    String orderDetails,
  ) async {
    final notification = NotificationItem(
      id: '',
      title: 'New Order Created',
      message: 'A new order #$orderId has been created. $orderDetails',
      userRole: 'supplier',
      userId: supplierId,
      timestamp: DateTime.now(),
      relatedId: orderId,
    );

    await _databaseService.addNotification(notification);

    // Show local notification if the current user is the supplier
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? '';
    final currentId = prefs.getString('userId') ?? '';

    if (currentRole == 'supplier' &&
        (currentId == supplierId || supplierId.isEmpty)) {
      await showLocalNotification(notification.title, notification.message);
    }
  }

  // Send notification when an order is accepted (supplier to admin)
  Future<void> sendOrderAcceptedNotification(
    String orderId,
    String supplierName,
  ) async {
    final notification = NotificationItem(
      id: '',
      title: 'Order Accepted',
      message: 'Order #$orderId has been accepted by $supplierName',
      userRole: 'admin',
      timestamp: DateTime.now(),
      relatedId: orderId,
    );

    await _databaseService.addNotification(notification);

    // Show local notification if the current user is an admin
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? '';

    if (currentRole == 'admin') {
      await showLocalNotification(notification.title, notification.message);
    }
  }

  // Send notification when an order is rejected (supplier to admin)
  Future<void> sendOrderRejectedNotification(
    String orderId,
    String supplierName,
    String reason,
  ) async {
    final notification = NotificationItem(
      id: '',
      title: 'Order Rejected',
      message:
          'Order #$orderId has been rejected by $supplierName. Reason: $reason',
      userRole: 'admin',
      timestamp: DateTime.now(),
      relatedId: orderId,
    );

    await _databaseService.addNotification(notification);

    // Show local notification if the current user is an admin
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? '';

    if (currentRole == 'admin') {
      await showLocalNotification(notification.title, notification.message);
    }
  }

  // Send notification when order status changes (admin to customer)
  Future<void> sendOrderStatusUpdateNotification(
    String orderId,
    String newStatus,
    String customerEmail,
  ) async {
    String message;
    switch (newStatus.toLowerCase()) {
      case 'prepared':
        message =
            'Your order #$orderId has been prepared and is ready for delivery.';
        break;
      case 'on_theway':
        message = 'Your order #$orderId is on the way to you.';
        break;
      case 'delivered':
        message =
            'Your order #$orderId has been delivered. Thank you for your purchase!';
        break;
      default:
        message = 'Your order #$orderId status has been updated to $newStatus.';
    }

    final notification = NotificationItem(
      id: '',
      title: 'Order Status Update',
      message: message,
      userRole: 'customer',
      userId: customerEmail, // Using email as ID for customers
      timestamp: DateTime.now(),
      relatedId: orderId,
    );

    await _databaseService.addNotification(notification);

    // Show local notification if the current user is the customer
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? '';
    final currentEmail = prefs.getString('userEmail') ?? '';

    if (currentRole == 'customer' && currentEmail == customerEmail) {
      await showLocalNotification(notification.title, notification.message);
    }
  }

  // Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    await _databaseService.markAsRead(notificationId);
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? 'customer';
    await _databaseService.markAllAsRead(currentRole);
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentRole = prefs.getString('userRole') ?? 'customer';
    return await _databaseService.getUnreadNotificationsCount(currentRole);
  }
}
