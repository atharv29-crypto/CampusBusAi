import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/student/student_dashboard.dart';
import 'screens/parent/parent_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const CampusBusApp());
}

class CampusBusApp extends StatelessWidget {
  const CampusBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusBusAI 360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7900),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _loadRole(User user) async {
    // Refresh token so newly assigned custom claims can take effect.
    await user.getIdToken(true);

    return AuthService().getUserRole(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        final user = authSnapshot.data;

        // Not logged in: show the common login page.
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<String?>(
          future: _loadRole(user),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            if (roleSnapshot.hasError) {
              return ErrorScreen(
                message: 'Unable to load your account role. Please try again.',
                onLogout: () async {
                  await AuthService().logout();
                },
              );
            }

            final role = roleSnapshot.data?.trim().toLowerCase();

            switch (role) {
              case 'student':
                return const StudentDashboard();

              case 'parent':
                return const ParentDashboard();

              case 'driver':
                return const DriverDashboard();

              case 'admin':
                return const AdminDashboard();

              default:
                return ErrorScreen(
                  message:
                      'No valid role was found for this account. '
                      'Please contact the administrator.',
                  onLogout: () async {
                    await AuthService().logout();
                  },
                );
            }
          },
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFFF7900))),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message, required this.onLogout});

  final String message;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 60,
                color: Color(0xFFFF7900),
              ),
              const SizedBox(height: 16),
              const Text(
                'CampusBusAI 360',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await onLogout();
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
