import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

const _orange = Color(0xFFFF7900);
const _dark = Color(0xFF172033);
const _muted = Color(0xFF788195);
const _bg = Color(0xFFF5F7FB);
const _line = Color(0xFFE8ECF2);
const _blue = Color(0xFF087FC4);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selected = 'Overview';
  String _expanded =
      ''; // Main features stay collapsed; sub-feature cards appear in the content area.
  final TextEditingController _search = TextEditingController();
  bool _working = false;

  final List<_NavGroup> _groups = const [
    _NavGroup('Dashboard', Icons.dashboard_rounded, [
      'Overview',
      'System Status',
    ]),
    _NavGroup('User Management', Icons.people_alt_rounded, [
      'Students',
      'Drivers',
      'Driver Approvals',
      'Admin Accounts',
      'Parents',
    ]),
    _NavGroup('Fleet Management', Icons.directions_bus_rounded, [
      'All Buses',
      'Assign Driver',
      'Bus Status',
      'Bus Maintenance',
      'Maintenance History',
    ]),
    _NavGroup('Route Management', Icons.alt_route_rounded, [
      'All Routes',
      'Stops Management',
      'Bus Assignment',
      'Route Deviation',
    ]),
    _NavGroup('Live Tracking', Icons.map_rounded, [
      'Live Fleet Map',
      'Bus Location',
      'ETA & Delays',
    ]),
    _NavGroup('Attendance & Reports', Icons.fact_check_rounded, [
      'Student Attendance',
      'Driver Attendance',
      'Attendance History',
      'Reports & Export',
    ]),
    _NavGroup('Safety & Alerts', Icons.health_and_safety_rounded, [
      'Emergency SOS',
      'Delay Alerts',
      'Safety Monitoring',
      'Notification Center',
    ]),
    _NavGroup('Analytics', Icons.analytics_rounded, [
      'Trip Analytics',
      'Attendance Analytics',
      'Delay Analysis',
      'Fleet Reports',
    ]),
    _NavGroup('Feedback & Complaints', Icons.feedback_rounded, [
      'View Complaints',
      'Feedback Status',
    ]),
    _NavGroup('System Settings', Icons.settings_rounded, [
      'General Settings',
      'Notification Settings',
      'Audit Log',
    ]),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _go(String group, String page) => setState(() {
    _expanded = '';
    _selected = page;
  });

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _logout() async {
    await AuthService().logout();
  }

  Future<void> _reviewDriver(
    QueryDocumentSnapshot<Map<String, dynamic>> request,
    bool approve,
  ) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final data = request.data();
      final db = FirebaseFirestore.instance;
      final uid = data['uid'] as String;
      final batch = db.batch();
      final requestRef = db.collection('driver_requests').doc(request.id);
      if (approve) {
        batch.set(db.collection('users').doc(uid), {
          'uid': uid,
          'name': data['name'] ?? '',
          'email': data['email'] ?? '',
          'role': 'driver',
          'mobile': data['mobile'] ?? '',
          'employeeId': data['employeeId'] ?? '',
          'busNumber': data['busNumber'] ?? '',
          'createdAt': data['createdAt'] ?? FieldValue.serverTimestamp(),
          'approvedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
      }
      batch.update(requestRef, {
        'status': approve ? 'approved' : 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      await batch.commit();
      if (mounted) {
        _message(approve ? 'Driver approved.' : 'Driver request rejected.');
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _message(
          'Could not update request (${e.code}). Check Firestore rules.',
        );
      }
    } catch (e) {
      if (mounted) _message('Action failed: $e');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: _bg,
      drawer: wide ? null : Drawer(child: SafeArea(child: _sidebar())),
      body: Column(
        children: [
          _topBar(user?.email ?? 'Administrator', wide),
          Expanded(
            child: Row(
              children: [
                if (wide) _sidebar(),
                Expanded(child: _pageBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(String email, bool wide) => Container(
    height: 76,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _line)),
    ),
    child: Row(
      children: [
        if (!wide)
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu),
            ),
          ),
        const Icon(
          Icons.directions_bus_filled_rounded,
          color: _orange,
          size: 34,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CampusBusAI 360',
                style: TextStyle(
                  color: _dark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Admin Panel • Track • Predict • Protect',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ),
        if (wide)
          SizedBox(
            width: 270,
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search this page...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: _bg,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => _go('Safety & Alerts', 'Notification Center'),
          icon: const Icon(Icons.notifications_none_rounded, color: _dark),
        ),
        const CircleAvatar(
          backgroundColor: Color(0xFFFFE8D6),
          child: Icon(Icons.admin_panel_settings, color: _orange),
        ),
        if (wide) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrator',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _dark),
                ),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ],
    ),
  );

  Widget _sidebar() => Container(
    width: 250,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFE8D6),
                child: Icon(Icons.admin_panel_settings, color: _orange),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Workspace',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    Text(
                      'Transport operations',
                      style: TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(color: _line),
        Expanded(
          child: ListView(
            children: [
              for (final group in _groups) _navGroup(group),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: _line),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'CampusBusAI 360 • Admin',
            style: TextStyle(fontSize: 10, color: _muted),
          ),
        ),
      ],
    ),
  );

  Widget _navGroup(_NavGroup group) {
    final selectedInside =
        group.pages.contains(_selected) || _selected == group.title;
    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: selectedInside,
      selectedTileColor: const Color(0xFFFFF0E3),
      leading: Icon(
        group.icon,
        color: selectedInside ? _orange : _dark,
        size: 21,
      ),
      title: Text(
        group.title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: selectedInside ? FontWeight.w700 : FontWeight.w500,
          color: _dark,
        ),
      ),
      trailing: group.title == 'User Management'
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('driver_requests')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _muted,
                ),
              ],
            )
          : group.title == 'Dashboard'
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
      onTap: () => setState(() {
        _expanded = '';
        _selected = group.title == 'Dashboard' ? 'Overview' : group.title;
      }),
    );
  }

  Widget _pageBody() => SingleChildScrollView(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_groups.any((g) => g.pages.contains(_selected)) &&
                _selected != 'Overview') ...[
              IconButton(
                tooltip: 'Back to section cards',
                onPressed: () {
                  final parent = _groups.firstWhere(
                    (g) => g.pages.contains(_selected),
                  );
                  setState(() => _selected = parent.title);
                },
                icon: const Icon(Icons.arrow_back_rounded, color: _dark),
              ),
              const SizedBox(width: 2),
            ],
            Container(
              width: 5,
              height: 38,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_groups.any((g) => g.pages.contains(_selected)) &&
                      _selected != 'Overview')
                    Text(
                      '${_groups.firstWhere((g) => g.pages.contains(_selected)).title}  >  $_selected',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  Text(
                    _selected,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                  Text(
                    _subtitle(_selected),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_selected == 'All Routes')
              FilledButton.icon(
                onPressed: () => _editDialog('Add Route'),
                style: FilledButton.styleFrom(backgroundColor: _orange),
                icon: const Icon(Icons.add),
                label: const Text('Add Route'),
              ),
            if (_selected == 'All Buses')
              FilledButton.icon(
                onPressed: () => _editBus(),
                style: FilledButton.styleFrom(backgroundColor: _orange),
                icon: const Icon(Icons.add),
                label: const Text('Add Bus'),
              ),
            if (_selected == 'Reports & Export')
              OutlinedButton.icon(
                onPressed: () => _message(
                  'Connect report data/export service to enable downloads.',
                ),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
          ],
        ),
        const SizedBox(height: 22),
        if (_selected == 'Overview')
          _overview()
        else if (_groups.any(
          (group) => group.title == _selected && group.title != 'Dashboard',
        ))
          _moduleCards(_groups.firstWhere((group) => group.title == _selected))
        else if (_selected == 'Driver Approvals')
          _driverApprovals()
        else if (_selected == 'Bus Maintenance' ||
            _selected == 'Maintenance History')
          _maintenance()
        else if (_selected == 'All Routes' ||
            _selected == 'Stops Management' ||
            _selected == 'Bus Assignment' ||
            _selected == 'Route Deviation')
          _routesPage()
        else if (_selected == 'All Buses' ||
            _selected == 'Assign Driver' ||
            _selected == 'Bus Status')
          _busesPage()
        else if (_selected == 'Student Attendance' ||
            _selected == 'Driver Attendance' ||
            _selected == 'Attendance History' ||
            _selected == 'Reports & Export')
          _attendancePage()
        else if (_selected == 'Live Fleet Map' ||
            _selected == 'Bus Location' ||
            _selected == 'ETA & Delays')
          _trackingPage()
        else if (_selected == 'Emergency SOS' ||
            _selected == 'Delay Alerts' ||
            _selected == 'Safety Monitoring' ||
            _selected == 'Notification Center')
          _alertsPage()
        else if (_selected == 'Students' ||
            _selected == 'Parents' ||
            _selected == 'Drivers' ||
            _selected == 'Admin Accounts')
          _usersPage()
        else
          _genericPage(),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'CampusBusAI 360 • Demo UI — live data depends on Firebase/GPS integration',
            style: TextStyle(fontSize: 11, color: _muted),
          ),
        ),
      ],
    ),
  );

  Widget _moduleCards(_NavGroup group) {
    final descriptions = <String, String>{
      'Students': 'View student profiles and account status.',
      'Parents': 'Manage parent accounts and linked students.',
      'Drivers': 'View driver profiles and assigned buses.',
      'Admin Accounts': 'Review authorized administrator accounts.',
      'Driver Approvals': 'Approve or reject driver registration requests.',
      'All Buses': 'Browse buses, registration and assigned route.',
      'Assign Driver': 'Assign an approved driver to a bus.',
      'Bus Status': 'Review current bus availability and status.',
      'Bus Maintenance':
          'Service dates, vehicle issues and maintenance history.',
      'Maintenance History': 'Review previous and upcoming services.',
      'All Routes': 'Create, view and edit college bus routes.',
      'Stops Management': 'Add, remove and reorder route stops.',
      'Bus Assignment': 'Assign buses and drivers to routes.',
      'Route Deviation': 'Review reported deviations from planned routes.',
      'Live Fleet Map':
          'View bus locations on a map (demo until GPS connects).',
      'Bus Location': 'Inspect last known location for a bus.',
      'ETA & Delays': 'Review arrival estimates and delay records.',
      'Student Attendance': 'View student pickup, boarding and drop records.',
      'Driver Attendance': 'View duty start, duty end and attendance status.',
      'Attendance History': 'Search previous attendance records.',
      'Reports & Export': 'Prepare attendance and transport reports.',
      'Emergency SOS': 'Review emergency reports and response status.',
      'Delay Alerts': 'Review late bus and stop-delay alerts.',
      'Safety Monitoring': 'Review safety incidents and monitoring status.',
      'Notification Center': 'Review system and transport notifications.',
      'Trip Analytics': 'Review trip completion and performance.',
      'Attendance Analytics': 'Compare student and driver attendance.',
      'Delay Analysis': 'Analyze delays by bus, route and date.',
      'Fleet Reports': 'Review fleet usage and vehicle reports.',
      'View Complaints': 'Review complaints submitted by users.',
      'Feedback Status': 'Track feedback and resolution status.',
      'General Settings': 'Manage general application preferences.',
      'Notification Settings': 'Configure notification preferences.',
      'Audit Log': 'Review administrator actions and changes.',
      'System Status': 'Review connection and service status.',
    };
    final icons = <String, IconData>{
      'Overview': Icons.dashboard_rounded,
      'System Status': Icons.monitor_heart_outlined,
      'Students': Icons.school_rounded,
      'Parents': Icons.family_restroom_rounded,
      'Drivers': Icons.badge_rounded,
      'Admin Accounts': Icons.admin_panel_settings_rounded,
      'Driver Approvals': Icons.verified_user_rounded,
      'All Buses': Icons.directions_bus_rounded,
      'Assign Driver': Icons.person_add_alt_1_rounded,
      'Bus Status': Icons.fact_check_rounded,
      'Bus Maintenance': Icons.build_circle_rounded,
      'Maintenance History': Icons.history_rounded,
      'All Routes': Icons.alt_route_rounded,
      'Stops Management': Icons.location_on_rounded,
      'Bus Assignment': Icons.assignment_turned_in_rounded,
      'Route Deviation': Icons.wrong_location_rounded,
      'Live Fleet Map': Icons.map_rounded,
      'Bus Location': Icons.my_location_rounded,
      'ETA & Delays': Icons.schedule_rounded,
      'Student Attendance': Icons.school_rounded,
      'Driver Attendance': Icons.badge_rounded,
      'Attendance History': Icons.history_rounded,
      'Reports & Export': Icons.file_download_rounded,
      'Emergency SOS': Icons.warning_rounded,
      'Delay Alerts': Icons.notifications_active_rounded,
      'Safety Monitoring': Icons.health_and_safety_rounded,
      'Notification Center': Icons.notifications_rounded,
      'Trip Analytics': Icons.analytics_rounded,
      'Attendance Analytics': Icons.pie_chart_rounded,
      'Delay Analysis': Icons.show_chart_rounded,
      'Fleet Reports': Icons.assessment_rounded,
      'View Complaints': Icons.report_problem_rounded,
      'Feedback Status': Icons.feedback_rounded,
      'General Settings': Icons.settings_rounded,
      'Notification Settings': Icons.notifications_active_rounded,
      'Audit Log': Icons.history_rounded,
    };
    final colors = <Color>[
      _blue,
      _orange,
      const Color(0xFF16865C),
      const Color(0xFF7656C9),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a ${group.title} module',
          style: const TextStyle(fontSize: 14, color: _muted),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 700
                ? 3
                : constraints.maxWidth >= 440
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (var i = 0; i < group.pages.length; i++)
                  SizedBox(
                    width: width,
                    child: _moduleCard(
                      group.pages[i],
                      descriptions[group.pages[i]] ??
                          'Manage ${group.pages[i].toLowerCase()} for CampusBusAI 360.',
                      icons[group.pages[i]] ?? group.icon,
                      colors[i % colors.length],
                      () => _go(group.title, group.pages[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _moduleCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: .12),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: _muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(String page) {
    if (page == 'Overview') {
      return 'Monitor college bus operations from one place.';
    }
    if (page == 'Driver Approvals') {
      return 'Review driver registrations and approve verified accounts.';
    }
    if (page.contains('Attendance')) {
      return 'Review student and driver attendance records.';
    }
    if (page.contains('Route') || page.contains('Stops')) {
      return 'Manage routes, stops, assignments and route status.';
    }
    if (page.contains('Bus') ||
        page.contains('Fleet') ||
        page.contains('Maintenance')) {
      return 'Manage vehicles, service schedules and fleet status.';
    }
    return 'Manage ${page.toLowerCase()} for CampusBusAI 360.';
  }

  Widget _overview() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 1050
              ? 6
              : c.maxWidth > 650
              ? 3
              : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final cards = [
            (
              'Total Buses',
              '12',
              'Fleet records',
              Icons.directions_bus,
              _orange,
            ),
            ('Total Students', '416', 'Registered', Icons.groups, _blue),
            (
              'Total Drivers',
              '18',
              'Approved accounts',
              Icons.badge,
              const Color(0xFF6C63FF),
            ),
            (
              "Today's Trips",
              '24',
              'Demo count',
              Icons.route,
              const Color(0xFFDA8B18),
            ),
            (
              'On-time Rate',
              '92%',
              'Demo metric',
              Icons.schedule,
              const Color(0xFF15966A),
            ),
            (
              'Pending Approvals',
              null,
              'Driver requests',
              Icons.person_add_alt_1,
              Colors.red,
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in cards)
                SizedBox(
                  width: w,
                  child: _statCard(
                    c.$1,
                    c.$2 ?? '…',
                    c.$3,
                    c.$4,
                    c.$5,
                    pending: c.$2 == null,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 800) {
            return Column(
              children: [
                _panel('Today\'s Bus Status', _busTable(compact: true)),
                const SizedBox(height: 14),
                _panel('Attendance Summary', _attendanceSummary()),
                const SizedBox(height: 14),
                _panel('Quick Management', _quickActions()),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: _panel('Today\'s Bus Status', _busTable(compact: true)),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _panel('Attendance Summary', _attendanceSummary()),
                    const SizedBox(height: 14),
                    _panel('Quick Management', _quickActions()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    bool pending = false,
  }) => Container(
    padding: const EdgeInsets.all(14),
    constraints: const BoxConstraints(minHeight: 120),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: .13),
              child: Icon(icon, color: color, size: 21),
            ),
            const Spacer(),
            if (pending)
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('driver_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (_, s) => Text(
                  '${s.data?.docs.length ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _dark,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    ),
  );

  Widget _panel(String title, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );

  Widget _quickActions() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _quick(
        'Driver Approvals',
        Icons.verified_user,
        () => _go('User Management', 'Driver Approvals'),
      ),
      _quick(
        'Manage Fleet',
        Icons.directions_bus,
        () => _go('Fleet Management', 'All Buses'),
      ),
      _quick(
        'Manage Routes',
        Icons.route,
        () => _go('Route Management', 'All Routes'),
      ),
      _quick(
        'Safety Alerts',
        Icons.warning_amber,
        () => _go('Safety & Alerts', 'Emergency SOS'),
      ),
    ],
  );

  Widget _quick(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _dark,
          side: const BorderSide(color: _line),
        ),
        icon: Icon(icon, size: 17, color: _orange),
        label: Text(label),
      );

  Widget _busTable({bool compact = false}) => Column(
    children: [
      _busRow(
        'BUS-A01',
        'Ramesh Patil',
        'YSPM Main Route',
        'Running',
        Colors.green,
      ),
      const Divider(color: _line),
      _busRow('BUS-A02', 'S. Jadhav', 'City Route', 'Idle', _orange),
      const Divider(color: _line),
      _busRow(
        'BUS-A03',
        'Unassigned',
        'Route pending',
        'Maintenance',
        Colors.red,
      ),
      if (!compact) ...[
        const Divider(color: _line),
        _busRow('BUS-A04', 'P. More', 'Wadhe Route', 'Running', Colors.green),
      ],
    ],
  );

  Widget _busRow(
    String bus,
    String driver,
    String route,
    String status,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        const Icon(Icons.directions_bus_filled, color: _orange, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bus,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                '$driver • $route',
                style: const TextStyle(fontSize: 10, color: _muted),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _attendanceSummary() => Column(
    children: [
      Row(
        children: [
          const SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: .87,
                    strokeWidth: 10,
                    backgroundColor: Color(0xFFFFE6D1),
                    color: Color(0xFF15966A),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '87%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Present',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendDot(color: Color(0xFF15966A), label: 'Present • demo'),
                SizedBox(height: 8),
                _LegendDot(color: _orange, label: 'Absent • demo'),
                SizedBox(height: 8),
                _LegendDot(color: _blue, label: 'Not boarded • demo'),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _go('Attendance & Reports', 'Student Attendance'),
          child: const Text('View Attendance'),
        ),
      ),
    ],
  );

  Widget _driverApprovals() => _panel(
    'Driver Approval Center',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review registration details before approving a driver.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 430,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('driver_requests')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Could not load requests: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs
                  .where((d) => (d.data()['status'] ?? 'pending') == 'pending')
                  .toList();
              if (docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.task_alt, size: 54, color: Color(0xFF15966A)),
                      SizedBox(height: 10),
                      Text('No pending driver requests'),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFFFE8D6),
                              child: Icon(Icons.person, color: _orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['name']?.toString() ?? 'Unnamed driver',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    d['email']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Chip(
                              label: Text(
                                'PENDING',
                                style: TextStyle(fontSize: 10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 18,
                          runSpacing: 6,
                          children:
                              [
                                    Text('Mobile: ${d['mobile'] ?? '—'}'),
                                    Text(
                                      'Employee ID: ${d['employeeId'] ?? '—'}',
                                    ),
                                    Text('Bus: ${d['busNumber'] ?? '—'}'),
                                  ]
                                  .map(
                                    (w) => DefaultTextStyle(
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                      child: w,
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _working
                                  ? null
                                  : () => _reviewDriver(doc, true),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF16865C),
                              ),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _working
                                  ? null
                                  : () => _reviewDriver(doc, false),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _maintenance() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 750 ? 3 : 1;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            (
              'Last Maintenance',
              '12 Sep 2026',
              'Oil and filter service',
              Icons.check_circle,
              Colors.green,
            ),
            (
              'Next Service Due',
              '12 Dec 2026',
              'Demo schedule',
              Icons.calendar_month,
              _orange,
            ),
            (
              'Vehicles Reported',
              '2',
              'Needs admin review',
              Icons.build_circle,
              _blue,
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: w,
                  child: _statCard(item.$1, item.$2, item.$3, item.$4, item.$5),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      _panel(
        'Maintenance History',
        Column(
          children: [
            _simpleRecord(
              'BUS-A01',
              'Oil and filter service',
              '12 Sep 2026',
              'Completed',
              Colors.green,
            ),
            const Divider(color: _line),
            _simpleRecord(
              'BUS-A02',
              'Brake and tyre inspection',
              '18 Jun 2026',
              'Completed',
              Colors.green,
            ),
            const Divider(color: _line),
            _simpleRecord(
              'BUS-A03',
              'Scheduled maintenance',
              '12 Dec 2026',
              'Upcoming',
              _orange,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _panel('Report Vehicle Issue', _issueForm()),
    ],
  );

  Widget _issueForm() {
    final desc = TextEditingController();
    String type = 'General Inspection';
    return StatefulBuilder(
      builder: (context, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(
              labelText: 'Issue type',
              border: OutlineInputBorder(),
            ),
            items: const [
              'General Inspection',
              'Engine',
              'Brakes',
              'Tyres',
              'Battery / Electrical',
              'Other',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              if (v != null) setLocal(() => type = v);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: desc,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Describe vehicle issue',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _orange),
              onPressed: () {
                if (desc.text.trim().isEmpty) {
                  _message('Please describe the issue first.');
                  return;
                }
                _message(
                  'Demo only: connect Firestore to send this issue to Admin.',
                );
                desc.clear();
              },
              icon: const Icon(Icons.send),
              label: const Text('Submit Issue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleRecord(
    String title,
    String subtitle,
    String date,
    String status,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.directions_bus, color: _orange, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              Text(date, style: const TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );

  Widget _routesPage() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 700 ? 3 : 1;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            ('Total Routes', '6', Icons.route, _blue),
            ('Total Stops', '24', Icons.location_on, _orange),
            (
              'Assigned Buses',
              '10',
              Icons.directions_bus,
              const Color(0xFF15966A),
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final x in items)
                SizedBox(
                  width: w,
                  child: _statCard(x.$1, x.$2, 'Demo values', x.$3, x.$4),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      _panel(
        _selected,
        Column(
          children: [
            _routeRow(
              'Route 1 - Main',
              'Satara MIDC → Power House → Karanje → YSPM',
              'BUS-A01',
            ),
            const Divider(color: _line),
            _routeRow(
              'Route 2 - City',
              'City Centre → Wadhe Phata → YSPM',
              'BUS-A02',
            ),
            const Divider(color: _line),
            _routeRow(
              'Route 3 - Express',
              'Arphal → Vaduth → Arale → YSPM',
              'Unassigned',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed: () => _editDialog('Edit Route / Stops'),
                icon: const Icon(Icons.edit_road),
                label: const Text('Manage Route / Stops'),
              ),
            ),
            const Text(
              'Route list is demo data. Saving edits to other apps requires Firestore route integration.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _routeRow(String name, String stops, String bus) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFFFE8D6),
          child: Icon(Icons.alt_route, color: _orange),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(stops, style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 650)
          Text(bus, style: const TextStyle(fontSize: 11, color: _muted)),
        IconButton(
          tooltip: 'Edit',
          onPressed: () => _editDialog('Edit $name'),
          icon: const Icon(Icons.edit_outlined, color: _orange),
        ),
      ],
    ),
  );

  Widget _busesPage() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('buses').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return _panel(
          'Bus List',
          Text('Could not load buses: ${snapshot.error}'),
        );
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Center(child: CircularProgressIndicator());
      final buses = snapshot.data?.docs ?? [];
      final active = buses.where((b) => b.data()['isActive'] == true).length;
      final maintenance = buses
          .where((b) => (b.data()['status'] ?? '') == 'Maintenance')
          .length;
      return Column(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 750 ? 3 : 1;
              final w = (c.maxWidth - (cols - 1) * 12) / cols;
              final items = [
                ('Total Buses', '${buses.length}', Icons.directions_bus, _blue),
                (
                  'Active Buses',
                  '$active',
                  Icons.check_circle,
                  const Color(0xFF15966A),
                ),
                ('Maintenance', '$maintenance', Icons.build_circle, _orange),
              ];
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final x in items)
                    SizedBox(
                      width: w,
                      child: _statCard(
                        x.$1,
                        x.$2,
                        'Firestore records',
                        x.$3,
                        x.$4,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _panel(
            'Bus List',
            buses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No buses added yet. Click Add Bus to create the first bus.',
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < buses.length; i++) ...[
                        _busFirestoreRow(buses[i]),
                        if (i != buses.length - 1) const Divider(color: _line),
                      ],
                    ],
                  ),
          ),
        ],
      );
    },
  );

  Widget _busFirestoreRow(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final active = d['isActive'] == true;
    final status = (d['status'] ?? (active ? 'Active' : 'Inactive')).toString();
    final color = !active
        ? _muted
        : status == 'Maintenance'
        ? _orange
        : const Color(0xFF15966A);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showBusDetails(doc.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Row(
            children: [
              const Icon(Icons.directions_bus_filled, color: _orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (d['busNumber'] ?? 'Unnamed Bus').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    Text(
                      '${d['registrationNumber'] ?? 'Registration not set'} • ${d['routeName'] ?? 'Route not assigned'}',
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                    Text(
                      'Driver: ${d['driverName'] ?? 'Not assigned'} • Capacity: ${d['capacity'] ?? '-'}',
                      style: const TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  active ? status : 'Inactive',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editBus({String? busId, Map<String, dynamic>? existing}) async {
    final d = existing ?? {};
    final busNumber = TextEditingController(
      text: d['busNumber']?.toString() ?? '',
    );
    final registration = TextEditingController(
      text: d['registrationNumber']?.toString() ?? '',
    );
    final route = TextEditingController(text: d['routeName']?.toString() ?? '');
    final driverName = TextEditingController(
      text: d['driverName']?.toString() ?? '',
    );
    final driverId = TextEditingController(
      text: d['driverId']?.toString() ?? '',
    );
    final capacity = TextEditingController(
      text: d['capacity']?.toString() ?? '',
    );
    final departure = TextEditingController(
      text: d['departureTime']?.toString() ?? '',
    );
    final arrival = TextEditingController(
      text: d['arrivalTime']?.toString() ?? '',
    );
    final stops = TextEditingController(
      text:
          (d['stops'] is List
              ? (d['stops'] as List).join(', ')
              : d['stops']?.toString()) ??
          '',
    );
    String status = (d['status'] ?? 'Active').toString();
    final formKey = GlobalKey<FormState>();
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(busId == null ? 'Add Bus' : 'Edit Bus'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _busInput(busNumber, 'Bus Number', required: true),
                      _busInput(
                        registration,
                        'Registration Number',
                        required: true,
                      ),
                      _busInput(route, 'Route Name'),
                      _busInput(driverName, 'Driver Name'),
                      _busInput(driverId, 'Driver UID (optional)'),
                      _busInput(capacity, 'Capacity', number: true),
                      _busInput(departure, 'Departure Time'),
                      _busInput(arrival, 'Arrival Time'),
                      _busInput(stops, 'Stops (comma separated)', maxLines: 2),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: 'Bus Status',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(value: 'Idle', child: Text('Idle')),
                          DropdownMenuItem(
                            value: 'Maintenance',
                            child: Text('Maintenance'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => status = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    _message('Please login again.');
                    return;
                  }
                  final ref = FirebaseFirestore.instance.collection('buses');
                  final data = <String, dynamic>{
                    'busNumber': busNumber.text.trim(),
                    'registrationNumber': registration.text.trim(),
                    'routeName': route.text.trim(),
                    'driverName': driverName.text.trim(),
                    'driverId': driverId.text.trim(),
                    'capacity': int.tryParse(capacity.text.trim()) ?? 0,
                    'departureTime': departure.text.trim(),
                    'arrivalTime': arrival.text.trim(),
                    'stops': stops.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList(),
                    'status': status,
                    'isActive': status != 'Inactive',
                    'updatedAt': FieldValue.serverTimestamp(),
                    'updatedBy': uid,
                  };
                  try {
                    if (busId == null) {
                      data['createdAt'] = FieldValue.serverTimestamp();
                      data['createdBy'] = uid;
                      final created = await ref.add(data);
                      await _addBusHistory(
                        created.id,
                        'Bus Added',
                        'Bus ${busNumber.text.trim()} was added.',
                      );
                    } else {
                      await ref.doc(busId).update(data);
                      await _addBusHistory(
                        busId,
                        'Bus Updated',
                        'Bus details were updated.',
                      );
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted)
                      _message(
                        busId == null
                            ? 'Bus added successfully.'
                            : 'Bus updated successfully.',
                      );
                  } on FirebaseException catch (e) {
                    if (mounted)
                      _message(
                        'Save failed (${e.code}). Check Firestore rules.',
                      );
                  } catch (e) {
                    if (mounted) _message('Save failed: $e');
                  }
                },
                child: const Text('Save Bus'),
              ),
            ],
          ),
        ),
      );
    } finally {
      busNumber.dispose();
      registration.dispose();
      route.dispose();
      driverName.dispose();
      driverId.dispose();
      capacity.dispose();
      departure.dispose();
      arrival.dispose();
      stops.dispose();
    }
  }

  Widget _busInput(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    ),
  );

  Future<void> _addBusHistory(
    String busId,
    String action,
    String description,
  ) async {
    await FirebaseFirestore.instance.collection('bus_history').add({
      'busId': busId,
      'action': action,
      'description': description,
      'changedBy': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _changeBusActive(
    String busId,
    bool active,
    String busNumber,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('buses').doc(busId).update({
        'isActive': active,
        'status': active ? 'Active' : 'Inactive',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      });
      await _addBusHistory(
        busId,
        active ? 'Bus Activated' : 'Bus Deactivated',
        'Bus $busNumber was ${active ? 'activated' : 'deactivated'}.',
      );
      if (mounted) _message(active ? 'Bus activated.' : 'Bus deactivated.');
    } on FirebaseException catch (e) {
      if (mounted)
        _message('Status update failed (${e.code}). Check Firestore rules.');
    }
  }

  void _showBusDetails(String busId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 680,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('buses')
                .doc(busId)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.hasError)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Unable to load bus details.'),
                );
              if (!snap.hasData)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              if (!snap.data!.exists)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Bus record not found.'),
                );
              final d = snap.data!.data()!;
              final active = d['isActive'] == true;
              final busNumber = (d['busNumber'] ?? 'Bus').toString();
              return Padding(
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              busNumber,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              active
                                  ? (d['status'] ?? 'Active').toString()
                                  : 'Inactive',
                            ),
                            backgroundColor: active
                                ? const Color(0xFFE3F6EC)
                                : const Color(0xFFECEFF3),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                _editBus(busId: busId, existing: d),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _changeBusActive(busId, !active, busNumber),
                            icon: Icon(
                              active ? Icons.pause_circle : Icons.play_circle,
                            ),
                            label: Text(active ? 'Deactivate' : 'Activate'),
                          ),
                        ],
                      ),
                      const Divider(height: 26),
                      _detailLine(
                        'Registration Number',
                        d['registrationNumber'],
                      ),
                      _detailLine('Driver', d['driverName']),
                      _detailLine('Driver UID', d['driverId']),
                      _detailLine('Route', d['routeName']),
                      _detailLine('Capacity', d['capacity']),
                      _detailLine('Departure', d['departureTime']),
                      _detailLine('Arrival', d['arrivalTime']),
                      _detailLine(
                        'Stops',
                        d['stops'] is List
                            ? (d['stops'] as List).join(' → ')
                            : d['stops'],
                      ),
                      const Divider(height: 26),
                      const Text(
                        'Bus History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 190,
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('bus_history')
                              .where('busId', isEqualTo: busId)
                              .snapshots(),
                          builder: (ctx, history) {
                            if (history.hasError)
                              return const Text(
                                'History unavailable. Check Firestore rules/indexes.',
                              );
                            if (!history.hasData)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            final records = [...history.data!.docs]
                              ..sort(
                                (a, b) =>
                                    ((b.data()['timestamp'] as Timestamp?)
                                                ?.millisecondsSinceEpoch ??
                                            0)
                                        .compareTo(
                                          (a.data()['timestamp'] as Timestamp?)
                                                  ?.millisecondsSinceEpoch ??
                                              0,
                                        ),
                              );
                            if (records.isEmpty)
                              return const Text(
                                'No history recorded for this bus yet.',
                              );
                            return ListView(
                              children: [
                                for (final h in records)
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.history,
                                      color: _orange,
                                    ),
                                    title: Text(
                                      (h.data()['action'] ?? 'Updated')
                                          .toString(),
                                    ),
                                    subtitle: Text(
                                      (h.data()['description'] ?? '')
                                          .toString(),
                                    ),
                                    trailing: Text(
                                      _formatBusTime(h.data()['timestamp']),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const Text(
                        'Trip History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 150,
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('trips')
                              .where('busId', isEqualTo: busId)
                              .snapshots(),
                          builder: (ctx, trips) {
                            if (trips.hasError)
                              return const Text('Trip history unavailable.');
                            if (!trips.hasData)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            if (trips.data!.docs.isEmpty)
                              return const Text(
                                'No trips recorded for this bus yet.',
                              );
                            return ListView(
                              children: [
                                for (final t in trips.data!.docs)
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(
                                      Icons.route,
                                      color: _blue,
                                    ),
                                    title: Text(
                                      (t.data()['routeName'] ??
                                              t.data()['status'] ??
                                              'Trip')
                                          .toString(),
                                    ),
                                    subtitle: Text(
                                      'Driver: ${t.data()['driverName'] ?? t.data()['driverId'] ?? '-'}',
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _detailLine(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            (value ?? '-').toString(),
            style: const TextStyle(
              color: _dark,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );

  String _formatBusTime(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    return 'Pending';
  }

  Widget _attendancePage() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 750 ? 4 : 2;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            ('Present', '358', const Color(0xFF15966A)),
            ('Absent', '42', Colors.red),
            ('Late', '12', _orange),
            ('Attendance', '86.9%', _blue),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final x in items)
                SizedBox(
                  width: w,
                  child: _statCard(
                    x.$1,
                    x.$2,
                    'Illustrative records',
                    Icons.fact_check,
                    x.$3,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      _panel(
        _selected,
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selected == 'Driver Attendance'
                        ? 'Driver duty records'
                        : 'Student attendance records',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DropdownButton<String>(
                  value: 'Today',
                  items: const [
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                    DropdownMenuItem(
                      value: 'This Month',
                      child: Text('This Month'),
                    ),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
            const Divider(color: _line),
            if (_selected == 'Driver Attendance') ...[
              _attendanceRow(
                'Ramesh Patil',
                'BUS-A01',
                '07:35 AM',
                '04:20 PM',
                'Present',
                Colors.green,
              ),
              _attendanceRow(
                'S. Jadhav',
                'BUS-A02',
                '07:52 AM',
                '—',
                'Late',
                _orange,
              ),
              _attendanceRow(
                'P. More',
                'BUS-A04',
                '—',
                '—',
                'Absent',
                Colors.red,
              ),
            ] else ...[
              _attendanceRow(
                'Aarav Shinde',
                'Satara MIDC',
                '07:42 AM',
                '08:30 AM',
                'Present',
                Colors.green,
              ),
              _attendanceRow(
                'Sneha Jadhav',
                'Power House',
                '07:48 AM',
                '08:32 AM',
                'Present',
                Colors.green,
              ),
              _attendanceRow(
                'Rohan Patil',
                'Karanje',
                '—',
                '—',
                'Absent',
                Colors.red,
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Demo records. Real attendance requires Firestore / QR / duty-start integration.',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _attendanceRow(
    String name,
    String detail,
    String start,
    String end,
    String status,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.person, color: _orange),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(detail, style: const TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 650)
          Expanded(child: Text(start, style: const TextStyle(fontSize: 10))),
        if (MediaQuery.sizeOf(context).width > 850)
          Expanded(child: Text(end, style: const TextStyle(fontSize: 10))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _trackingPage() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 750 ? 3 : 1;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            ('Active Buses', '10', Icons.gps_fixed, _blue),
            ('Delayed Buses', '2', Icons.schedule, _orange),
            ('Avg ETA', '8 min', Icons.timer, const Color(0xFF15966A)),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final x in items)
                SizedBox(
                  width: w,
                  child: _statCard(x.$1, x.$2, 'Demo values', x.$3, x.$4),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      _panel(
        'Live Fleet Map',
        Container(
          height: 310,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MapPainter())),
              const Positioned(
                top: 18,
                left: 16,
                child: _MapTag('SATARA MIDC'),
              ),
              const Positioned(
                top: 60,
                right: 18,
                child: _MapTag('WADHE PHATA'),
              ),
              const Positioned(
                bottom: 18,
                right: 18,
                child: _MapTag('YSPM CAMPUS'),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 12),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_bus, color: _orange, size: 30),
                      Text(
                        'BUS-A01',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Demo map • GPS not connected',
                        style: TextStyle(fontSize: 10, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _alertsPage() => _panel(
    _selected,
    Column(
      children: [
        _simpleRecord(
          'SOS • BUS-A03',
          'Emergency alert example',
          '10:15 AM',
          'Demo alert',
          Colors.red,
        ),
        const Divider(color: _line),
        _simpleRecord(
          'Delay • BUS-A02',
          'Bus delayed at scheduled stop',
          '08:20 AM',
          'Review',
          _orange,
        ),
        const Divider(color: _line),
        _simpleRecord(
          'Route deviation • BUS-A01',
          'Illustrative route alert',
          '07:45 AM',
          'Demo alert',
          _blue,
        ),
        const SizedBox(height: 12),
        const Text(
          'No real alert is sent from these sample records.',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    ),
  );

  Widget _usersPage() {
    if (_selected == 'Admin Accounts') {
      return _liveAdminAccounts();
    }

    final Map<String, (String, String, IconData, Color)> summaries = {
      'Students': ('Total Students', '416', Icons.school, _blue),
      'Parents': ('Total Parents', '390', Icons.family_restroom, _orange),
      'Drivers': ('Total Drivers', '18', Icons.badge, const Color(0xFF15966A)),
    };

    final item = summaries[_selected] ?? summaries['Students']!;

    return Column(
      children: [
        _statCard(item.$1, item.$2, 'Demo value', item.$3, item.$4),
        const SizedBox(height: 16),
        _panel(
          _selected,
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'This section still uses demo data. '
              'Live integration will be added separately.',
              style: TextStyle(color: _muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveAdminAccounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Authorized administrators',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _dark,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _working ? null : _showAddAdminDialog,
              style: FilledButton.styleFrom(backgroundColor: _orange),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Admin'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _panel(
                'Admin Accounts',
                const Text(
                  'Could not load accounts. Check Firestore Rules '
                  'and confirm the current user has the admin claim.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _panel(
                'Admin Accounts',
                const Text('No Admin profiles found in Firestore.'),
              );
            }

            return _panel(
              'Admin Accounts (${docs.length})',
              Column(
                children: [
                  for (var i = 0; i < docs.length; i++) ...[
                    if (i > 0) const Divider(color: _line),
                    Builder(
                      builder: (context) {
                        final data = docs[i].data();
                        final active = data['isActive'] == true;
                        final name = (data['name'] ?? 'Unnamed Admin')
                            .toString();
                        final email = (data['email'] ?? '').toString();

                        return _simpleRecord(
                          name,
                          '$email • UID: ${docs[i].id}',
                          'Administrator',
                          active ? 'Active' : 'Inactive',
                          active ? Colors.green : Colors.red,
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Account list is read from Firestore. Creating an Authentication '
          'account and assigning admin privileges requires the trusted '
          'local Admin SDK setup.',
          style: TextStyle(fontSize: 11, color: _muted),
        ),
      ],
    );
  }

  void _showAddAdminDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Admin'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This form collects the details only. It does not create '
                'an Authentication account or grant admin privileges yet.',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isEmpty ||
                  !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a name and valid email address.'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              _message(
                'Details validated. Next, create the account through '
                'the trusted local Admin SDK setup.',
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _genericPage() => Column(
    children: [
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 750 ? 3 : 1;
          final w = (c.maxWidth - (cols - 1) * 12) / cols;
          final items = [
            ('Total Records', '—', Icons.dataset, _blue),
            ('Needs Review', '—', Icons.pending_actions, _orange),
            ('Updated Today', '—', Icons.update, const Color(0xFF15966A)),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final x in items)
                SizedBox(
                  width: w,
                  child: _statCard(
                    x.$1,
                    x.$2,
                    'Connect data source',
                    x.$3,
                    x.$4,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      _panel(
        _selected,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.dashboard_customize, color: _orange, size: 36),
            const SizedBox(height: 10),
            Text(
              '$_selected page',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 6),
            const Text(
              'The page layout is ready to extend. Connect its Firestore collection and actions to display live records.',
              style: TextStyle(color: _muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _message(
                    'Search will work after the data source is connected.',
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _editDialog('Add / Edit $_selected'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add / Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  void _editDialog(String title) {
    final name = TextEditingController();
    final details = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Name / Route / Bus number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: details,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Details / Stops / Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Prototype dialog only: Save is not connected to Firestore yet.',
                style: TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () {
              Navigator.pop(ctx);
              _message('Demo only: connect Firestore before saving changes.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _NavGroup {
  final String title;
  final IconData icon;
  final List<String> pages;
  const _NavGroup(this.title, this.icon, this.pages);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
      ),
    ],
  );
}

class _MapTag extends StatelessWidget {
  final String label;
  const _MapTag(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _dark,
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 7; i++) {
      final path = Path()
        ..moveTo(0, size.height * i / 7)
        ..lineTo(size.width * .3, size.height * ((i + 1) % 7) / 7)
        ..lineTo(size.width * .7, size.height * i / 7)
        ..lineTo(size.width, size.height * ((i + 2) % 7) / 7);
      canvas.drawPath(path, road);
    }
    final route = Paint()
      ..color = _blue
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .08, size.height * .72)
      ..lineTo(size.width * .25, size.height * .55)
      ..lineTo(size.width * .42, size.height * .68)
      ..lineTo(size.width * .55, size.height * .42)
      ..lineTo(size.width * .72, size.height * .5)
      ..lineTo(size.width * .9, size.height * .2);
    canvas.drawPath(path, route);
    final dot = Paint()..color = _orange;
    for (final p in [
      Offset(size.width * .25, size.height * .55),
      Offset(size.width * .42, size.height * .68),
      Offset(size.width * .55, size.height * .42),
      Offset(size.width * .72, size.height * .5),
    ]) {
      canvas.drawCircle(p, 6, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
