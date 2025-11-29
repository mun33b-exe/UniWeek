import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  // Auth
  Future<void> signUpUser({
    required String email,
    required String password,
    required String role,
    String? society,
  }) async {
    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user != null) {
      await _client.from('profiles').insert({
        'id': res.user!.id,
        'email': email,
        'role': role,
        'society': society,
      });
    }
  }

  Future<void> signInUser({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  // Events
  Stream<List<Map<String, dynamic>>> getEvents() {
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .order('date', ascending: true);
  }

  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required String venue,
    required String societyType,
    String? imageUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('events').insert({
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'venue': venue,
      'society_type': societyType,
      'created_by': user.id,
      'image_url': imageUrl,
    });
  }

  Future<void> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? date,
    String? venue,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (date != null) updates['date'] = date.toIso8601String();
    if (venue != null) updates['venue'] = venue;
    if (imageUrl != null) updates['image_url'] = imageUrl;

    if (updates.isEmpty) return;

    await _client.from('events').update(updates).eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    await _client.from('events').delete().eq('id', eventId);
  }

  Future<String> uploadEventBanner(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'event_banners/$fileName';
    await _client.storage.from('event_banners').upload(path, imageFile);
    return _client.storage.from('event_banners').getPublicUrl(path);
  }

  // Registrations
  Future<void> registerForEvent(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Check if already registered (rejected?)
    final existing = await _client
        .from('registrations')
        .select()
        .eq('event_id', eventId)
        .eq('student_id', user.id)
        .maybeSingle();

    if (existing != null) {
      if (existing['status'] == 'rejected') {
        // Re-request
        await _client
            .from('registrations')
            .update({
              'status': 'pending',
              'registration_date': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
        return;
      }
      // Already registered or pending
      return;
    }

    await _client.from('registrations').insert({
      'event_id': eventId,
      'student_id': user.id,
      'status': 'pending',
    });
  }

  Future<bool> isRegistered(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final response = await _client
        .from('registrations')
        .select()
        .eq('event_id', eventId)
        .eq('student_id', user.id)
        .maybeSingle();

    return response != null && response['status'] == 'accepted';
  }

  Future<String?> getRegistrationStatus(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('registrations')
        .select('status')
        .eq('event_id', eventId)
        .eq('student_id', user.id)
        .maybeSingle();

    return response?['status'] as String?;
  }

  Future<List<Map<String, dynamic>>> getEventRegistrations(
    String eventId,
  ) async {
    final response = await _client
        .from('registrations')
        .select('*, profiles(email)')
        .eq('event_id', eventId);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getStudentRegistrations() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('registrations')
        .select('*, events(*)')
        .eq('student_id', user.id)
        .inFilter('status', ['accepted', 'pending']);

    // Extract events from the response
    return List<Map<String, dynamic>>.from(
      response
          .where((reg) => reg['events'] != null)
          .map((reg) => reg['events'] as Map<String, dynamic>),
    );
  }

  Future<List<Map<String, dynamic>>> getStudentRegistrationsByStatus(
    String status,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('registrations')
        .select('*, events(*)')
        .eq('student_id', user.id)
        .eq('status', status);

    // Extract events from the response
    return List<Map<String, dynamic>>.from(
      response.map((reg) => reg['events'] as Map<String, dynamic>),
    );
  }

  Future<void> updateRegistrationStatus(String regId, String status) async {
    await _client
        .from('registrations')
        .update({'status': status})
        .eq('id', regId);
  }

  Future<void> withdrawRegistration(String eventId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('registrations')
        .delete()
        .eq('event_id', eventId)
        .eq('student_id', user.id);
  }

  // Analytics
  Future<List<Map<String, dynamic>>> getRegistrationStats() async {
    // This is a simplified way to get stats.
    // Ideally we would use a view or a more complex query.
    // For hackathon, we'll fetch events and then count registrations for each.
    // Or better, fetch registrations and group by event_id locally or via RPC if available.
    // Let's try to fetch all registrations and process locally for simplicity and speed.

    final events = await _client.from('events').select('id, title');
    final registrations = await _client
        .from('registrations')
        .select('event_id');

    final stats = <String, int>{};
    for (var reg in registrations) {
      final eventId = reg['event_id'] as String;
      stats[eventId] = (stats[eventId] ?? 0) + 1;
    }

    return events.map((event) {
      return {'title': event['title'], 'count': stats[event['id']] ?? 0};
    }).toList();
  }
}
