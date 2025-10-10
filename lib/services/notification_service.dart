import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  warning,
  info
}

class NotificationService {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

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
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}