import 'package:biblio/Homescreen/homepage.dart';
import 'package:biblio/onboarding/onboarding_screen.dart';
import 'package:biblio/onboarding/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/providers/auth_provider.dart';
import 'package:biblio/core/providers/achievement_provider.dart';

import 'package:biblio/core/services/auth_services.dart';
import 'package:biblio/core/services/sembast_service.dart';
import 'package:biblio/core/services/achievement_service.dart';
import 'package:biblio/core/services/user_profile_migration.dart';
import 'package:biblio/core/services/xp_service.dart';
import 'package:biblio/features/gamification/widgets/achievement_unlock_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Supabase
  await SupabaseService.initialize();

  // Get the app's document directory
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = '${dir.path}/sembast.db';

  // Initialize Sembast
  final sembastService = SembastService();
  await sembastService.init(dbPath);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Remove the native splash screen once initialization is done
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  final _achievementService = AchievementService();
  final _profileMigration = UserProfileMigration();
  String? _lastInitializedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForNewAchievements();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  /// Called whenever the auth user changes (login/logout/app start).
  /// Ensures profile + achievements exist for the current user.
  Future<void> _initializeGamificationForUser(String userId) async {
    // Don't re-init if we already did it for this user in this session
    if (_lastInitializedUserId == userId) return;
    _lastInitializedUserId = userId;

    debugPrint('🎮 Initializing gamification for user: $userId');

    // Step 1: Ensure user_profiles row exists (creates if missing)
    await _profileMigration.ensureUserProfileExists();

    // Step 2: Sync achievement rows (creates missing ones if new achievements were added)
    await _achievementService.initializeUserAchievements();

    // Step 3: Check retroactive achievements against existing data
    await _achievementService.checkAllAchievementsRetroactively();
  }

  void _listenForNewAchievements() {
    ref.listenManual(newAchievementsProvider, (previous, next) {
      next.whenData((newAchievements) {
        if (newAchievements.isEmpty) return;

        for (final userAchievement in newAchievements) {
          final achievement = userAchievement.achievement;
          if (achievement == null) continue;

          Future.delayed(Duration.zero, () {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => AchievementUnlockDialog(
                      achievement: achievement,
                      onDismiss: () async {
                        await _achievementService.markConfettiShown(
                          userAchievement.id,
                        );
                        ref.invalidate(newAchievementsProvider);
                      },
                    ),
              );
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder:
          (context, child) => MaterialApp(
            title: 'Biblio',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD97A73),
              ),
              useMaterial3: true,
            ),
            home: authState.when(
              data: (user) {
                if (user != null) {
                  Future.microtask(
                    () => _initializeGamificationForUser(user.id),
                  );
                  return const _UsernameGate();
                }
                _lastInitializedUserId = null;
                return const OnboardingScreen();
              },
              loading:
                  () => const Scaffold(
                    backgroundColor: Color(0xFFF5F3EF),
                    body: Center(child: CircularProgressIndicator()),
                  ),
              error: (err, stack) => const OnboardingScreen(),
            ),
          ),
    );
  }
}

/// Checks if the logged-in user has a username.
/// If yes → Homepage. If no → ProfileSetupScreen (onboarding).
class _UsernameGate extends StatefulWidget {
  const _UsernameGate();

  @override
  State<_UsernameGate> createState() => _UsernameGateState();
}

class _UsernameGateState extends State<_UsernameGate> {
  final _xpService = XpService();
  late Future<bool> _hasUsernameFuture;

  @override
  void initState() {
    super.initState();
    _hasUsernameFuture = _checkUsername();
  }

  Future<bool> _checkUsername() async {
    final profile = await _xpService.getUserProfile();
    return profile?.username != null && profile!.username!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasUsernameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F3EF),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasUsername = snapshot.data ?? false;

        if (hasUsername) {
          return const Homepage();
        } else {
          return const ProfileSetupScreen();
        }
      },
    );
  }
}
