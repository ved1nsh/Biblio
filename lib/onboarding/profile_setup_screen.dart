import 'package:flutter/material.dart';
import 'username_setup_screen.dart';

/// Profile setup entry point — routes to the username screen
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately navigate to username setup
    return const UsernameSetupScreen();
  }
}
