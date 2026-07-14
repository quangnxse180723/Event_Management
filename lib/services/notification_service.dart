import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationType {
  success,
  error,
  warning,
  info
}

class NotificationService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  // Flutter Local Notifications Plugin
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initLocalNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        const InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(settings: initializationSettings);
  }

  static void initRealtimeListener() {
    Supabase.instance.client
        .channel('public:event')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'event',
            callback: (payload) {
              final newEvent = payload.newRecord;
              if (newEvent != null) {
                final title = newEvent['title'] ?? 'Sự kiện mới';
                showLocalNotification('Sự kiện mới!', title.toString());
              }
            })
        .subscribe();
  }

  static Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'event_channel_id',
      'Sự kiện mới',
      channelDescription: 'Thông báo về sự kiện mới',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<void> scheduleEventReminder(
      int id, String title, String body, DateTime scheduledTime) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reminder_channel_id',
      'Nhắc nhở sự kiện',
      channelDescription: 'Nhắc nhở trước khi sự kiện bắt đầu',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return; // Cannot schedule in the past
    }

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelScheduledNotification(int id) async {
    await _localNotificationsPlugin.cancel(id: id);
  }

  /// Hiển thị thông báo thành công
  static void showSuccess(BuildContext context, String message) {
    _showNotification(context, message, NotificationType.success);
  }

  /// Hiển thị thông báo lỗi
  static void showError(BuildContext context, String message) {
    _showNotification(context, message, NotificationType.error);
  }

  /// Hiển thị thông báo cảnh báo
  static void showWarning(BuildContext context, String message) {
    _showNotification(context, message, NotificationType.warning);
  }

  /// Hiển thị thông báo thông tin
  static void showInfo(BuildContext context, String message) {
    _showNotification(context, message, NotificationType.info);
  }

  /// Hiển thị thông báo tùy chỉnh
  static void showCustom(
    BuildContext context, 
    String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context, 
      message, 
      NotificationType.info,
      backgroundColor: backgroundColor,
      textColor: textColor,
      icon: icon,
      duration: duration,
    );
  }

  static void _showNotification(
    BuildContext context,
    String message,
    NotificationType type, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (_isShowing) {
      _hideNotification();
    }

    _isShowing = true;
    
    final overlay = Overlay.of(context);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => CustomNotificationWidget(
        message: message,
        type: type,
        backgroundColor: backgroundColor,
        textColor: textColor,
        icon: icon,
        onDismiss: _hideNotification,
      ),
    );

    overlay.insert(_overlayEntry!);

    // Tự động ẩn sau thời gian chỉ định
    Future.delayed(duration, () {
      _hideNotification();
    });
  }

  static void _hideNotification() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowing = false;
    }
  }

  /// Ẩn thông báo ngay lập tức
  static void hide() {
    _hideNotification();
  }
}

class CustomNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback onDismiss;

  const CustomNotificationWidget({
    Key? key,
    required this.message,
    required this.type,
    this.backgroundColor,
    this.textColor,
    this.icon,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<CustomNotificationWidget> createState() => _CustomNotificationWidgetState();
}

class _CustomNotificationWidgetState extends State<CustomNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    
    switch (widget.type) {
      case NotificationType.success:
        return Colors.green.shade600;
      case NotificationType.error:
        return Colors.red.shade600;
      case NotificationType.warning:
        return Colors.orange.shade600;
      case NotificationType.info:
        return Colors.blue.shade600;
    }
  }

  Color _getTextColor() {
    return widget.textColor ?? Colors.white;
  }

  IconData _getIcon() {
    if (widget.icon != null) return widget.icon!;
    
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final notificationWidth =
        screenWidth < 420 ? screenWidth - 32 : 360.0;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: notificationWidth,
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getIcon(),
                              color: _getTextColor(),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: TextStyle(
                                  color: _getTextColor(),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                await _animationController.reverse();
                                widget.onDismiss();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: _getTextColor(),
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
