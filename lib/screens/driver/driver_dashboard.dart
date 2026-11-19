import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'driver_attendance_page.dart';

const driverOrange = Color(0xFFFF7900);
const driverDark = Color(0xFF172033);
const driverMuted = Color(0xFF788195);
const driverBg = Color(0xFFF5F7FB);

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});
  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final _db = FirebaseFirestore.instance;
  String selectedTab = 'Dashboard';
  bool _busy = false;
  String issueType = 'General Inspection';
  final issueController = TextEditingController();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  String get _dateKey {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    issueController.dispose();
    super.dispose();
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _startTrip(String busId, Map<String, dynamic> bus) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final ref = _db.collection('trips').doc('${busId}_$_dateKey');
      await _db.runTransaction((tx) async {
        final old = await tx.get(ref);
        if (old.exists && old.data()?['status'] == 'completed') {
          throw Exception("Today's trip has already been completed.");
        }
        if (old.exists && old.data()?['status'] == 'inProgress') {
          throw Exception(" The trip is already in progress.");
        }
        tx.set(ref, {
          'busId': busId,
          'busNumber': bus['busNumber'] ?? '',
          'driverId': _uid,
          'dateKey': _dateKey,
          'status': 'inProgress',
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      _message('Trip started successfully.');
    } catch (e) {
      _message('Trip start failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeTrip(String busId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Trip?'),
        content: const Text(
          'All students who are currently on the bus will be marked as dropped at the final stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    if (confirm != true || _busy) return;
    setState(() => _busy = true);
    try {
      final tripId = '${busId}_$_dateKey';
      final tripRef = _db.collection('trips').doc(tripId);
      final trip = await tripRef.get();
      if (!trip.exists || trip.data()?['status'] != 'inProgress') {
        throw Exception("No active trip was found.");
      }
      final records = await _db
          .collection('attendance')
          .where('tripId', isEqualTo: tripId)
          .where('driverId', isEqualTo: _uid)
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'boarded')
          .get();
      // Firestore batches support at most 500 writes.
      for (var start = 0; start < records.docs.length; start += 450) {
        final batch = _db.batch();
        for (final doc in records.docs.skip(start).take(450)) {
          batch.update(doc.reference, {
            'status': 'dropped',
            'dropStop': 'College – Final Stop',
            'droppedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'dropMarkedByTripCompletion': true,
          });
        }
        await batch.commit();
      }
      await tripRef.update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message(
        'Trip completed. ${records.docs.length} students marked as dropped.',
      );
    } catch (e) {
      _message('Trip completion failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitMaintenance(String busId, String busNumber) async {
    final description = issueController.text.trim();
    if (description.isEmpty) {
      _message('Please describe the issue.');
      return;
    }
    setState(() => _busy = true);
    try {
      await _db.collection('maintenance_reports').add({
        'driverId': _uid,
        'busId': busId,
        'busNumber': busNumber,
        'issueType': issueType,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      issueController.clear();
      _message('Maintenance issue submitted to the Admin.');
    } catch (e) {
      _message('Issue submit failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendSOS(String busId, String busNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'Send an SOS alert only if there is a real emergency. Do you want to alert the Admin and Transport Office?',
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
    if (confirm != true) return;
    try {
      await _db.collection('emergency_alerts').add({
        'driverId': _uid,
        'busId': busId,
        'busNumber': busNumber,
        'message': 'Driver emergency SOS',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      _message(
        'SOS alert saved. The Admin Dashboard must be set up to receive this alert.',
      );
    } catch (e) {
      _message('SOS failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to access Driver Dashboard.')),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, profileSnap) {
        if (profileSnap.hasError)
          return _errorScaffold('Profile load error: ${profileSnap.error}');
        if (!profileSnap.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        final profile = profileSnap.data!.data();
        if (profile == null ||
            profile['role'] != 'driver' ||
            profile['isActive'] != true) {
          return _errorScaffold(
            'Driver profile not found or account is inactive. Please contact the Admin.',
          );
        }
        final name = (profile['name'] ?? 'Driver').toString();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('buses')
              .where('driverId', isEqualTo: _uid)
              .snapshots(),
          builder: (context, busSnap) {
            if (busSnap.hasError)
              return _errorScaffold('Bus load error: ${busSnap.error}');
            if (!busSnap.hasData)
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            if (busSnap.data!.docs.isEmpty) {
              return _shell(name, _noBusPage(name));
            }
            final busDoc = busSnap.data!.docs.first;
            final bus = busDoc.data();
            final busId = busDoc.id;
            final busNumber = (bus['busNumber'] ?? busId).toString();
            final routeName =
                (bus['routeName'] ??
                        profile['routeName'] ??
                        'Route not assigned')
                    .toString();
            return _shell(
              name,
              selectedTab == 'Attendance'
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: DriverAttendancePage(),
                    )
                  : selectedTab == 'Bus Maintenance'
                  ? _maintenance(busId, busNumber)
                  : _dashboard(name, busId, busNumber, routeName, bus),
            );
          },
        );
      },
    );
  }

  Widget _errorScaffold(String message) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );

  Widget _shell(String name, Widget content) => Scaffold(
    backgroundColor: driverBg,
    body: Column(
      children: [
        _topBar(name),
        Expanded(
          child: Row(
            children: [
              if (MediaQuery.sizeOf(context).width >= 1000) _sidebar(),
              Expanded(child: content),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to log out of your Driver account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _message('Logout failed: $e');
    }
  }

  Widget _topBar(String name) => Container(
    height: 72,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        const Icon(Icons.directions_bus, color: driverOrange, size: 32),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusBusAI 360',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: driverDark,
                ),
              ),
              Text(
                'Track • Predict • Protect',
                style: TextStyle(fontSize: 11, color: driverMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Attendance',
          onPressed: () => setState(() => selectedTab = 'Attendance'),
          icon: const Icon(Icons.fact_check_outlined),
        ),
        IconButton(
          tooltip: 'Maintenance',
          onPressed: () => setState(() => selectedTab = 'Bus Maintenance'),
          icon: const Icon(Icons.build_circle_outlined, color: driverOrange),
        ),
        const CircleAvatar(
          backgroundColor: Color(0xFFFFE8D6),
          child: Icon(Icons.person, color: driverOrange),
        ),
        const SizedBox(width: 8),
        if (MediaQuery.sizeOf(context).width > 500)
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Logout',
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        ),
      ],
    ),
  );

  Widget _sidebar() {
    final items = <Map<String, dynamic>>[
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.alt_route_rounded, 'label': "Today's Trip"},
      {'icon': Icons.groups_rounded, 'label': 'Students'},
      {'icon': Icons.fact_check_outlined, 'label': 'Attendance'},
      {'icon': Icons.notifications_none_rounded, 'label': 'Notifications'},
      {'icon': Icons.warning_amber_rounded, 'label': 'Emergency SOS'},
      {'icon': Icons.build_circle_outlined, 'label': 'Bus Maintenance'},
      {'icon': Icons.person_outline_rounded, 'label': 'My Profile'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: selectedTab == item['label']
                          ? driverOrange
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          item['icon'] as IconData,
                          color: selectedTab == item['label']
                              ? Colors.white
                              : driverDark,
                        ),
                        title: Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedTab == item['label']
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selectedTab == item['label']
                                ? Colors.white
                                : driverDark,
                          ),
                        ),
                        onTap: () => setState(
                          () => selectedTab = item['label'] as String,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          const Icon(Icons.support_agent, color: driverOrange, size: 36),
          const Text(
            'Need Help?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Contact Transport Office',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: driverMuted),
          ),
        ],
      ),
    );
  }

  Widget _noBusPage(String driverName) {
    final Widget page;
    switch (selectedTab) {
      case 'Attendance':
        page = const DriverAttendancePage();
        break;
      case 'Bus Maintenance':
        page = _noBusNotice(
          'Bus Maintenance',
          Icons.build_circle_outlined,
          'You can report vehicle issues after a bus is assigned to you. Your bus assignment is still pending with the Admin.',
        );
        break;
      case 'Emergency SOS':
        page = _noBusNotice(
          'Emergency SOS',
          Icons.sos,
          'A bus must be assigned to your account before you can send an SOS alert. If there is an emergency, contact the Transport Office directly.',
        );
        break;
      case 'Students':
        page = _noBusNotice(
          'Students',
          Icons.groups_outlined,
          'Students assigned to your bus will appear here once a bus is assigned to you.',
        );
        break;
      case "Today's Trip":
        page = _noBusNotice(
          "Today's Trip",
          Icons.alt_route,
          'No bus has been assigned to your account yet. Your trip details will appear here after the Admin assigns a bus.',
        );
        break;
      case 'Notifications':
        page = _noBusNotice(
          'Notifications',
          Icons.notifications_none,
          'There are no new driver notifications.',
        );
        break;
      case 'My Profile':
        page = _noBusNotice(
          'My Profile',
          Icons.person_outline,
          'Driver: $driverName\nBus Assignment: Pending',
        );
        break;
      case 'Settings':
        page = _noBusNotice(
          'Settings',
          Icons.settings_outlined,
          'Your Driver account settings will appear here.',
        );
        break;
      default:
        page = _noBusNotice(
          'Welcome, $driverName',
          Icons.dashboard_rounded,
          'No bus has been assigned to your account. Please contact the Admin. Your trip, student list, and live attendance details will appear here after a bus is assigned.',
        );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 500),
        child: Align(alignment: Alignment.topLeft, child: page),
      ),
    );
  }

  Widget _noBusNotice(String title, IconData icon, String message) => _panel(
    title,
    icon,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Chip(
          avatar: Icon(Icons.info_outline, size: 17),
          label: Text('Bus assignment pending'),
        ),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: driverDark, height: 1.5)),
      ],
    ),
  );

  Widget _dashboard(
    String name,
    String busId,
    String busNumber,
    String routeName,
    Map<String, dynamic> bus,
  ) {
    final tripId = '${busId}_$_dateKey';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('trips').doc(tripId).snapshots(),
      builder: (context, tripSnap) {
        final trip = tripSnap.data?.data();
        final started = trip?['status'] == 'inProgress';
        final completed = trip?['status'] == 'completed';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $name! 👋',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: driverDark,
                        ),
                      ),
                      const Text(
                        "Here is today's assigned bus and trip information.",
                        style: TextStyle(color: driverMuted),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      completed
                          ? 'Trip Completed'
                          : started
                          ? 'Trip In Progress'
                          : 'Trip Not Started',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _attendanceSummary(busId, busNumber, routeName, tripId),
              const SizedBox(height: 18),
              _panel(
                'Current Trip',
                Icons.route,
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _info('Bus Number', busNumber)),
                        const SizedBox(width: 10),
                        Expanded(child: _info('Assigned Route', routeName)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy || started || completed
                                ? null
                                : () => _startTrip(busId, bus),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Trip'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy || !started
                                ? null
                                : () => _completeTrip(busId),
                            icon: const Icon(Icons.flag),
                            label: const Text('Complete Trip'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      completed
                          ? "Today's trip is complete."
                          : started
                          ? 'The trip is in progress. Record student boarding in the Attendance tab.'
                          : 'Select Start Trip before recording attendance.',
                      style: const TextStyle(color: driverMuted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => selectedTab = 'Attendance'),
                            icon: const Icon(Icons.fact_check),
                            label: const Text('Open Attendance'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _sendSOS(busId, busNumber),
                            icon: const Icon(Icons.sos, color: Colors.red),
                            label: const Text('Emergency SOS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _studentList(busId),
              const SizedBox(height: 16),
              _panel('Assigned Route', Icons.alt_route, _routeStops(bus)),
              const SizedBox(height: 16),
              const Text(
                'CampusBusAI 360 • Driver Module • Firebase-connected core features',
                style: TextStyle(color: driverMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attendanceSummary(
    String busId,
    String busNumber,
    String routeName,
    String tripId,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('busId', isEqualTo: busId)
        .snapshots(),
    builder: (context, studentSnap) {
      final total = studentSnap.data?.docs.length ?? 0;
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('attendance')
            .where('tripId', isEqualTo: tripId)
            .where('driverId', isEqualTo: _uid)
            .where('busId', isEqualTo: busId)
            .snapshots(),
        builder: (context, attendanceSnap) {
          final records = attendanceSnap.data?.docs ?? [];
          final boarded = records
              .where((d) => d.data()['status'] == 'boarded')
              .length;
          final dropped = records
              .where((d) => d.data()['status'] == 'dropped')
              .length;
          final notBoarded = (total - boarded - dropped).clamp(0, total);
          return LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 850
                  ? 4
                  : c.maxWidth > 500
                  ? 2
                  : 1;
              final values = [
                ['Expected Students', '$total', Icons.groups, Colors.blue],
                [
                  'Currently On Bus',
                  '$boarded',
                  Icons.directions_bus,
                  Colors.green,
                ],
                ['Dropped', '$dropped', Icons.check_circle, Colors.teal],
                [
                  'Yet to Board',
                  '$notBoarded',
                  Icons.access_time,
                  driverOrange,
                ],
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final v in values)
                    SizedBox(
                      width: (c.maxWidth - (cols - 1) * 10) / cols,
                      child: _stat(
                        v[0] as String,
                        v[1] as String,
                        v[2] as IconData,
                        v[3] as Color,
                      ),
                    ),
                ],
              );
            },
          );
        },
      );
    },
  );

  Widget _studentList(String busId) => _panel(
    'Students Assigned to This Bus',
    Icons.groups,
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('busId', isEqualTo: busId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Text('Student load error: ${snap.error}');
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        if (snap.data!.docs.isEmpty)
          return const Text('No students have been assigned to this bus.');
        return Column(
          children: [
            for (final doc in snap.data!.docs)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text((doc.data()['name'] ?? 'Student').toString()),
                subtitle: Text(
                  '${doc.data()['studentId'] ?? doc.id} • ${doc.data()['pickupStop'] ?? doc.data()['stop'] ?? 'Stop not set'}',
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _routeStops(Map<String, dynamic> bus) {
    final raw = bus['routeStops'];
    if (raw is List && raw.isNotEmpty) {
      return Column(
        children: [
          for (final stop in raw)
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.location_on_outlined,
                color: driverOrange,
              ),
              title: Text(
                stop is Map
                    ? (stop['name'] ?? 'Stop').toString()
                    : stop.toString(),
              ),
            ),
        ],
      );
    }
    return Text(
      (bus['routeName'] ?? 'Route stops have not been configured by Admin.')
          .toString(),
    );
  }

  Widget _maintenance(String busId, String busNumber) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => selectedTab = 'Dashboard'),
              icon: const Icon(Icons.arrow_back),
            ),
            const Expanded(
              child: Text(
                'Bus Maintenance',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: driverDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _panel(
          'Report Vehicle Issue',
          Icons.report_problem_outlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: issueType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    const [
                          'General Inspection',
                          'Engine',
                          'Brakes',
                          'Tyres',
                          'Battery / Electrical',
                          'Other',
                        ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => issueType = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: issueController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _submitMaintenance(busId, busNumber),
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Issue'),
                  style: FilledButton.styleFrom(backgroundColor: driverOrange),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _panel(
          'My Maintenance Reports',
          Icons.history,
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('maintenance_reports')
                .where('driverId', isEqualTo: _uid)
                .orderBy('createdAt', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError)
                return Text('Reports load error: ${snap.error}');
              if (!snap.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty)
                return const Text(
                  'You have not submitted any maintenance reports yet.',
                );
              return Column(
                children: [
                  for (final d in snap.data!.docs)
                    ListTile(
                      leading: const Icon(
                        Icons.build_circle_outlined,
                        color: driverOrange,
                      ),
                      title: Text(
                        (d.data()['issueType'] ?? 'Issue').toString(),
                      ),
                      subtitle: Text(
                        (d.data()['description'] ?? '').toString(),
                      ),
                      trailing: Chip(
                        label: Text(
                          (d.data()['status'] ?? 'pending').toString(),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _panel(String title, IconData icon, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFE8ECF2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: driverOrange),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: driverDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _stat(String title, String value, IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8ECF2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: .12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: driverMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _info(String title, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: driverBg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, color: driverMuted)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
