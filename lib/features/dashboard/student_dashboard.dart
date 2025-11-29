import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uni_week/core/theme.dart';
import 'package:uni_week/features/dashboard/student_view.dart';
import 'package:uni_week/features/settings/settings_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentView(), // Home (All Events)
    const StudentView(filterStatus: 'accepted'), // Registered
    const StudentView(filterStatus: 'pending'), // Requested
    const SettingsScreen(), // Settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).cardColor,
        indicatorColor: UniWeekTheme.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(icon: Icon(LucideIcons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(LucideIcons.calendarCheck),
            label: 'Registered',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.clock),
            label: 'Requested',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
