import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  final int userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('notification')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId, int index) async {
    // Optimistic UI update
    setState(() {
      _notifications[index]['is_read'] = true;
    });

    try {
      await Supabase.instance.client
          .from('notification')
          .update({'is_read': true})
          .eq('notification_id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert if failed (optional)
      setState(() {
        _notifications[index]['is_read'] = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await Supabase.instance.client
          .from('notification')
          .update({'is_read': true})
          .eq('user_id', widget.userId)
          .eq('is_read', false);
          
      _fetchNotifications();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Vừa xong';
          }
          return '${difference.inMinutes} phút trước';
        }
        return '${difference.inHours} giờ trước';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ngày trước';
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Đánh dấu tất cả đã đọc',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Bạn chưa có thông báo nào.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['is_read'] == true;
                      
                      return InkWell(
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(notification['notification_id'], index);
                          }
                          // Hiện dialog hoặc chuyển hướng tuỳ logic sau này
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(notification['title'] ?? ''),
                              content: Text(notification['message'] ?? ''),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Đóng'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.event_note,
                                  color: isRead ? Colors.grey.shade600 : Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['message'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatDate(notification['created_at'] ?? ''),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
