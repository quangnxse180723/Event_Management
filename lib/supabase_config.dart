import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://qegseyeqojeeuvkdtzxx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlZ3NleWVxb2plZXV2a2R0enh4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkzNjY4OTAsImV4cCI6MjA5NDk0Mjg5MH0.3AUDhkm9ayuOj1FujviUgL6GkhOLa65-tRHEtljdYUU',
  );
}