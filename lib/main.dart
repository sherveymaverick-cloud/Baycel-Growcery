import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';
import 'widgets/shared_widgets.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/terms_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupBackgroundMessaging();
  await NotificationService().initialize();
  runApp(const MyApp());
}

/// Fade-through page transition (300ms easeInOut) — respects Reduce Motion.
class BaycelPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  BaycelPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final reduced = MediaQuery.of(context).disableAnimations;
            if (reduced) return child;
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Baycel Growcery',
      theme: buildBaycelTheme(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _checkConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hasAgreedToTerms') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkConsent(),
      builder: (context, consentSnapshot) {
        if (consentSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: SkeletonDashboard()));
        }

        final hasConsented = consentSnapshot.data ?? false;

        return StreamBuilder<User?>(
          stream: AuthService().userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: SkeletonDashboard()));
            }

            final isLoggedIn = snapshot.hasData;

            if (isLoggedIn) {
              return const HomeScreen();
            }

            if (!hasConsented) {
              return TermsOverlay(child: const LoginScreen());
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
