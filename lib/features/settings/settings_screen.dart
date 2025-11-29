import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme_provider.dart';
import 'package:uni_week/core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final profile = await supabase.getUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildProfileCard(context),
                const SizedBox(height: 24),
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final isDark =
                          themeProvider.themeMode == ThemeMode.dark ||
                          (themeProvider.themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);

                      return SwitchListTile(
                        title: Text(
                          'Dark Mode',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        secondary: Icon(
                          LucideIcons.moon,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        value: isDark,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: ListTile(
                    leading: const Icon(LucideIcons.logOut, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () async {
                      await Provider.of<SupabaseService>(
                        context,
                        listen: false,
                      ).signOut();
                      // Navigation is handled by AuthWrapper in main.dart
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final email = _profile?['email'] ?? 'No Email';
    final role = _profile?['role'] ?? 'Student';
    final society = _profile?['society'];

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: UniWeekTheme.primary.withOpacity(0.1),
              child: Text(
                email[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: UniWeekTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              email,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(
                  label: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: UniWeekTheme.primary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
                if (society != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      society,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
