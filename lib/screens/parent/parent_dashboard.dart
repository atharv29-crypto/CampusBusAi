import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  static const orange = Color(0xFFFF7900);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      _tripPage(),
      _notificationsPage(),
      _profilePage(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.directions_bus_rounded, color: orange, size: 28),
            SizedBox(width: 9),
            Text(
              'CampusBusAI 360',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 2),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _showLogoutConfirmation(context),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: pages[_selectedIndex],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Trip',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _overview() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Parent Dashboard',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Your child’s journey, at a glance.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 20),
      _childCard(),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.directions_bus,
              'Bus Status',
              'On route',
              const Color(0xFFE8F4FF),
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              Icons.access_time,
              'Estimated Arrival',
              '12 min',
              const Color(0xFFFFF1E5),
              orange,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _sectionTitle('Live Journey', trailing: 'DEMO DATA'),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE6D1),
                  child: Icon(Icons.location_on, color: orange),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus MH-11 AB 1234',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Lonand → Yashoda Technical Campus',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F7E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RUNNING',
                    style: TextStyle(
                      color: Color(0xFF218344),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: .62,
                minHeight: 8,
                color: orange,
                backgroundColor: Color(0xFFFFE6D1),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lonand',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '62% journey',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
                Text(
                  'College',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => setState(() => _selectedIndex = 1),
              icon: const Icon(Icons.map_outlined),
              label: const Text('View trip details'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _sectionTitle('Today’s Updates'),
      const SizedBox(height: 10),
      _infoTile(
        Icons.check_circle_outline,
        'Boarding recorded',
        'Today, 7:32 AM',
        Colors.green,
      ),
      _infoTile(
        Icons.directions_bus_outlined,
        'Bus departed from stop',
        'Today, 7:35 AM',
        orange,
      ),
      const SizedBox(height: 12),
      const Text(
        'Note: This is a UI prototype. Bus location and ETA are sample values.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );

  Widget _childCard() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF7900), Color(0xFFFF9D45)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: orange.withValues(alpha: .18),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 29,
          backgroundColor: Colors.white,
          child: Icon(Icons.school_rounded, color: orange, size: 30),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Linked Student',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                'Student name will appear here',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Route: Lonand to Campus',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        Icon(Icons.verified_user_outlined, color: Colors.white, size: 25),
      ],
    ),
  );

  Widget _tripPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Trip Tracking',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Demo route status and stops',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      Container(
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded, size: 54, color: orange),
              SizedBox(height: 8),
              Text(
                'Live map will be connected here',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Map currently uses demo UI',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      _sectionTitle('Route Stops'),
      const SizedBox(height: 8),
      _stopTile('Lonand', 'Completed · 7:05 AM', true),
      _stopTile('Wathar', 'Completed · 7:24 AM', true),
      _stopTile('Revadi Phata', 'Next stop · ETA 8 min', false),
      _stopTile('Yashoda Technical Campus', 'Destination', false),
    ],
  );

  Widget _notificationsPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Alerts & Notifications',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      _infoTile(
        Icons.notifications_active_outlined,
        'Journey started',
        'Demo alert · 7:05 AM',
        orange,
      ),
      _infoTile(
        Icons.person_pin_circle_outlined,
        'Student boarding marked',
        'Demo alert · 7:32 AM',
        Colors.green,
      ),
      _infoTile(
        Icons.access_time,
        'Arrival estimate updated',
        'Demo alert · 7:40 AM',
        Colors.blue,
      ),
      const SizedBox(height: 12),
      const Text(
        'Notifications are sample UI and are not sent by Firebase yet.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );

  Widget _profilePage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Parent Profile',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      const CircleAvatar(
        radius: 42,
        backgroundColor: Color(0xFFFFE6D1),
        child: Icon(Icons.person, color: orange, size: 44),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Parent name',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      const Center(
        child: Text(
          'parent@example.com',
          style: TextStyle(color: Colors.black54),
        ),
      ),
      const SizedBox(height: 22),
      ListTile(
        leading: const Icon(Icons.link),
        title: const Text('Linked student'),
        subtitle: const Text('Student linking will be configured later'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
      const SizedBox(height: 10),
      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Logout'),
        onTap: () => _showLogoutConfirmation(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
    ],
  );

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate should listen to authStateChanges() and show LoginScreen.
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Widget _sectionTitle(String title, {String? trailing}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: const TextStyle(
            color: orange,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
    ],
  );

  Widget _statCard(
    IconData icon,
    String title,
    String value,
    Color bg,
    Color fg,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: bg,
          child: Icon(icon, color: fg),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    ),
  );

  Widget _infoTile(IconData icon, String title, String subtitle, Color color) =>
      Container(
        margin: const EdgeInsets.only(bottom: 9),
        decoration: _cardDecoration(),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
        ),
      );

  Widget _stopTile(String title, String subtitle, bool done) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: _cardDecoration(),
    child: ListTile(
      leading: Icon(
        done ? Icons.check_circle : Icons.location_on_outlined,
        color: done ? Colors.green : orange,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
    ],
  );
}
