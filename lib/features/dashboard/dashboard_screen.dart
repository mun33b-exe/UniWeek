import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/services/notification_service.dart';
import 'package:uni_week/features/dashboard/handler_view.dart';
import 'package:uni_week/features/dashboard/student_dashboard.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _role;
  String? _userId;
  bool _isLoading = true;
  StreamSubscription? _notificationSubscription;
  final _notificationService = NotificationService();
  final Set<String> _shownNotificationIds = {}; // Track shown notifications

  @override
  void initState() {
    super.initState();
    _checkRole();
    _initNotifications();
  }

  Future<void> _checkRole() async {
    debugPrint('🔍 Checking role...');
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      final profile = await supabase.getUserProfile();
      debugPrint('👤 Profile fetched: ${profile?['id']}');

      if (mounted) {
        setState(() {
          _role = profile?['role'];
          _userId = profile?['id'];
          _isLoading = false;
        });

        // Start listening for notifications
        if (_userId != null) {
          debugPrint('🔔 Starting notification listener for $_userId');
          _listenToNotifications();
        } else {
          debugPrint('⚠️ User ID is null, cannot listen to notifications');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking role: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  void _listenToNotifications() {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    _notificationSubscription?.cancel(); // Cancel any existing subscription

    _notificationSubscription = supabase
        .listenToNotifications(_userId!)
        .listen(
          (notifications) {
            if (notifications.isEmpty || !mounted) return;

            // Find the first unread notification that we haven't shown yet
            for (final notification in notifications) {
              final id = notification['id'] as String;
              final isRead = notification['read'] as bool?;

              if (isRead == false && !_shownNotificationIds.contains(id)) {
                _shownNotificationIds.add(id); // Mark as shown

                final title =
                    notification['title'] as String? ?? 'Notification';
                final body = notification['body'] as String? ?? '';

                // Show snackbar
                _showNotificationSnackBar(title, body, id);

                // Show local notification
                _notificationService.showNotification(title: title, body: body);

                break; // Only show one at a time
              }
            }
          },
          onError: (error) {
            debugPrint('❌ Notification listener error: $error');
          },
        );

    debugPrint('🔔 Notification listener started for user: $_userId');
  }

  void _showNotificationSnackBar(String title, String body, String id) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(body),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            if (!mounted) return;
            Provider.of<SupabaseService>(
              context,
              listen: false,
            ).markNotificationAsRead(id);
          },
        ),
      ),
    );

    // Mark as read after showing
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Provider.of<SupabaseService>(
          context,
          listen: false,
        ).markNotificationAsRead(id);
      }
    });

    debugPrint('🔔 Showed notification: $title');
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == 'handler') {
      return const HandlerView();
    }

    return const StudentDashboard();
  }
}
