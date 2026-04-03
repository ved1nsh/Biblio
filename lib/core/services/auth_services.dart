import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:biblio/core/models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    // Web Client ID (for Supabase)
    serverClientId:
        '102076294576-58nfd6rfer990163dafkg132v3591aqn.apps.googleusercontent.com',
    // Android Client ID (for getting ID token) - ADD THIS LINE
    clientId:
        '102076294576-pnpggokfs5hmn0i7cunce1ig8o4ik56l.apps.googleusercontent.com', // Replace with your Android Client ID
  );

  // Get current user
  AppUser? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return AppUser.fromJson(user.toJson());
  }

  // Check if user is signed in
  bool get isSignedIn => _supabase.auth.currentUser != null;

  // Listen to auth state changes
  Stream<AppUser?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return AppUser.fromJson(user.toJson());
    });
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null;
      }

      // 2. Get Google Auth tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google tokens');
      }

      // 3. Sign in to Supabase

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw Exception('Failed to sign in with Supabase');
      }

      return AppUser.fromJson(response.user!.toJson());
    } catch (e) {
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Delete account (optional - for future use)
  Future<void> deleteAccount() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();

      // Note: Supabase doesn't have a direct delete user method from client
      // You'll need to implement this via Edge Functions or Admin API
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }
}

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://cmzyuepprdprxqytzxdi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtenl1ZXBwcmRwcnhxeXR6eGRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzMjEyNjksImV4cCI6MjA4MTg5NzI2OX0.L57dE9u_gR1U2ZDLYHyauTx6rCY90RNlUYX-ZShFo0M', // Replace with your actual anon key
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
