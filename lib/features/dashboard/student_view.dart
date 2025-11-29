import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';
import 'package:uni_week/features/dashboard/event_card.dart';

class StudentView extends StatefulWidget {
  final String? filterStatus; // 'accepted', 'pending', or null for all

  const StudentView({super.key, this.filterStatus});

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'ACM', 'CLS', 'CSS'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniWeek Events'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildEventList()),
        ],
      ),
      floatingActionButton: null,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Find events (e.g. Coding)...',
          prefixIcon: Icon(
            LucideIcons.search,
            color: Theme.of(context).hintColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
              selectedColor: chipColor.withOpacity(0.8),
              backgroundColor: Theme.of(context).cardColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
    Stream<List<Map<String, dynamic>>> stream;

    if (widget.filterStatus != null) {
      stream = Stream.fromFuture(
        supabase.getStudentRegistrationsByStatus(widget.filterStatus!),
      );
    } else {
      stream = supabase.getEvents();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var events = snapshot.data!;

        // Filter by Society
        var filteredEvents = _selectedFilter == 'All'
            ? events
            : events
                  .where((e) => e['society_type'] == _selectedFilter)
                  .toList();

        // Filter by Search Query
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredEvents = filteredEvents.where((e) {
            final title = (e['title'] ?? '').toString().toLowerCase();
            final description = (e['description'] ?? '')
                .toString()
                .toLowerCase();
            final venue = (e['venue'] ?? '').toString().toLowerCase();
            return title.contains(query) ||
                description.contains(query) ||
                venue.contains(query);
          }).toList();
        }

        if (filteredEvents.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: UniWeekTheme.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: filteredEvents.length,
            itemBuilder: (context, index) {
              final event = filteredEvents[index];
              return EventCard(event: event, isOwner: false);
            },
          ),
        );
      },
    );
  }
}
