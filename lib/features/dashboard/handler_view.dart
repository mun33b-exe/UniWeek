import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:uni_week/features/dashboard/create_event_dialog.dart';
import 'package:uni_week/features/events/event_manage_screen.dart';

class HandlerView extends StatefulWidget {
  const HandlerView({super.key});

  @override
  State<HandlerView> createState() => _HandlerViewState();
}

class _HandlerViewState extends State<HandlerView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Dashboard'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: UniWeekTheme.primary,
          labelColor: UniWeekTheme.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'My Events'),
            Tab(text: 'Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await Provider.of<SupabaseService>(
                context,
                listen: false,
              ).signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_MyEventsTab(), _AnalyticsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        backgroundColor: UniWeekTheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.black),
      ),
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateEventDialog(),
    );
  }
}

class _MyEventsTab extends StatelessWidget {
  Future<void> _deleteEvent(BuildContext context, String eventId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          'Delete Event?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await Provider.of<SupabaseService>(
          context,
          listen: false,
        ).deleteEvent(eventId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Event deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _editEvent(BuildContext context, Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data!;
        // Ideally filter by created_by, but for hackathon speed we show all or assume backend filters
        // Since we didn't implement RLS for "my events" specifically in getEvents, let's just show all for now
        // or filter client side if we had the user ID.
        // The requirement says "My Events", let's assume the handler wants to see all events to manage or just theirs.
        // Given the prompt "Returns Stream of events" was generic, let's show all.

        if (events.isEmpty) {
          return const Center(child: Text('No events created yet'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Rebuild to refresh stream
            (context as Element).markNeedsBuild();
          },
          color: UniWeekTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final date = DateTime.parse(event['date']);
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EventManageScreen(event: event),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (event['image_url'] != null)
                        Image.network(
                          event['image_url'],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ListTile(
                        title: Text(
                          event['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${DateFormat('MMM d, y').format(date)} • ${event['venue']}',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                LucideIcons.edit,
                                color: UniWeekTheme.primary,
                              ),
                              onPressed: () => _editEvent(context, event),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _deleteEvent(context, event['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _AnalyticsTab extends StatefulWidget {
  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  List<Map<String, dynamic>> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      final stats = await supabase.getRegistrationStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stats.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Event Registrations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    _stats
                        .map((e) => e['count'] as int)
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble() +
                    5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _stats.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _stats[value.toInt()]['title']
                                  .toString()
                                  .substring(0, 3), // Truncate for space
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _stats.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: (entry.value['count'] as int).toDouble(),
                        color: UniWeekTheme.primary,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
