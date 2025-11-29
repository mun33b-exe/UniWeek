import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/features/dashboard/handler_view.dart';
import 'package:uni_week/features/dashboard/student_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final profile = await supabase.getUserProfile();
    if (mounted) {
      setState(() {
        _role = profile?['role'];
        _isLoading = false;
      });
    }
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
