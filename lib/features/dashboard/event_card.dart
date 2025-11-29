import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/services/notification_service.dart';
import 'package:uni_week/core/theme.dart';

class EventCard extends StatefulWidget {
  final Map<String, dynamic> event;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManage;

  const EventCard({
    super.key,
    required this.event,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
    this.onManage,
  });

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  String? _status; // null, pending, accepted, rejected
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isOwner) {
      _checkRegistration();
    }
  }

  Future<void> _checkRegistration() async {
    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final status = await supabase.getRegistrationStatus(widget.event['id']);
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRegistration() async {
    if (_status == 'accepted' || _status == 'pending') return;

    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    final notificationService = NotificationService();

    try {
      await supabase.registerForEvent(widget.event['id']);

      // Schedule local reminder for 30 minutes before event
      DateTime eventDate;
      try {
        eventDate = DateTime.parse(widget.event['date']);
      } catch (e) {
        eventDate = DateTime.now();
      }

      await notificationService.scheduleEventReminder(
        widget.event['title'],
        eventDate,
        widget.event['id'],
      );

      // Notify event creator (handler)
      final creatorId = widget.event['created_by'];
      if (creatorId != null) {
        await supabase.createNotification(
          userId: creatorId,
          title: '🎯 New Registration Request',
          body: 'A student wants to join "${widget.event['title']}"',
        );
      }

      if (mounted) {
        setState(() {
          _status = 'pending';
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

  Future<void> _withdrawRegistration() async {
    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      await supabase.withdrawRegistration(widget.event['id']);
      if (mounted) {
        setState(() {
          _status = null;
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

  Future<void> _confirmWithdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          'Withdraw Registration?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to withdraw from this event?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _withdrawRegistration();
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime date;
    try {
      date = DateTime.parse(widget.event['date']);
    } catch (e) {
      date = DateTime.now();
    }
    final formattedDate = DateFormat('MMM d, y • h:mm a').format(date);
    final society = widget.event['society_type'] ?? 'General';

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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.event['image_url'] != null)
            Image.network(
              widget.event['image_url'],
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      LucideIcons.image,
                      size: 48,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
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
                        color: badgeColor.withOpacity(0.2),
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
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.event['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.event['venue'],
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // BOTTOM ACTION AREA
                if (widget.isOwner)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        icon: LucideIcons.users,
                        label: 'Manage',
                        color: Colors.blue,
                        onTap: widget.onManage,
                      ),
                      _buildActionButton(
                        context,
                        icon: LucideIcons.edit3,
                        label: 'Edit',
                        color: Colors.amber,
                        onTap: widget.onEdit,
                      ),
                      _buildActionButton(
                        context,
                        icon: LucideIcons.trash2,
                        label: 'Delete',
                        color: Colors.red,
                        onTap: widget.onDelete,
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _status == null
                          ? _toggleRegistration
                          : _status == 'rejected'
                          ? _toggleRegistration // Retry
                          : _status == 'pending'
                          ? _withdrawRegistration // Cancel Request
                          : _confirmWithdraw, // Withdraw Accepted
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _status == 'accepted'
                            ? Colors.transparent
                            : _status == 'rejected'
                            ? Colors.red
                            : _status == 'pending'
                            ? Colors.transparent
                            : UniWeekTheme.primary,
                        side: _status == 'accepted' || _status == 'pending'
                            ? const BorderSide(color: Colors.red)
                            : null,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_status == 'pending' ||
                                    _status == 'accepted')
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(
                                      LucideIcons.trash2,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                  ),
                                Text(
                                  _status == 'accepted'
                                      ? 'Withdraw / Cancel'
                                      : _status == 'pending'
                                      ? 'Withdraw Request'
                                      : _status == 'rejected'
                                      ? 'Rejected (Tap to Retry)'
                                      : 'Register',
                                  style: TextStyle(
                                    color:
                                        _status == 'accepted' ||
                                            _status == 'pending'
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
