import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uni_week/core/theme.dart';

class StudentCalendarSheet extends StatefulWidget {
  final List<Map<String, dynamic>> events;

  const StudentCalendarSheet({super.key, required this.events});

  @override
  State<StudentCalendarSheet> createState() => _StudentCalendarSheetState();
}

class _StudentCalendarSheetState extends State<StudentCalendarSheet> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  late ValueNotifier<List<Map<String, dynamic>>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return widget.events.where((event) {
      final eventDate = DateTime.parse(event['date']);
      return isSameDay(eventDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: UniWeekTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2025, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: _onDaySelected,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: UniWeekTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  defaultTextStyle: TextStyle(color: Colors.white),
                  weekendTextStyle: TextStyle(color: Colors.white70),
                  outsideTextStyle: TextStyle(color: Colors.white24),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
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
              const Divider(color: Colors.white24),
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _selectedEvents,
                  builder: (context, value, _) {
                    if (value.isEmpty) {
                      return const Center(
                        child: Text(
                          'No events on this day',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: value.length,
                      itemBuilder: (context, index) {
                        final event = value[index];
                        final date = DateTime.parse(event['date']);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.white10,
                          child: ListTile(
                            title: Text(
                              event['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat('h:mm a').format(date),
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              event['venue'],
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
