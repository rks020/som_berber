import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yilmaz_hair_barber/models/customer.dart';

void main() {
  test('fetch customers', () async {
    final supabase = SupabaseClient(
      'https://eqkkkxjjyixtrwoutmkq.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVxa2treGpqeWl4dHJ3b3V0bWtxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMxNDkxMzgsImV4cCI6MjA5ODcyNTEzOH0.7QIx4jJkcrCIfMKHkL4wd4K5xoU4avIujqWabRyt7EQ',
    );

    try {
      final cRes = await supabase.from('customers').select();
      print("cRes: $cRes");
      for (var e in cRes) {
        try {
          print("Parsing customer ID: ${e['id']}");
          final id = e['id'] as String;
          final name = e['name'] as String;
          final phone = e['phone'] as String;
          final notes = (e['notes'] ?? '') as String;
          print("created_at: ${e['created_at']}");
          final createdAt = DateTime.parse(e['created_at'] as String);
          final profilePicturePath = e['profile_picture_path'] as String?;
          print("Successfully parsed customer $name");
        } catch (inner) {
          print("Error parsing customer: $inner");
        }
      }
    } catch (e) {
      print("Error fetching customers: $e");
    }
  });
}
