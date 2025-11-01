import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notifications/notification_service.dart';
import 'package:flutter_riverpod/legacy.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final svc = NotificationService();
  svc.init();
  return svc;
});
final badgeCountProvider = StateProvider<int>((_) => 0);
