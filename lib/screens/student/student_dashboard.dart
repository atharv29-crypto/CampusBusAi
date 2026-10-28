import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_feature_screen.dart';
import 'google_map_tracking.dart';

const orange = Color(0xFFFF7900);
const dark = Color(0xFF172033);
const muted = Color(0xFF788195);
const pageBg = Color(0xFFF6F8FC);
void openStudentFeature(BuildContext context, String title, IconData icon) {
  if (title == 'Dashboard') return;

  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => StudentFeatureScreen(title: title, icon: icon),
    ),
  );
}

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1050;

          return Column(
            children: [
              const TopBar(),
              Expanded(
                child: Row(
                  children: [
                    if (desktop) const Sidebar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(desktop ? 24 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const WelcomeSection(),
                            const SizedBox(height: 22),
                            const SummarySection(),
                            const SizedBox(height: 18),
                            if (desktop)
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      children: [
                                        GoogleMapTracking(),
                                        SizedBox(height: 16),
                                        AttendanceSection(),
                                        SizedBox(height: 16),
                                        QuickActions(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      children: [
                                        RouteSection(),
                                        SizedBox(height: 16),
                                        NotificationsSection(),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Column(
                                children: [
                                  GoogleMapTracking(),
                                  SizedBox(height: 16),
                                  RouteSection(),
                                  SizedBox(height: 16),
                                  AttendanceSection(),
                                  SizedBox(height: 16),
                                  QuickActions(),
                                  SizedBox(height: 16),
                                  NotificationsSection(),
                                ],
                              ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'CampusBusAI 360 • Track • Predict • Protect',
                                style: TextStyle(color: muted, fontSize: 12),
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
          );
        },
      ),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 420;
        final showStudentName = width >= 620;
        final showSearch = width >= 850;

        return Container(
          height: compact ? 68 : 76,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 22,
            vertical: 4,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8EBF0))),
          ),
          child: Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                color: orange,
                size: compact ? 29 : 36,
              ),
              SizedBox(width: compact ? 7 : 10),

              Expanded(
                flex: showSearch ? 3 : 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CampusBusAI 360',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: compact ? 17 : 21,
                          fontWeight: FontWeight.bold,
                          color: dark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track • Predict • Protect',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: compact ? 10 : 12,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (showSearch) ...[
                const SizedBox(width: 16),
                const Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Search bus, stop or route...',
                        prefixIcon: Icon(Icons.search),
                        filled: true,
                        fillColor: pageBg,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              IconButton(
                tooltip: 'Notifications',
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  openStudentFeature(
                    context,
                    'Notifications',
                    Icons.notifications_none_rounded,
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),

              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Logout',
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                onPressed: () async {
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true) {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logout failed. Please try again.'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),

              SizedBox(width: compact ? 4 : 8),

              CircleAvatar(
                radius: compact ? 16 : 19,
                backgroundColor: const Color(0xFFFFE8D6),
                child: Icon(
                  Icons.person,
                  color: orange,
                  size: compact ? 19 : 24,
                ),
              ),

              if (showStudentName) ...[
                const SizedBox(width: 10),
                const Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atharv Chorge',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Student',
                        maxLines: 1,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      [Icons.dashboard_rounded, 'Dashboard'],
      [Icons.location_on_outlined, 'Live Tracking'],
      [Icons.alt_route_rounded, 'My Route'],
      [Icons.calendar_month_outlined, 'Attendance'],
      [Icons.notifications_none, 'Notifications'],
      [Icons.person_outline, 'My Profile'],
      [Icons.settings_outlined, 'Settings'],
    ];

    return Container(
      width: 225,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: i == 0 ? orange : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    items[i][0] as IconData,
                    color: i == 0 ? Colors.white : dark,
                  ),
                  title: Text(
                    items[i][1] as String,
                    style: TextStyle(
                      color: i == 0 ? Colors.white : dark,
                      fontWeight: i == 0 ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    final title = items[i][1] as String;
                    final icon = items[i][0] as IconData;
                    openStudentFeature(context, title, icon);
                  },
                ),
              ),
            ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.support_agent, color: orange, size: 34),
                SizedBox(height: 8),
                Text(
                  'Need Help?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  'Contact Transport Office',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, Atharv! 👋',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Here's your bus information for today.",
              style: TextStyle(color: muted, fontSize: 14),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFECEFF3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, color: orange),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'College Bus Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Semester 6 • Student Portal',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  const SummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 950
            ? 4
            : constraints.maxWidth >= 540
            ? 2
            : 1;

        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: const SummaryCard(
                title: 'Bus Number',
                value: 'BUS-01',
                subtitle: 'YSPM Main Route',
                icon: Icons.directions_bus_rounded,
                color: orange,
              ),
            ),
            SizedBox(
              width: width,
              child: const SummaryCard(
                title: 'Estimated Arrival',
                value: '8 min',
                subtitle: 'To your pickup stop',
                icon: Icons.access_time_rounded,
                color: Colors.green,
              ),
            ),
            SizedBox(
              width: width,
              child: const SummaryCard(
                title: 'Current Location',
                value: 'Near Power House',
                subtitle: 'Demo location',
                icon: Icons.location_on_rounded,
                color: Colors.purple,
              ),
            ),
            SizedBox(
              width: width,
              child: const SummaryCard(
                title: 'Bus Occupancy',
                value: '28 / 50',
                subtitle: '56% seats filled',
                icon: Icons.groups_rounded,
                color: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF3)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const Panel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFECEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: orange, size: 23),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class TrackingMap extends StatelessWidget {
  const TrackingMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Live Bus Tracking',
      icon: Icons.directions_bus_rounded,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.circle, color: Colors.red, size: 9),
            SizedBox(width: 5),
            Text(
              'Demo Location',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
          ],
        ),
      ),
      child: Container(
        height: 300,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F2E3),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: MapPainter())),
            const Positioned(top: 20, left: 18, child: MapLabel('SATARA MIDC')),
            const Positioned(
              top: 22,
              right: 18,
              child: MapLabel('YSPM COLLEGE'),
            ),
            const Positioned(
              bottom: 40,
              left: 18,
              child: MapLabel('Power House'),
            ),
            const Positioned(
              bottom: 22,
              right: 22,
              child: Icon(Icons.school, color: dark, size: 30),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22000000), blurRadius: 14),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.directions_bus, color: orange, size: 32),
                    SizedBox(height: 4),
                    Text(
                      'BUS-01',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Speed: 32 km/h', style: TextStyle(fontSize: 11)),
                    Text('ETA: 8 min', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                'Illustrative map • GPS not connected',
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapLabel extends StatelessWidget {
  final String text;

  const MapLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 7; i++) {
      final path = Path()
        ..moveTo(0, size.height * (i / 7))
        ..lineTo(size.width * 0.35, size.height * ((i + 1) / 8))
        ..lineTo(size.width * 0.6, size.height * (i / 7))
        ..lineTo(size.width, size.height * ((i + 1) / 8));
      canvas.drawPath(path, roadPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF1685F8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.73)
      ..lineTo(size.width * 0.22, size.height * 0.83)
      ..lineTo(size.width * 0.38, size.height * 0.64)
      ..lineTo(size.width * 0.56, size.height * 0.53)
      ..lineTo(size.width * 0.67, size.height * 0.31)
      ..lineTo(size.width * 0.82, size.height * 0.27)
      ..lineTo(size.width * 0.92, size.height * 0.15);

    canvas.drawPath(route, routePaint);

    final stopPaint = Paint()..color = orange;

    for (final point in [
      Offset(size.width * 0.22, size.height * 0.83),
      Offset(size.width * 0.38, size.height * 0.64),
      Offset(size.width * 0.67, size.height * 0.31),
      Offset(size.width * 0.82, size.height * 0.27),
    ]) {
      canvas.drawCircle(point, 7, stopPaint);
      canvas.drawCircle(
        point,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouteSection extends StatelessWidget {
  const RouteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final stops = [
      ['Lonand', 'Start', 'Start'],
      ['Koparde Phata', 'Route stop', ''],
      ['Salpe', 'Route stop', ''],
      ['Adaki Phata', 'Route stop', ''],
      ['Wathar', 'Route stop', ''],
      ['Deur', 'Route stop', ''],
      ['Pimpode Khurd', 'Route stop', ''],
      ['Ambawade', 'Route stop', ''],
      ['Revadi Phata', 'Route stop', ''],
      ['Shivtar', 'Route stop', ''],
      ['Yashoda Technical Campus', 'Destination', 'Destination'],
    ];

    return Panel(
      title: "Today's Route",
      icon: Icons.alt_route_rounded,
      trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      child: Column(
        children: [
          for (int i = 0; i < stops.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Icon(
                    i == 0 || i == stops.length - 1
                        ? Icons.location_on
                        : Icons.circle_outlined,
                    color: i == 0
                        ? Colors.green
                        : (i == stops.length - 1 ? Colors.red : muted),
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stops[i][0],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (stops[i][2].isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: i == stops.length - 1
                            ? const Color(0xFFFFE8E8)
                            : const Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        stops[i][2],
                        style: TextStyle(
                          fontSize: 10,
                          color: i == stops.length - 1
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    stops[i][1],
                    style: const TextStyle(fontSize: 11, color: muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AttendanceSection extends StatelessWidget {
  const AttendanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: "Today's Attendance",
      icon: Icons.fact_check_rounded,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF9F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 30),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not yet boarded',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tap when you board the bus',
                        style: TextStyle(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: orange),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Boarding Demo'),
                      content: const Text(
                        'Demo only. Attendance is not saved to Firebase yet.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Mark as Boarded'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: CountBox('40', 'Expected', Colors.blue)),
              SizedBox(width: 8),
              Expanded(child: CountBox('28', 'Boarded', Colors.green)),
              SizedBox(width: 8),
              Expanded(child: CountBox('12', 'Yet to Board', Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

class CountBox extends StatelessWidget {
  final String number;
  final String label;
  final Color color;

  const CountBox(this.number, this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: 'Quick Actions',
      icon: Icons.bolt_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 650 ? 4 : 2;
          final width = (constraints.maxWidth - (columns - 1) * 9) / columns;

          final actions = [
            ['Track Bus', 'Live location', Icons.location_on, Colors.green],
            [
              'View Route',
              'Stops & timings',
              Icons.calendar_month,
              Colors.blue,
            ],
            ['Report Issue', 'Bus delay / other', Icons.notifications, orange],
            ['Emergency SOS', 'Send demo alert', Icons.sos, Colors.red],
          ];

          return Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final action in actions)
                SizedBox(
                  width: width,
                  child: Material(
                    color: (action[3] as Color).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (action[0] == 'Emergency SOS') {
                          showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Emergency SOS'),
                              content: const Text(
                                'Demo only. No real emergency alert or call will be sent.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Close'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Demo SOS selected'),
                                      ),
                                    );
                                  },
                                  child: const Text('Test SOS'),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${action[0]} demo selected'),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 5,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              action[2] as IconData,
                              color: action[3] as Color,
                              size: 28,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              action[0] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              action[1] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 9, color: muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      [
        Icons.directions_bus,
        'Bus-01 is 5 minutes delayed',
        'Due to heavy traffic near MIDC',
        Colors.orange,
      ],
      [
        Icons.check_circle,
        'Previous attendance marked',
        'Boarded at Power House',
        Colors.green,
      ],
      [
        Icons.info,
        'Bus-01 left Satara MIDC',
        'Next stop: Power House',
        Colors.blue,
      ],
    ];

    return Panel(
      title: 'Recent Notifications',
      icon: Icons.notifications_active_outlined,
      trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      child: Column(
        children: [
          for (final n in notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: (n[3] as Color).withValues(alpha: 0.12),
                    child: Icon(n[0] as IconData, color: n[3] as Color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n[1] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n[2] as String,
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
