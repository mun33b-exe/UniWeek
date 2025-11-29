import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/features/auth/login_screen.dart';
import 'package:uni_week/features/dashboard/handler_view.dart';
import 'package:uni_week/features/dashboard/student_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      final profile = await supabase.getUserProfile();
      if (mounted) {
        setState(() {
          _role = profile?['role'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle error, maybe redirect to login if profile not found
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == null) {
      // Fallback if no role found, maybe redirect to login
      return const LoginScreen();
    }

    return _role == 'handler' ? const HandlerView() : const StudentView();
  }
}
