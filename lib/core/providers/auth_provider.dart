import 'package:biblio/core/services/auth_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/models/user_model.dart';
import 'package:flutter_riverpod/legacy.dart';

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current User Provider
final currentUserProvider = StateProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser;
});

// Auth State Stream Provider
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Is Signed In Provider
final isSignedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isSignedIn;
});
