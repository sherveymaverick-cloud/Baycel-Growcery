import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeNative();
    }
  }

  Future<void> _initializeWeb() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Web notification permission: ${settings.authorizationStatus}');
      
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
      
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Web foreground message: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('Web notification init skipped: $e');
    }
  }

  Future<void> _initializeNative() async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _setupMessageHandlers();
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
    );
    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings);
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened: ${message.notification?.title}');
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'baycel_growcery',
      'Baycel Growcery',
      channelDescription: 'Notifications for Baycel Growcery',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> sendLowStockAlert(String productName, int currentStock, int reorderLevel) async {
    final users = await FirebaseFirestore.instance.collection('users').where('role', whereIn: ['owner', 'manager', 'bodegero']).get();
    for (final doc in users.docs) {
      await _sendToUser(doc.id, 'Low Stock Alert', '$productName is low on stock ($currentStock remaining)', 'low_stock');
    }
  }

  static Future<void> sendCashAdvanceRequest(String employeeName, double amount, String employeeId) async {
    final users = await FirebaseFirestore.instance.collection('users').where('role', whereIn: ['owner', 'manager']).get();
    for (final doc in users.docs) {
      await _sendToUser(doc.id, 'Cash Advance Request', '$employeeName requested ₱${amount.toStringAsFixed(0)} cash advance', 'cash_advance');
    }
  }

  static Future<void> sendAbsenceRequest(String employeeName, String reason, String employeeId) async {
    final users = await FirebaseFirestore.instance.collection('users').where('role', whereIn: ['owner', 'manager']).get();
    for (final doc in users.docs) {
      await _sendToUser(doc.id, 'Absence Request', '$employeeName submitted an absence form: $reason', 'absence');
    }
  }

  static Future<void> sendPayrollReady(String employeeName, double netPay, String employeeId) async {
    await _sendToUser(employeeId, 'Payroll Ready', 'Your payslip for ₱${netPay.toStringAsFixed(0)} is ready', 'payroll');
  }

  static Future<void> sendCashAdvanceStatus(double amount, String status, String employeeId, {String? note}) async {
    final approved = status == 'approved';
    var body = 'Your cash advance request of ₱${amount.toStringAsFixed(0)} was ${approved ? 'approved' : 'rejected'}';
    if (!approved && note != null && note.isNotEmpty) {
      body += '. Reason: $note';
    }
    await _sendToUser(
      employeeId,
      approved ? 'Cash Advance Approved' : 'Cash Advance Rejected',
      body,
      'cash_advance',
    );
  }

  static Future<void> sendAbsenceStatus(String status, String employeeId, {String? comment}) async {
    final approved = status == 'approved';
    var body = 'Your absence form was ${approved ? 'approved' : 'rejected'}';
    if (!approved && comment != null && comment.isNotEmpty) {
      body += '. Reason: $comment';
    }
    await _sendToUser(
      employeeId,
      approved ? 'Absence Approved' : 'Absence Rejected',
      body,
      'absence',
    );
  }

  static Future<void> _sendToUser(String userId, String title, String body, String type) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Failed to send notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

void setupBackgroundMessaging() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
