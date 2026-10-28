import 'package:flutter/material.dart';

const Color _orange = Color(0xFFFF7900);
const Color _dark = Color(0xFF172033);
const Color _muted = Color(0xFF788195);
const Color _pageBg = Color(0xFFF6F8FC);

class StudentFeatureScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const StudentFeatureScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> details = _getDetails(title);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECEFF3)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFFFE8D6),
                        child: Icon(icon, color: _orange, size: 34),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details['description']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _muted, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: _orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                details['status']!,
                                style: const TextStyle(
                                  color: _dark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Available Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _dark,
                  ),
                ),
                const SizedBox(height: 12),
                ..._getItems(title).map(
                  (item) => Card(
                    elevation: 0,
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFECEFF3)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle_outline,
                        color: _orange,
                      ),
                      title: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _dark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'CampusBusAI 360 • Track • Predict • Protect',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, String> _getDetails(String screenTitle) {
    switch (screenTitle) {
      case 'Live Tracking':
        return {
          'description': 'View your assigned bus tracking information.',
          'status': 'Demo mode: GPS is not connected.',
        };
      case 'My Route':
        return {
          'description': 'Check your bus route and scheduled stops.',
          'status': 'Route information is currently illustrative.',
        };
      case 'Attendance':
        return {
          'description': 'Review boarding and exit attendance details.',
          'status': 'Demo records are not saved to Firebase.',
        };
      case 'Notifications':
        return {
          'description': 'Review bus updates and journey alerts.',
          'status': 'Push notifications are not configured yet.',
        };
      case 'My Profile':
        return {
          'description': 'View your student profile information.',
          'status': 'Profile information is currently demo data.',
        };
      case 'Settings':
        return {
          'description': 'Manage your application preferences.',
          'status': 'Settings are not saved permanently yet.',
        };
      case 'Report Issue':
        return {
          'description': 'Review the issue-reporting feature.',
          'status': 'Issue reports are not sent to the transport office.',
        };
      default:
        return {
          'description': 'Explore your CollegeBus student portal.',
          'status': 'Prototype mode: backend services are not connected.',
        };
    }
  }

  List<String> _getItems(String screenTitle) {
    switch (screenTitle) {
      case 'Live Tracking':
        return [
          'Assigned Bus: BUS-01',
          'Current Location: Near Power House',
          'Estimated Arrival: 8 minutes',
          'Location Source: Simulated data',
        ];
      case 'My Route':
        return [
          'Satara MIDC',
          'Power House',
          'Karanje',
          'Your Stop',
          'YSPM College',
        ];
      case 'Attendance':
        return [
          'Expected Students: 40',
          'Boarded Students: 28',
          'Yet to Board: 12',
          'Attendance source: Demo data',
        ];
      case 'Notifications':
        return [
          'Bus-01 is delayed',
          'Previous attendance marked',
          'Bus-01 left Satara MIDC',
        ];
      case 'My Profile':
        return [
          'Student Name: Atharv Chorge',
          'Role: Student',
          'Assigned Bus: BUS-01',
          'College: Yashoda Technical Campus',
        ];
      case 'Settings':
        return [
          'Notification preferences',
          'Account preferences',
          'Application information',
        ];
      case 'Report Issue':
        return ['Bus delay', 'Route-related issue', 'Other transport issue'];
      default:
        return ['Bus information', 'Journey information', 'Student services'];
    }
  }
}
