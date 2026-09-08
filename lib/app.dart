import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/candidature/nouvelle_candidature_screen.dart';
import 'screens/suivi/suivi_screen.dart';
import 'widgets/sidebar.dart';

class JalonApp extends StatelessWidget {
  const JalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jalon',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const AppShell();
        }
        return const AuthFlow();
      },
    );
  }
}

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool showSignup = false;

  @override
  Widget build(BuildContext context) {
    return showSignup
        ? SignupScreen(onSwitchToLogin: () => setState(() => showSignup = false))
        : LoginScreen(onSwitchToSignup: () => setState(() => showSignup = true));
  }
}

enum AppPage { profil, candidature, suivi }

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppPage page = AppPage.profil;

  Widget _buildCurrentScreen() {
    switch (page) {
      case AppPage.profil:
        return const ProfilScreen();
      case AppPage.candidature:
        return const NouvelleCandidatureScreen();
      case AppPage.suivi:
        return const SuiviScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            currentPage: page,
            onSelect: (p) => setState(() => page = p),
            onLogout: () => AuthService().signOut(),
          ),
          Expanded(
            child: Container(
              color: AppColors.bg,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildCurrentScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
