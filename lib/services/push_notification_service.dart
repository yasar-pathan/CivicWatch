import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:civic_watch/services/notification_navigation_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handling hook kept minimal for now.
  debugPrint('Background message received: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('FCM permission status: ${settings.authorizationStatus}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.messageId}');
    });

    await _persistCurrentToken();

    _messaging.onTokenRefresh.listen((token) async {
      await _persistToken(token);
    });
  }

  Future<void> initializeWithNavigator({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    await initialize();

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _openFromMessage(message, navigatorKey);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await _openFromMessage(initialMessage, navigatorKey);
    }
  }

  Future<void> _openFromMessage(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    await NotificationNavigationService.openFromPayload(
      context,
      issueId: message.data['issueId'],
      route: message.data['route'],
    );
  }

  Future<void> _persistCurrentToken() async {
    final token = await _messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await _persistToken(token);
    }
  }

  Future<void> _persistToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore.collection('users').doc(uid).set({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
