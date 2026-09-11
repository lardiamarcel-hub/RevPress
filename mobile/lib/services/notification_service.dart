import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère l'abonnement au topic FCM `digest_pret` et l'affichage des
/// notifications reçues au premier plan.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _digestTopic = 'digest_pret';

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      if (enabled) {
        await FirebaseMessaging.instance.subscribeToTopic(_digestTopic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_digestTopic);
      }
    } catch (_) {
      // Pas de backend connecté : préférence conservée localement, sans effet réseau.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    const androidDetails = AndroidNotificationDetails(
      'digest_channel',
      'Revue de presse économique',
      channelDescription: 'Notification du digest quotidien/hebdomadaire',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }
}
