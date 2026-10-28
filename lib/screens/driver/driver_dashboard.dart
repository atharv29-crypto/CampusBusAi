import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  static const Color orange = Color(0xFFFF7900);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _tripStarted = false;
  bool _busy = false;
  bool _sosActive = false;
  int _tab = 0;

  // Prototype passenger records. Replace with Firestore data when route/student
  // assignment is implemented.
  final List<_Passenger> _passengers = [
    _Passenger(name: 'Aarav Patil', stop: 'Lonand', boarded: true),
    _Passenger(name: 'Sana Shaikh', stop: 'Wathar', boarded: true),
    _Passenger(name: 'Rohan Jadhav', stop: 'Revadi Phata'),
    _Passenger(name: 'Anaya More', stop: 'Adaki Phata'),
    _Passenger(name: 'Vedant Pawar', stop: 'Salpe', boarded: true),
    _Passenger(name: 'Ira Deshmukh', stop: 'Deur'),
  ];

  User? get _user => _auth.currentUser;

  int get _boardedCount => _passengers.where((p) => p.boarded).length;
  int get _waitingCount => _passengers.where((p) => !p.boarded).length;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      _passengersPage(),
      _routePage(),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _tripStarted
                  ? const Color(0xFFE4F7E9)
                  : const Color(0xFFF0F1F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _tripStarted ? 'ON TRIP' : 'OFF DUTY',
                style: TextStyle(
                  color: _tripStarted ? Colors.green.shade800 : Colors.black54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: pages[_tab],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Passengers',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
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
        'Driver Dashboard',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Trip operations and passenger safety.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7900), Color(0xFFFF9D45)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.directions_bus_filled,
                  color: Colors.white,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Bus',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'MH-11 AB 1234',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white54),
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ROUTE',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lonand → Campus',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHIFT',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Morning',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _statCard(
              Icons.people_alt_outlined,
              'Expected',
              '${_passengers.length}',
              Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              Icons.how_to_reg_outlined,
              'Boarded',
              '$_boardedCount',
              Colors.green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard(
              Icons.hourglass_bottom,
              'Waiting',
              '$_waitingCount',
              orange,
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _tripStarted ? Colors.red : orange,
                ),
                onPressed: _busy ? null : _toggleTrip,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _tripStarted
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                label: Text(
                  _busy
                      ? 'Please wait...'
                      : _tripStarted
                      ? 'End Trip'
                      : 'Start Trip',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                onPressed: _busy ? null : _confirmSos,
                icon: const Icon(Icons.sos_rounded),
                label: Text(_sosActive ? 'SOS ACTIVE' : 'Emergency SOS'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trip and SOS actions are saved to Firestore. Confirm your security rules before using with real passengers.',
              style: TextStyle(color: Colors.black54, fontSize: 11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _sectionTitle('Boarding Summary'),
      const SizedBox(height: 8),
      _progressRow('Boarded', _boardedCount, _passengers.length, Colors.green),
      _progressRow(
        'Waiting at stops',
        _waitingCount,
        _passengers.length,
        orange,
      ),
      _progressRow('Exited', 0, _passengers.length, Colors.blue),
      const SizedBox(height: 10),
      const Text(
        'Passenger names and route details are currently sample data.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );

  Future<void> _toggleTrip() async {
    final user = _user;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    setState(() => _busy = true);
    final starting = !_tripStarted;
    try {
      final tripRef = _firestore.collection('trips').doc(user.uid);
      await tripRef.set({
        'driverUid': user.uid,
        'driverEmail': user.email,
        'busNumber': 'MH-11 AB 1234',
        'routeName': 'Lonand to Yashoda Technical Campus',
        'status': starting ? 'started' : 'ended',
        if (starting) 'startedAt': FieldValue.serverTimestamp(),
        if (!starting) 'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _tripStarted = starting);
      _showMessage(
        starting ? 'Trip started and saved.' : 'Trip ended and saved.',
      );
    } on FirebaseException catch (e) {
      _showMessage('Firestore error: ${e.message ?? e.code}');
    } catch (_) {
      _showMessage('Could not update trip. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSos() async {
    if (_sosActive) {
      setState(() => _sosActive = false);
      _showMessage(
        'SOS display cleared. The saved alert remains in Firestore.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will create an SOS alert record in Firestore. Continue only for a real or test alert as appropriate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    final user = _user;
    if (user == null) {
      _showMessage('Please login again.');
      return;
    }

    setState(() => _busy = true);
    try {
      await _firestore.collection('sos_alerts').add({
        'driverUid': user.uid,
        'driverEmail': user.email,
        'busNumber': 'MH-11 AB 1234',
        'routeName': 'Lonand to Yashoda Technical Campus',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() => _sosActive = true);
      _showMessage('SOS alert saved to Firestore.');
    } on FirebaseException catch (e) {
      _showMessage('SOS failed: ${e.message ?? e.code}');
    } catch (_) {
      _showMessage('Could not send SOS. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _passengersPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Passenger Management',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Review boarding status for today’s route.',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _miniCount('Expected', '${_passengers.length}', Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniCount('Boarded', '$_boardedCount', Colors.green),
          ),
          const SizedBox(width: 10),
          Expanded(child: _miniCount('Waiting', '$_waitingCount', orange)),
        ],
      ),
      const SizedBox(height: 16),
      ..._passengers.map(
        (p) => Container(
          margin: const EdgeInsets.only(bottom: 9),
          decoration: _cardDecoration(),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFFFE6D1),
              child: Text(
                p.name.split(' ').map((s) => s[0]).take(2).join(),
                style: const TextStyle(
                  color: orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Stop: ${p.stop}'),
            trailing: p.boarded
                ? const Chip(
                    label: Text('Boarded'),
                    avatar: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                : TextButton(
                    onPressed: _busy ? null : () => _markBoarded(p),
                    child: const Text('Mark boarded'),
                  ),
          ),
        ),
      ),
      const Text(
        'Boarding updates are local prototype state; connect a real student/route collection before production.',
        style: TextStyle(color: Colors.black54, fontSize: 12),
      ),
    ],
  );

  Future<void> _markBoarded(_Passenger passenger) async {
    setState(() {
      passenger.boarded = true;
    });
    _showMessage('${passenger.name} marked as boarded.');
  }

  Widget _routePage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Route & Stops',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      const Text(
        'Morning route: Lonand to Yashoda Technical Campus',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 16),
      Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded, size: 52, color: orange),
              SizedBox(height: 8),
              Text(
                'Route map placeholder',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Connect existing map widget here',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      _routeStop('Lonand', 'Start · 7:00 AM', true),
      _routeStop('Tambe', 'Scheduled · 7:12 AM', true),
      _routeStop('Koparde Phata', 'Scheduled · 7:18 AM', true),
      _routeStop('Wathar', 'Scheduled · 7:28 AM', false),
      _routeStop('Revadi Phata', 'Scheduled · 7:40 AM', false),
      _routeStop('Yashoda Technical Campus', 'Destination · 8:10 AM', false),
    ],
  );

  Widget _profilePage() {
    final user = _user;
    final displayName = user?.displayName?.trim();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Driver Profile',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFFFFE6D1),
          child: Icon(Icons.person, color: orange, size: 44),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            (displayName == null || displayName.isEmpty)
                ? 'Driver'
                : displayName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        Center(
          child: Text(
            user?.email ?? 'No email',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 22),
        const ListTile(
          leading: Icon(Icons.directions_bus),
          title: Text('Assigned bus'),
          subtitle: Text('MH-11 AB 1234 (demo assignment)'),
          tileColor: Colors.white,
        ),
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout'),
          subtitle: const Text('Sign out of this account'),
          onTap: _busy ? null : _logout,
          tileColor: Colors.white,
        ),
      ],
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // AuthGate listening to authStateChanges will display LoginScreen.
    } on FirebaseAuthException catch (e) {
      _showMessage('Logout failed: ${e.message ?? e.code}');
    } catch (_) {
      _showMessage('Logout failed. Please try again.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
  );

  Widget _statCard(IconData icon, String title, String value, Color color) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
      );

  Widget _miniCount(String title, String value, Color color) => Container(
    padding: const EdgeInsets.all(12),
    decoration: _cardDecoration(),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    ),
  );

  Widget _progressRow(String title, int count, int total, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title),
                Text(
                  '$count / $total',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 7,
                color: color,
                backgroundColor: const Color(0xFFE9EDF3),
              ),
            ),
          ],
        ),
      );

  Widget _routeStop(String title, String subtitle, bool passed) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: _cardDecoration(),
    child: ListTile(
      leading: Icon(
        passed ? Icons.check_circle : Icons.location_on_outlined,
        color: passed ? Colors.green : orange,
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

class _Passenger {
  _Passenger({required this.name, required this.stop, this.boarded = false});

  final String name;
  final String stop;
  bool boarded;
}
