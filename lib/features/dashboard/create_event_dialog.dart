import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:uni_week/core/services/supabase_service.dart';
import 'package:uni_week/core/theme.dart';

class CreateEventDialog extends StatefulWidget {
  final Map<String, dynamic>? event; // If provided, we are in Edit Mode

  const CreateEventDialog({super.key, this.event});

  @override
  State<CreateEventDialog> createState() => _CreateEventDialogState();
}

class _CreateEventDialogState extends State<CreateEventDialog> {
  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!['title'];
      _venueController.text = widget.event!['venue'];
      _descController.text = widget.event!['description'] ?? '';

      final dateTime = DateTime.parse(widget.event!['date']);
      _selectedDate = dateTime;
      _selectedTime = TimeOfDay.fromDateTime(dateTime);

      _existingImageUrl = widget.event!['image_url'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final supabase = Provider.of<SupabaseService>(context, listen: false);

    try {
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await supabase.uploadEventBanner(_selectedImage!);
      }

      final fullDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (widget.event != null) {
        // Update
        await supabase.updateEvent(
          eventId: widget.event!['id'],
          title: _titleController.text,
          description: _descController.text,
          date: fullDateTime,
          venue: _venueController.text,
          imageUrl: imageUrl,
        );
      } else {
        // Create
        final profile = await supabase.getUserProfile();
        final society = profile?['society'] ?? 'ACM';

        await supabase.createEvent(
          title: _titleController.text,
          description: _descController.text,
          date: fullDateTime,
          venue: _venueController.text,
          societyType: society,
          imageUrl: imageUrl,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.event != null ? 'Event updated' : 'Event created',
            ),
          ),
        );
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
    return AlertDialog(
      backgroundColor: UniWeekTheme.surface,
      title: Text(
        widget.event != null ? 'Edit Event' : 'Create New Event',
        style: const TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : (_existingImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_existingImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                child: _selectedImage == null && _existingImageUrl == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.image,
                            color: Colors.white54,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Pick Banner',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(labelText: 'Venue'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(LucideIcons.calendar),
                      ),
                      child: Text(
                        _selectedDate != null
                            ? DateFormat('MMM d, y').format(_selectedDate!)
                            : 'Select Date',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        prefixIcon: Icon(LucideIcons.clock),
                      ),
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.event != null ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
