import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';
import 'package:intl/intl.dart';

class StudentView extends StatefulWidget {
  const StudentView({super.key});

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'ACM', 'CLS', 'CSS'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniWeek Events'),
        backgroundColor: UniWeekTheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            onPressed: () async {
              await Provider.of<SupabaseService>(
                context,
                listen: false,
              ).signOut();
              // The auth state change should be handled in main.dart or by re-checking auth
              // For now, we can just pop or navigate to login if we had a root navigator
              // But since we are in Dashboard, let's just let the StreamBuilder in main handle it if we had one.
              // Or manually navigate.
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCalendar,
        label: const Text('My Calendar'),
        icon: const Icon(LucideIcons.calendar),
        backgroundColor: UniWeekTheme.primary,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          Color chipColor;
          switch (filter) {
            case 'ACM':
              chipColor = Colors.blue;
              break;
            case 'CLS':
              chipColor = Colors.pink;
              break;
            case 'CSS':
              chipColor = Colors.green;
              break;
            default:
              chipColor = Colors.grey;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter);
                }
              },
              selectedColor: chipColor.withValues(alpha: 0.8),
              backgroundColor: UniWeekTheme.surface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventList() {
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
        final filteredEvents = _selectedFilter == 'All'
            ? events
            : events
                  .where((e) => e['society_type'] == _selectedFilter)
                  .toList();

        if (filteredEvents.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredEvents.length,
          itemBuilder: (context, index) {
            final event = filteredEvents[index];
            return _EventCard(event: event);
          },
        );
      },
    );
  }

  void _showCalendar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UniWeekTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2025, 12, 31),
                    focusedDay: DateTime.now(),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: UniWeekTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(color: Colors.white),
                      weekendTextStyle: TextStyle(color: Colors.white70),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EventCard extends StatefulWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _isRegistered = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final isReg = await supabase.isRegistered(widget.event['id']);
    if (mounted) {
      setState(() {
        _isRegistered = isReg;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRegistration() async {
    if (_isRegistered) return; // Already registered

    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      await supabase.registerForEvent(widget.event['id']);
      if (mounted) {
        setState(() {
          _isRegistered = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.event['date']);
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(date);
    final society = widget.event['society_type'];

    Color badgeColor;
    switch (society) {
      case 'ACM':
        badgeColor = Colors.blue;
        break;
      case 'CLS':
        badgeColor = Colors.pink;
        break;
      case 'CSS':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.event['image_url'] != null)
            Image.network(
              widget.event['image_url'],
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        society,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.event['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      widget.event['venue'],
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _isRegistered
                        ? null
                        : _toggleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRegistered
                          ? Colors.green
                          : UniWeekTheme.primary,
                      disabledBackgroundColor: _isRegistered
                          ? Colors.green.withValues(alpha: 0.5)
                          : null,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isRegistered ? 'Registered' : 'Register'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
