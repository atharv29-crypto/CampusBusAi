import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../student/student_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../driver/driver_dashboard.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _MessageScreen(
        title: 'Session Not Found',
        message: 'Please login again.',
      );
    }

    return FutureBuilder<String?>(
      future: AuthService().getUserRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F8FC),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7900)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _MessageScreen(
            title: 'Profile Unavailable',
            message:
                'User profile मिळत नाही. Internet आणि Firestore setup तपासा.',
            onLogout: () => AuthService().logout(),
          );
        }

        final role = snapshot.data;

        if (role == null || role.isEmpty) {
          return _MessageScreen(
            title: 'Role Not Assigned',
            message:
                'या account ला role assign झालेला नाही. Admin शी संपर्क साध.',
            onLogout: () => AuthService().logout(),
          );
        }

        switch (role.toLowerCase()) {
          case 'student':
            return const StudentDashboard();

          case 'parent':
            return const ParentDashboard();

          case 'driver':
            return const DriverDashboard();

          case 'admin':
            return const AdminDashboard();

          default:
            return _MessageScreen(
              title: 'Invalid Role',
              message: 'या account चा role मान्य नाही. Admin शी संपर्क साध.',
              onLogout: () => AuthService().logout(),
            );
        }
      },
    );
  }
}

// --------------------------------------------------
// ADMIN DASHBOARD
// --------------------------------------------------

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color orange = Color(0xFFFF7900);

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().logout();
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout करता आला नाही. पुन्हा प्रयत्न करा.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  size: 76,
                  color: orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome, Admin!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? 'Admin account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 28),
                const _AdminFeatureCard(
                  icon: Icons.people_alt_outlined,
                  title: 'User Management',
                  subtitle: 'Manage students, parents and drivers.',
                ),
                const SizedBox(height: 12),
                const _AdminFeatureCard(
                  icon: Icons.directions_bus_outlined,
                  title: 'Bus Management',
                  subtitle: 'Bus assignments and vehicle details.',
                ),
                const SizedBox(height: 12),
                const _AdminFeatureCard(
                  icon: Icons.route_outlined,
                  title: 'Route Management',
                  subtitle: 'Manage bus routes and stops.',
                ),
                const SizedBox(height: 12),
                const _AdminFeatureCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Alerts & Reports',
                  subtitle: 'View trip alerts and safety reports.',
                ),
                const SizedBox(height: 24),
                const Text(
                  'Admin features are UI placeholders. Management actions '
                  'and data access must be connected and secured separately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFE6D1),
          child: Icon(icon, color: const Color(0xFFFF7900)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// --------------------------------------------------
// ERROR / MESSAGE SCREEN
// --------------------------------------------------

class _MessageScreen extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onLogout;

  const _MessageScreen({
    required this.title,
    required this.message,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFFF7900),
                  size: 64,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (onLogout != null) ...[
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7900),
                    ),
                    onPressed: () async {
                      try {
                        await onLogout!();
                      } catch (_) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Logout करता आला नाही. पुन्हा प्रयत्न करा.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
