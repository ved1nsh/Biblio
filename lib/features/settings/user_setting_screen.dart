import 'package:biblio/core/services/auth_services.dart';
import 'package:biblio/features/settings/change_username_screen.dart';
import 'package:biblio/features/settings/settings_faq_screen.dart';
import 'package:biblio/features/gamification/screens/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UserSettingsScreen extends ConsumerWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = (screenWidth / 393).clamp(0.85, 1.0);

    final user = Supabase.instance.client.auth.currentUser;
    final metadata = user?.userMetadata;
    final fullName = _resolveFullName(metadata, user?.email);
    final userPhotoUrl = _resolvePhotoUrl(metadata);

    final avatarRadius = (74 * scale).clamp(64.0, 74.0);
    final nameFontSize = (30 * scale).clamp(24.0, 30.0);
    final usernameFontSize = (14 * scale).clamp(12.0, 16.0);
    final linkFontSize = (12 * scale).clamp(10.0, 13.0);
    final buttonFontSize = (16 * scale).clamp(14.0, 18.0);
    final horizontalPadding = (24 * scale).clamp(16.0, 24.0);
    final sectionGap = (32 * scale).clamp(24.0, 32.0);
    final topGap = (12 * scale).clamp(10.0, 12.0);
    final nameGap = (18 * scale).clamp(14.0, 18.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: (20 * scale).roundToDouble(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: topGap),
                        _buildAvatar(
                          fullName,
                          userPhotoUrl,
                          avatarRadius,
                          scale,
                        ),
                        SizedBox(height: nameGap),
                        Text(
                          fullName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF-UI-Display',
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: (4 * scale).roundToDouble()),
                        FutureBuilder<String>(
                          future: _loadUsername(user?.id, user?.email),
                          builder: (context, snapshot) {
                            final username = snapshot.data ?? '@reader';
                            return Text(
                              username,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SF-UI-Display',
                                fontSize: usernameFontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                        SizedBox(height: sectionGap),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: const Color(0xFFEFEFEF),
                            child: Column(
                              children: [
                                _buildListTile(
                                  title: 'Notifications',
                                  icon: Icons.notifications_none_rounded,
                                  scale: scale,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(),
                                _buildListTile(
                                  title: 'Change username',
                                  icon: Icons.person_outline_rounded,
                                  scale: scale,
                                  onTap: () async {
                                    await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const ChangeUsernameScreen(),
                                      ),
                                    );
                                    if (context.mounted) {
                                      (context as Element).markNeedsBuild();
                                    }
                                  },
                                ),
                                _buildDivider(),
                                _buildListTile(
                                  title: 'FAQs',
                                  icon: Icons.help_outline_rounded,
                                  scale: scale,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => const SettingsFaqScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(),
                                _buildListTile(
                                  title: 'Terms of service',
                                  icon: Icons.description_outlined,
                                  scale: scale,
                                  onTap: () {
                                    _launchUrl(
                                      'https://v1-biblio.vercel.app/terms-and-conditions',
                                    );
                                  },
                                ),
                                _buildDivider(),
                                _buildListTile(
                                  title: 'Privacy policy',
                                  icon: Icons.privacy_tip_outlined,
                                  scale: scale,
                                  onTap: () {
                                    _launchUrl(
                                      'https://v1-biblio.vercel.app/privacy-policy',
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Visit ',
                              style: TextStyle(
                                fontFamily: 'SF-UI-Display',
                                fontSize: linkFontSize,
                                color: Colors.black87,
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  () => _launchUrl(
                                    'https://v1-biblio.vercel.app/',
                                  ),
                              child: Text(
                                'biblio.com',
                                style: TextStyle(
                                  fontFamily: 'SF-UI-Display',
                                  fontSize: linkFontSize,
                                  color: const Color(0xFF4A9FFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              ' for more features',
                              style: TextStyle(
                                fontFamily: 'SF-UI-Display',
                                fontSize: linkFontSize,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: (16 * scale).roundToDouble()),
                        SizedBox(
                          width: double.infinity,
                          height: (56 * scale).clamp(48.0, 56.0),
                          child: ElevatedButton(
                            onPressed: () => _handleLogout(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFEFEF),
                              foregroundColor: const Color(0xFFE55B5B),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  size: (20 * scale).roundToDouble(),
                                ),
                                SizedBox(width: (8 * scale).roundToDouble()),
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontFamily: 'SF-UI-Display',
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData icon,
    required double scale,
    required VoidCallback onTap,
  }) {
    final tilePadH = (20 * scale).clamp(16.0, 20.0);
    final tilePadV = (18 * scale).clamp(14.0, 18.0);
    final iconSize = (20 * scale).clamp(16.0, 20.0);
    final tileGap = (16 * scale).clamp(12.0, 16.0);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tilePadH, vertical: tilePadV),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: iconSize),
            SizedBox(width: tileGap),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'SF-UI-Display',
                  fontSize: (15 * scale).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.black54,
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: Colors.grey.shade300);
  }

  Widget _buildAvatar(
    String name,
    String? userPhotoUrl,
    double avatarRadius,
    double scale,
  ) {
    final avatarSize = avatarRadius * 2;
    final avatarFontSize = (40 * scale).clamp(32.0, 48.0);

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E0D4),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD5CBB8), width: 2),
        image:
            userPhotoUrl != null
                ? DecorationImage(
                  image: NetworkImage(userPhotoUrl),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      child:
          userPhotoUrl == null
              ? Center(
                child: Text(
                  _getInitial(name),
                  style: TextStyle(
                    fontSize: avatarFontSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A4A4A),
                  ),
                ),
              )
              : null,
    );
  }

  String _resolveFullName(Map<String, dynamic>? metadata, String? email) {
    final raw = metadata?['full_name']?.toString().trim();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Reader';
  }

  String? _resolvePhotoUrl(Map<String, dynamic>? metadata) {
    final avatar = metadata?['avatar_url']?.toString().trim();
    if (avatar != null && avatar.isNotEmpty) {
      return avatar;
    }

    final picture = metadata?['picture']?.toString().trim();
    if (picture != null && picture.isNotEmpty) {
      return picture;
    }

    return null;
  }

  String _getInitial(String name) {
    if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  Future<String> _loadUsername(String? userId, String? email) async {
    final fallback =
        email != null && email.isNotEmpty
            ? '@${email.split('@').first}'
            : '@reader';

    if (userId == null) return fallback;

    try {
      final response =
          await Supabase.instance.client
              .from('user_profiles')
              .select('username')
              .eq('user_id', userId)
              .maybeSingle();

      final username = response?['username']?.toString().trim();
      if (username == null || username.isEmpty) {
        return fallback;
      }
      return username.startsWith('@') ? username : '@$username';
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Logout',
              style: TextStyle(
                fontFamily: 'SF-UI-Display',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to logout?',
              style: TextStyle(fontFamily: 'SF-UI-Display'),
            ),
            backgroundColor: const Color(0xFFFCF9F5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black54,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE55B5B),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SF-UI-Display',
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      final authService = AuthService();
      await authService.signOut();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}
