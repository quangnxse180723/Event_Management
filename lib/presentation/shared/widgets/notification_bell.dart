import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:student_attendance/presentation/notification/notification_screen.dart';

class NotificationBell extends StatefulWidget {
  final int userId;
  final Color iconColor;
  
  const NotificationBell({
    Key? key, 
    required this.userId,
    this.iconColor = Colors.black87,
  }) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int unreadCount = 0;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _setupRealtime();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await Supabase.instance.client
          .from('notification')
          .select('notification_id')
          .eq('user_id', widget.userId)
          .eq('is_read', false);
      if (mounted) {
        setState(() {
          unreadCount = response.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching unread notifications: $e');
    }
  }

  void _setupRealtime() {
    _channel = Supabase.instance.client
        .channel('public:notification:user_${widget.userId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notification',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
             _fetchUnreadCount(); 
          }
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notification',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: widget.userId,
          ),
          callback: (payload) {
             _fetchUnreadCount(); 
          }
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
     return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(userId: widget.userId),
                ),
              ).then((_) => _fetchUnreadCount()); // Refresh when returning
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: Icon(Icons.notifications, color: widget.iconColor),
            ),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
