import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';

class EventManageScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventManageScreen({super.key, required this.event});

  @override
  State<EventManageScreen> createState() => _EventManageScreenState();
}

class _EventManageScreenState extends State<EventManageScreen> {
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
  }

  Future<void> _fetchRegistrations() async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      final regs = await supabase.getEventRegistrations(widget.event['id']);
      if (mounted) {
        setState(() {
          _registrations = regs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching requests: $e')));
      }
    }
  }

  Future<void> _updateStatus(String regId, String status) async {
    final supabase = Provider.of<SupabaseService>(context, listen: false);
    try {
      await supabase.updateRegistrationStatus(regId, status);
      await _fetchRegistrations(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Request $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Event'),
        backgroundColor: UniWeekTheme.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _registrations.isEmpty
                ? const Center(child: Text('No registration requests yet'))
                : RefreshIndicator(
                    onRefresh: _fetchRegistrations,
                    color: UniWeekTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _registrations.length,
                      itemBuilder: (context, index) {
                        final reg = _registrations[index];
                        return _buildRequestCard(reg);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: UniWeekTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event['title'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.users, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${_registrations.length} Requests',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> reg) {
    final status = reg['status'] ?? 'pending';
    final studentEmail = reg['profiles']?['email'] ?? 'Unknown';

    Color statusColor;
    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(studentEmail, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          'Status: ${status.toUpperCase()}',
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
        ),
        trailing: status == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.checkCircle,
                      color: Colors.green,
                    ),
                    onPressed: () => _updateStatus(reg['id'], 'accepted'),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.xCircle, color: Colors.red),
                    onPressed: () => _updateStatus(reg['id'], 'rejected'),
                  ),
                ],
              )
            : Icon(
                status == 'accepted' ? LucideIcons.check : LucideIcons.x,
                color: statusColor,
              ),
      ),
    );
  }
}
