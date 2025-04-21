import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  final SupabaseClient primaryClient;
  final SupabaseClient secondaryClient;

  SupabaseConfig({
    required this.primaryClient,
    required this.secondaryClient,
  });
}