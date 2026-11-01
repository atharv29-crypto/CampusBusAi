import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool tripStarted = true;
  String selectedTab = 'Dashboard';
  String maintenanceIssueType = 'General Inspection';
  final TextEditingController maintenanceIssueController =
      TextEditingController();
  bool issueSubmitted = false;

  final int expectedStudents = 40;
  final Set<String> boarded = {
    'Aarav Shinde',
    'Sneha Jadhav',
    'Rohan Patil',
    'Pooja More',
    'Aditya Kadam',
  };

  final List<Map<String, dynamic>> students = [
    {'name': 'Aarav Shinde', 'stop': 'Satara MIDC', 'id': 'CSE-01'},
    {'name': 'Sneha Jadhav', 'stop': 'Power House', 'id': 'CSE-02'},
    {'name': 'Rohan Patil', 'stop': 'Power House', 'id': 'CSE-03'},
    {'name': 'Pooja More', 'stop': 'Karanje', 'id': 'CSE-04'},
    {'name': 'Aditya Kadam', 'stop': 'College Main Gate', 'id': 'CSE-05'},
    {'name': 'Neha Patil', 'stop': 'Satara MIDC', 'id': 'CSE-06'},
    {'name': 'Om Jadhav', 'stop': 'Karanje', 'id': 'CSE-07'},
    {'name': 'Sakshi More', 'stop': 'Power House', 'id': 'CSE-08'},
  ];

  final List<Map<String, dynamic>> stops = [
    {'name': 'Satara MIDC', 'expected': 15, 'boarded': 15},
    {'name': 'Power House', 'expected': 10, 'boarded': 8},
    {'name': 'Karanje', 'expected': 8, 'boarded': 0},
    {'name': 'College Main Gate', 'expected': 7, 'boarded': 0},
  ];

  int get boardedCount => boarded.length;
  int get remainingCount => expectedStudents - boardedCount;

  @override
  void dispose() {
    maintenanceIssueController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to access the Driver Dashboard.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Unable to load driver profile: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data?.data();
        if (profile == null ||
            profile['role'] != 'driver' ||
            profile['isActive'] != true) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Driver profile not found or account is inactive. Contact Admin.',
              ),
            ),
          );
        }

        final driverName = (profile['name'] ?? 'Driver').toString();
        final busNumber = (profile['busNumber'] ?? 'NOT-ASSIGNED').toString();
        final routeName = (profile['routeName'] ?? 'Route not assigned')
            .toString();

        return Scaffold(
          backgroundColor: driverBg,
          body: Column(
            children: [
              _topBar(driverName),
              Expanded(
                child: Row(
                  children: [
                    if (MediaQuery.sizeOf(context).width >= 1100) _sidebar(),
                    Expanded(
                      child: selectedTab == 'Bus Maintenance'
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _maintenancePage(busNumber, routeName),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _welcome(driverName, busNumber, routeName),
                                  const SizedBox(height: 20),
                                  _summaryCards(busNumber, routeName),
                                  const SizedBox(height: 20),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 850) {
                                        return Column(
                                          children: [
                                            _tripPanel(),
                                            const SizedBox(height: 16),
                                            _routePanel(),
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _tripPanel()),
                                          const SizedBox(width: 16),
                                          Expanded(child: _routePanel()),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      if (constraints.maxWidth < 850) {
                                        return Column(
                                          children: [
                                            _stopWisePanel(),
                                            const SizedBox(height: 16),
                                            _studentsPanel(),
                                            const SizedBox(height: 16),
                                            _activityPanel(),
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: _stopWisePanel()),
                                          const SizedBox(width: 14),
                                          Expanded(child: _studentsPanel()),
                                          const SizedBox(width: 14),
                                          Expanded(child: _activityPanel()),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  const Center(
                                    child: Text(
                                      'CampusBusAI 360 • Driver Profile: Live • Trip/Attendance: Demo',
                                      style: TextStyle(
                                        color: driverMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topBar(String driverName) {
    return Container(
      height: 75,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          const Icon(
            Icons.directions_bus_rounded,
            color: driverOrange,
            size: 35,
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
                    color: driverDark,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track • Predict • Protect',
                  style: TextStyle(color: driverMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width > 650)
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search students, stops, routes...',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: driverBg,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Bus Maintenance',
            onPressed: () => setState(() => selectedTab = 'Bus Maintenance'),
            icon: const Icon(Icons.build_circle_outlined, color: driverOrange),
          ),
          IconButton(
            onPressed: () => showMessage('Notifications demo'),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE8D6),
            child: Icon(Icons.person, color: driverOrange),
          ),
          if (MediaQuery.sizeOf(context).width > 500) ...[
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driverName, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Driver',
                  style: TextStyle(color: driverMuted, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sidebar() {
    final items = [
      [Icons.dashboard_rounded, 'Dashboard'],
      [Icons.alt_route_rounded, "Today's Trip"],
      [Icons.groups_rounded, 'Students'],
      [Icons.fact_check_outlined, 'Attendance'],
      [Icons.notifications_none, 'Notifications'],
      [Icons.warning_amber_rounded, 'Emergency SOS'],
      [Icons.build_circle_outlined, 'Bus Maintenance'],
      [Icons.person_outline, 'My Profile'],
      [Icons.settings_outlined, 'Settings'],
    ];

    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              decoration: BoxDecoration(
                color: items[i][1] == selectedTab
                    ? driverOrange
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  items[i][0] as IconData,
                  color: items[i][1] == selectedTab ? Colors.white : driverDark,
                ),
                title: Text(
                  items[i][1] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: items[i][1] == selectedTab
                        ? Colors.white
                        : driverDark,
                    fontWeight: items[i][1] == selectedTab
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  final label = items[i][1] as String;
                  if (label == 'Dashboard' || label == 'Bus Maintenance') {
                    setState(() => selectedTab = label);
                  } else {
                    showMessage('$label is not connected in this demo yet.');
                  }
                },
              ),
            ),
          const Spacer(),
          const Icon(Icons.support_agent, size: 38, color: driverOrange),
          const Text(
            'Need Help?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Contact Transport Office',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: driverMuted),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => showMessage('Contact office demo'),
            child: const Text('Call Office'),
          ),
        ],
      ),
    );
  }

  Widget _maintenancePage(String busNumber, String routeName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => selectedTab = 'Dashboard'),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Dashboard',
            ),
            const SizedBox(width: 6),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus Maintenance',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: driverDark,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Service schedule, maintenance history and vehicle issue reporting',
                    style: TextStyle(color: driverMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.build_circle, color: driverOrange, size: 34),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFD8B5)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: driverOrange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Demo maintenance records only. Admin/Transport Office should verify and update actual service dates.',
                  style: TextStyle(color: driverDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              _maintenanceInfoCard(
                'Last Maintenance',
                '12 Sep 2026',
                'Oil and filter service',
                Icons.check_circle_outline,
                Colors.green,
              ),
              _maintenanceInfoCard(
                'Next Maintenance Due',
                '12 Dec 2026',
                'Scheduled service (demo)',
                Icons.calendar_month,
                driverOrange,
              ),
              _maintenanceInfoCard(
                'Vehicle',
                busNumber,
                routeName,
                Icons.directions_bus,
                Colors.blue,
              ),
            ];
            if (constraints.maxWidth < 700) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: cards[i],
                    ),
                ],
              );
            }
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == cards.length - 1 ? 0 : 12,
                      ),
                      child: cards[i],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final history = _maintenanceHistoryPanel();
            final report = _reportMaintenancePanel();
            if (constraints.maxWidth < 850) {
              return Column(
                children: [history, const SizedBox(height: 16), report],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: history),
                const SizedBox(width: 16),
                Expanded(child: report),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'CampusBusAI 360 • Maintenance • Demo Data',
            style: TextStyle(color: driverMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _maintenanceInfoCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: driverMuted),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: driverDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: driverMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceHistoryPanel() {
    return _panel(
      'Maintenance History',
      Icons.history,
      Column(
        children: [
          _maintenanceHistoryRow(
            '12 Sep 2026',
            'Oil and filter service',
            'Completed • Demo record',
            Colors.green,
          ),
          const Divider(),
          _maintenanceHistoryRow(
            '18 Jun 2026',
            'Brake and tyre inspection',
            'Completed • Demo record',
            Colors.green,
          ),
          const Divider(),
          _maintenanceHistoryRow(
            '12 Dec 2026',
            'Scheduled maintenance',
            'Upcoming • Demo record',
            driverOrange,
          ),
          const SizedBox(height: 12),
          const Text(
            'Actual history and service costs will be added after Admin/Firebase integration.',
            style: TextStyle(fontSize: 11, color: driverMuted),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceHistoryRow(
    String date,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $subtitle',
                  style: const TextStyle(fontSize: 10, color: driverMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportMaintenancePanel() {
    return _panel(
      'Report Vehicle Issue',
      Icons.report_problem_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select issue type',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: maintenanceIssueType,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'General Inspection',
                child: Text('General Inspection'),
              ),
              DropdownMenuItem(value: 'Engine', child: Text('Engine')),
              DropdownMenuItem(value: 'Brakes', child: Text('Brakes')),
              DropdownMenuItem(value: 'Tyres', child: Text('Tyres')),
              DropdownMenuItem(
                value: 'Battery / Electrical',
                child: Text('Battery / Electrical'),
              ),
              DropdownMenuItem(value: 'Other', child: Text('Other')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => maintenanceIssueType = value);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Describe the issue',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: maintenanceIssueController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Example: unusual engine sound, low tyre pressure...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: driverOrange,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                if (maintenanceIssueController.text.trim().isEmpty) {
                  showMessage('Please describe the vehicle issue first.');
                  return;
                }
                setState(() => issueSubmitted = true);
                showMessage(
                  'Issue recorded in demo only. No alert sent to Admin.',
                );
                maintenanceIssueController.clear();
              },
              icon: const Icon(Icons.send),
              label: const Text('Submit Issue'),
            ),
          ),
          if (issueSubmitted)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Last issue submitted in this demo session.',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _welcome(String driverName, String busNumber, String routeName) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $driverName! 👋',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: driverDark,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Here is today's trip information.",
              style: TextStyle(color: driverMuted),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, color: driverOrange),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today’s Trip',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$busNumber • $routeName',
                    style: TextStyle(fontSize: 11, color: driverMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCards(String busNumber, String routeName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;

        final cards = [
          [
            'Bus Number',
            busNumber,
            routeName,
            Icons.directions_bus,
            driverOrange,
          ],
          [
            'Total Students',
            '$expectedStudents',
            'Expected today',
            Icons.groups,
            Colors.blue,
          ],
          [
            'Boarded',
            '$boardedCount',
            'Demo records',
            Icons.check_circle,
            Colors.green,
          ],
          [
            'Yet to Board',
            '$remainingCount',
            'Pending verification',
            Icons.access_time,
            Colors.deepOrange,
          ],
          [
            'Current Occupancy',
            '$boardedCount / 50',
            '50-seat capacity (demo)',
            Icons.airline_seat_recline_normal,
            Colors.blue,
          ],
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: _summaryCard(
                  card[0] as String,
                  card[1] as String,
                  card[2] as String,
                  card[3] as IconData,
                  card[4] as Color,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: driverMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: driverDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: driverMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: driverOrange, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: driverDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _routePanel() {
    final routeStops = [
      ['Satara MIDC', '15 / 15 boarded', 'Completed'],
      ['Power House', '8 / 10 boarded', 'Current Stop'],
      ['Karanje', '0 / 8 boarded', 'Upcoming'],
      ['College Main Gate', '0 / 7 boarded', 'Upcoming'],
    ];

    return _panel(
      "Today's Route & Stops",
      Icons.alt_route,
      Column(
        children: [
          for (int i = 0; i < routeStops.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: i == 1
                    ? const Color(0xFFEAF4FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i == 0 ? Colors.green : driverOrange,
                    child: Icon(
                      i == 0 ? Icons.check : Icons.location_on,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeStops[i][0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          routeStops[i][1],
                          style: const TextStyle(
                            fontSize: 10,
                            color: driverMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    routeStops[i][2],
                    style: TextStyle(
                      fontSize: 9,
                      color: i == 0 ? Colors.green : driverOrange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tripPanel() {
    return _panel(
      'Current Trip',
      Icons.route,
      Column(
        children: [
          Row(
            children: [
              Expanded(child: _timeBox('Start Time', '07:45 AM')),
              const SizedBox(width: 10),
              Expanded(child: _timeBox('Expected End', '08:30 AM')),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: tripStarted
                      ? null
                      : () => setState(() => tripStarted = true),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Trip'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: tripStarted ? () => _confirmEndTrip() : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('End Trip'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue, size: 30),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Stop',
                        style: TextStyle(color: driverMuted, fontSize: 11),
                      ),
                      Text(
                        'Karanje',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('In 4 min • 1.2 km', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallAction(
                  'Report Issue',
                  Icons.warning_rounded,
                  Colors.deepOrange,
                  () => _reportDialog('Report Issue'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallAction(
                  'Emergency SOS',
                  Icons.sos,
                  Colors.red,
                  () => _reportDialog('Emergency SOS'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _smallAction(
                  'Call Office',
                  Icons.call,
                  Colors.blue,
                  () => showMessage('Calling is not configured in this demo.'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String title, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: driverBg,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: driverMuted)),
          const SizedBox(height: 5),
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _stopWisePanel() {
    return _panel(
      'Stop-wise Students',
      Icons.groups,
      Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 3, child: _TableHeading('Stop')),
              Expanded(child: _TableHeading('Expected')),
              Expanded(child: _TableHeading('Boarded')),
              Expanded(child: _TableHeading('Remaining')),
            ],
          ),
          const Divider(),
          for (final stop in stops)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      stop['name'] as String,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stop['expected']}',
                      style: const TextStyle(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${stop['boarded']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${(stop['expected'] as int) - (stop['boarded'] as int)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          const Text(
            'Demo stop counts; real attendance integration pending.',
            style: TextStyle(fontSize: 10, color: driverMuted),
          ),
        ],
      ),
    );
  }

  Widget _studentsPanel() {
    return _panel(
      'Students at Current Stop',
      Icons.people_alt,
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statusChip('Boarded ${boarded.length}', Colors.green),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _statusChip(
                  'Yet to Board ${students.length - boarded.length}',
                  Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final student in students)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8ECF2))),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 15,
                    backgroundColor: Color(0xFFEAF0F8),
                    child: Icon(Icons.person, size: 17, color: driverMuted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student['name'] as String,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${student['id']} • ${student['stop']}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: driverMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _toggleBoarding(student['name'] as String),
                    child: Text(
                      boarded.contains(student['name'])
                          ? 'Boarded ✓'
                          : 'Mark Boarded',
                      style: TextStyle(
                        fontSize: 10,
                        color: boarded.contains(student['name'])
                            ? Colors.green
                            : driverOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _activityPanel() {
    return _panel(
      'Recent Activity',
      Icons.notifications_active,
      const Column(
        children: [
          _ActivityRow(
            icon: Icons.directions_bus,
            color: driverOrange,
            title: 'Arrived at Power House',
            subtitle: '28 students boarded',
            time: '08:08 AM',
          ),
          Divider(),
          _ActivityRow(
            icon: Icons.check_circle,
            color: Colors.green,
            title: 'Left Satara MIDC',
            subtitle: '15 students boarded',
            time: '07:52 AM',
          ),
          Divider(),
          _ActivityRow(
            icon: Icons.play_circle,
            color: Colors.blue,
            title: 'Bus started from depot',
            subtitle: 'Demo trip started',
            time: '07:45 AM',
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _smallAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
          child: Column(
            children: [
              Icon(icon, color: color, size: 25),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleBoarding(String name) {
    setState(() {
      if (boarded.contains(name)) {
        boarded.remove(name);
      } else {
        boarded.add(name);
      }
    });
    showMessage(
      boarded.contains(name)
          ? '$name marked as boarded (demo)'
          : '$name boarding status reset (demo)',
    );
  }

  void _confirmEndTrip() {
    final pending = remainingCount;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End Trip?'),
        content: Text(
          '$pending students are still pending in the demo count. '
          'Verify attendance before ending the trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => tripStarted = false);
              Navigator.pop(dialogContext);
              showMessage('Trip ended in demo mode.');
            },
            child: const Text('Confirm Demo'),
          ),
        ],
      ),
    );
  }

  void _reportDialog(String title) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: const Text(
          'This is a demonstration. No real emergency alert or call is sent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showMessage('$title demo recorded locally.');
            },
            child: const Text('Test'),
          ),
        ],
      ),
    );
  }
}

class _TableHeading extends StatelessWidget {
  final String label;
  const _TableHeading(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: driverMuted,
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: driverMuted),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 9, color: driverMuted)),
        ],
      ),
    );
  }
}
