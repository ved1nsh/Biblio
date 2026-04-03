import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:biblio/core/services/streak_saver_service.dart';
import 'package:biblio/core/providers/xp_provider.dart';

class StreakSaverScreen extends ConsumerStatefulWidget {
  const StreakSaverScreen({super.key});

  @override
  ConsumerState<StreakSaverScreen> createState() => _StreakSaverScreenState();
}

class _StreakSaverScreenState extends ConsumerState<StreakSaverScreen> {
  static const _bg = Color(0xFFFCF9F5);
  static const _textDark = Color(0xFF2D2D2D);
  static const _textGrey = Color(0xFF8A8A8A);
  static const _warmOrange = Color(0xFFD97757);

  final _saverService = StreakSaverService();
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final brokenAsync = ref.watch(brokenStreakProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final xpAsync = ref.watch(totalXpProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);
    final appBarTopPad = (15 * scale).clamp(12.0, 15.0);
    final backIconSize = (20 * scale).clamp(17.0, 20.0);
    final titleSize = (32 * scale).clamp(26.0, 32.0);
    final outerPadH = (20 * scale).clamp(16.0, 20.0);
    final sectionGap = (20 * scale).clamp(16.0, 20.0);
    final bottomGap = (40 * scale).clamp(32.0, 40.0);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + appBarTopPad),
        child: Padding(
          padding: EdgeInsets.only(top: appBarTopPad),
          child: AppBar(
            backgroundColor: _bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textDark,
                size: backIconSize,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Streak Saver',
              style: TextStyle(
                color: _textDark,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(brokenStreakProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(totalXpProvider);
        },
        color: _warmOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: outerPadH, vertical: 10),
          child: Column(
            children: [
              // Hero card
              _buildHeroCard(profileAsync, xpAsync, scale),
              SizedBox(height: sectionGap),

              // Broken / safe section
              brokenAsync.when(
                data: (info) {
                  if (info != null && info['is_broken'] == true) {
                    return _buildBrokenCard(info, profileAsync, xpAsync, scale);
                  }
                  return _buildSafeCard(scale);
                },
                loading: () => _buildLoadingCard(scale),
                error: (_, __) => _buildSafeCard(scale),
              ),
              SizedBox(height: sectionGap),

              // Info section
              _buildInfoSection(scale),
              SizedBox(height: bottomGap),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Hero card ──────────────────────────────────────────────────────────

  Widget _buildHeroCard(
    AsyncValue<dynamic> profileAsync,
    AsyncValue<int> xpAsync,
    double scale,
  ) {
    final savers =
        profileAsync.whenData((p) => p?.streakSaversAvailable ?? 0).value ?? 0;
    final xp = xpAsync.value ?? 0;
    final cardPad = (24 * scale).clamp(18.0, 24.0);
    final shieldSize = (72 * scale).clamp(60.0, 72.0);
    final shieldIconSize = (40 * scale).clamp(32.0, 40.0);
    final headerSize = (22 * scale).clamp(18.0, 22.0);
    final subSize = (13 * scale).clamp(11.0, 13.0);
    final dividerHeight = (48 * scale).clamp(40.0, 48.0);
    final sectionGap24 = (24 * scale).clamp(18.0, 24.0);
    final sectionGap16 = (16 * scale).clamp(12.0, 16.0);

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Shield icon with glow
          Container(
            width: shieldSize,
            height: shieldSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: shieldIconSize,
            ),
          ),
          SizedBox(height: sectionGap16),
          Text(
            'Streak Protection',
            style: TextStyle(
              fontSize: headerSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep your reading streak alive',
            style: TextStyle(
              fontSize: subSize,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'SF-UI-Display',
            ),
          ),
          SizedBox(height: sectionGap24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Free Savers',
                  value: '$savers',
                  scale: scale,
                ),
              ),
              Container(
                width: 1,
                height: dividerHeight,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _heroStat(
                  icon: Icons.bolt_rounded,
                  label: 'XP Available',
                  value: '$xp',
                  scale: scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required IconData icon,
    required String label,
    required String value,
    required double scale,
  }) {
    final iconSize = (22 * scale).clamp(18.0, 22.0);
    final valueSize = (24 * scale).clamp(20.0, 24.0);
    final labelSize = (11 * scale).clamp(9.0, 11.0);

    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: iconSize),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'SF-UI-Display',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.7),
            fontFamily: 'SF-UI-Display',
          ),
        ),
      ],
    );
  }

  // ─── Broken streak card ─────────────────────────────────────────────────

  Widget _buildBrokenCard(
    Map<String, dynamic> info,
    AsyncValue<dynamic> profileAsync,
    AsyncValue<int> xpAsync,
    double scale,
  ) {
    final streakLost = info['streak_lost'] as int? ?? 0;
    final missedDays = info['missed_days'] as int? ?? 0;
    final canRestore = info['can_restore'] as bool? ?? false;
    final savers =
        profileAsync.whenData((p) => p?.streakSaversAvailable ?? 0).value ?? 0;
    final xp = xpAsync.value ?? 0;
    final hasFree = savers > 0;
    final hasXp = xp >= 100;
    final cardPad = (24 * scale).clamp(18.0, 24.0);
    final fireBadgeSize = (64 * scale).clamp(54.0, 64.0);
    final fireEmojiSize = (28 * scale).clamp(22.0, 28.0);
    final titleSize = (22 * scale).clamp(18.0, 22.0);
    final bodySize = (15 * scale).clamp(13.0, 15.0);
    final subSize = (13 * scale).clamp(11.0, 13.0);
    final infoIconSize = (20 * scale).clamp(16.0, 20.0);
    final infoTextSize = (13 * scale).clamp(11.0, 13.0);

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE53935).withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fire icon
          Container(
            width: fireBadgeSize,
            height: fireBadgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text('🔥💔', style: TextStyle(fontSize: fireEmojiSize)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Streak Broken!',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE53935),
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your $streakLost-day reading streak ended',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              fontWeight: FontWeight.w500,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You missed $missedDays day${missedDays > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: subSize,
              color: _textGrey,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 24),

          if (canRestore) ...[
            // Option 1: Free Saver
            if (hasFree)
              _buildRestoreButton(
                icon: Icons.card_giftcard_rounded,
                title: 'Use Free Streak Saver',
                subtitle: '$savers available',
                gradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                scale: scale,
                onTap:
                    _isRestoring
                        ? null
                        : () => _handleRestore(useFreeStreak: true),
              ),
            if (hasFree) const SizedBox(height: 12),

            // Option 2: Use XP
            _buildRestoreButton(
              icon: Icons.bolt_rounded,
              title: 'Restore with 100 XP',
              subtitle:
                  hasXp ? 'You have $xp XP' : 'Need 100 XP (you have $xp)',
              gradient:
                  hasXp
                      ? const [Color(0xFF5B8DEF), Color(0xFF7C5CBF)]
                      : const [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
              scale: scale,
              onTap:
                  (_isRestoring || !hasXp)
                      ? null
                      : () => _handleRestore(useFreeStreak: false),
            ),
            const SizedBox(height: 16),

            // Start Fresh
            GestureDetector(
              onTap:
                  _isRestoring
                      ? null
                      : () {
                        ref.read(brokenStreakDismissedProvider.notifier).state =
                            true;
                        Navigator.pop(context);
                      },
              child: const Text(
                'Start Fresh',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textGrey,
                  fontFamily: 'SF-UI-Display',
                  decoration: TextDecoration.underline,
                  decorationColor: _textGrey,
                ),
              ),
            ),
          ] else ...[
            // Too many days missed
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFE65100),
                    size: infoIconSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Streak savers work within 3 missed days. '
                      'Start fresh and build a new streak!',
                      style: TextStyle(
                        fontSize: infoTextSize,
                        color: const Color(0xFFE65100),
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isRestoring) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRestoreButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required double scale,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    final buttonPadH = (20 * scale).clamp(16.0, 20.0);
    final iconSize = (28 * scale).clamp(22.0, 28.0);
    final titleSize = (15 * scale).clamp(13.0, 15.0);
    final subtitleSize = (12 * scale).clamp(10.0, 12.0);
    final chevronSize = (16 * scale).clamp(13.0, 16.0);

    return GestureDetector(
      onTap: () {
        if (isEnabled) {
          HapticFeedback.lightImpact();
          onTap();
        }
      },
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: buttonPadH, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (isEnabled)
                BoxShadow(
                  color: gradient[0].withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: iconSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontFamily: 'SF-UI-Display',
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: chevronSize,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Safe card ──────────────────────────────────────────────────────────

  Widget _buildSafeCard(double scale) {
    final cardPad = (32 * scale).clamp(24.0, 32.0);
    final badgeSize = (64 * scale).clamp(54.0, 64.0);
    final badgeIconSize = (36 * scale).clamp(30.0, 36.0);
    final titleSize = (20 * scale).clamp(16.0, 20.0);
    final bodySize = (14 * scale).clamp(12.0, 14.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF4CAF50),
              size: badgeIconSize,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your streak is safe!',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep reading every day to maintain\nyour streak and earn XP',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              color: _textGrey,
              fontFamily: 'SF-UI-Display',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading card ───────────────────────────────────────────────────────

  Widget _buildLoadingCard(double scale) {
    final cardPad = (40 * scale).clamp(30.0, 40.0);
    final spinnerSize = (28 * scale).clamp(22.0, 28.0);
    final textSize = (14 * scale).clamp(12.0, 14.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 14),
            Text(
              'Checking streak status...',
              style: TextStyle(
                fontSize: textSize,
                color: _textGrey,
                fontFamily: 'SF-UI-Display',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Info section ───────────────────────────────────────────────────────

  Widget _buildInfoSection(double scale) {
    final cardPad = (24 * scale).clamp(18.0, 24.0);
    final headerSize = (18 * scale).clamp(15.0, 18.0);
    final titleGap = (20 * scale).clamp(16.0, 20.0);

    return Container(
      padding: EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Streak Savers Work',
            style: TextStyle(
              fontSize: headerSize,
              fontWeight: FontWeight.w700,
              color: _textDark,
              fontFamily: 'SF-UI-Display',
            ),
          ),
          SizedBox(height: titleGap),
          _infoRow(
            icon: Icons.card_giftcard_rounded,
            color: const Color(0xFF4CAF50),
            title: 'Free Streak Savers',
            subtitle:
                'You start with 1 free saver. Use it to restore a broken streak at no XP cost.',
            scale: scale,
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.bolt_rounded,
            color: const Color(0xFF5B8DEF),
            title: 'XP Restoration',
            subtitle:
                'Spend 100 XP to restore your streak if you run out of free savers.',
            scale: scale,
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.timer_rounded,
            color: _warmOrange,
            title: '3-Day Window',
            subtitle:
                'Streak savers only work within 3 missed days. After that, you start fresh.',
            scale: scale,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required double scale,
  }) {
    final iconBoxSize = (40 * scale).clamp(34.0, 40.0);
    final iconSize = (22 * scale).clamp(18.0, 22.0);
    final titleSize = (14 * scale).clamp(12.0, 14.0);
    final subtitleSize = (12 * scale).clamp(10.0, 12.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                  fontFamily: 'SF-UI-Display',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleSize,
                  color: _textGrey,
                  fontFamily: 'SF-UI-Display',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Restore handler ───────────────────────────────────────────────────

  Future<void> _handleRestore({required bool useFreeStreak}) async {
    setState(() => _isRestoring = true);

    final success = await _saverService.restoreStreak(useFreeStreak);

    if (!mounted) return;

    setState(() => _isRestoring = false);

    if (success) {
      HapticFeedback.mediumImpact();

      // Refresh all related providers
      ref.invalidate(brokenStreakProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(totalXpProvider);
      ref.invalidate(streakSaversProvider);
      ref.read(brokenStreakDismissedProvider.notifier).state = false;

      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Streak restored! 🔥',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            duration: const Duration(seconds: 3),
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Failed to restore streak',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            duration: const Duration(seconds: 3),
          ),
        );
    }
  }
}
