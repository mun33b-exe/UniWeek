import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';
import 'package:uni_week/features/auth/login_screen.dart';
import 'package:uni_week/features/dashboard/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lzbwxlntdsrmzbcxsmni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6Ynd4bG50ZHNybXpiY3hzbW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzODE5NDIsImV4cCI6MjA3OTk1Nzk0Mn0.0beFDCoHQ9SZyaav3eEhN10ODEJIoj1FoQxAY0BMGFw',
  );

  runApp(const UniWeekApp());
}

class UniWeekApp extends StatelessWidget {
  const UniWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [Provider<SupabaseService>(create: (_) => SupabaseService())],
      child: MaterialApp(
        title: 'UniWeek',
        theme: UniWeekTheme.themeData,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
