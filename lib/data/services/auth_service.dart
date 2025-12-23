import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception("Signup failed");
    }
  }

  Future<void> signIn(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception("Login failed");
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}
