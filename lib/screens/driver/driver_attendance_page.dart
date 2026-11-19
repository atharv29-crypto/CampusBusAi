import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firestore-backed attendance for the bus assigned to the signed-in driver.
/// Attendance document ID is deterministic per trip/student to prevent duplicates.
class DriverAttendancePage extends StatefulWidget {
  const DriverAttendancePage({super.key});

  @override
  State<DriverAttendancePage> createState() => _DriverAttendancePageState();
}

class _DriverAttendancePageState extends State<DriverAttendancePage> {
  final _db = FirebaseFirestore.instance;
  final _stopController = TextEditingController();
  bool _working = false;

  String get _driverId => FirebaseAuth.instance.currentUser!.uid;
  String get _dateKey {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopController.dispose();
    super.dispose();
  }

  Future<void> _startTrip(String busId, Map<String, dynamic> bus) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final tripId = '${busId}_$_dateKey';
      final ref = _db.collection('trips').doc(tripId);
      await _db.runTransaction((tx) async {
        final existing = await tx.get(ref);
        if (existing.exists) {
          final status = existing.data()?['status'];
          if (status == 'inProgress') {
            throw Exception('This trip has already started.');
          }
          if (status == 'completed') {
            throw Exception('This trip has already been completed today.');
          }
        }
        tx.set(ref, {
          'busId': busId,
          'busNumber': bus['busNumber'] ?? '',
          'driverId': _driverId,
          'dateKey': _dateKey,
          'status': 'inProgress',
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      _toast('Trip started successfully.');
    } catch (e) {
      _toast(
        'Unable to start trip: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markBoarded({
    required String tripId,
    required String busId,
    required String busNumber,
    required String studentId,
    required Map<String, dynamic> student,
  }) async {
    if (_working) return;
    final stop = _stopController.text.trim().isNotEmpty
        ? _stopController.text.trim()
        : (student['pickupStop'] ?? student['stop'] ?? 'Not specified')
              .toString();
    final ref = _db.collection('attendance').doc('${tripId}_$studentId');
    setState(() => _working = true);
    try {
      await _db.runTransaction((tx) async {
        final tripRef = _db.collection('trips').doc(tripId);
        final trip = await tx.get(tripRef);
        if (!trip.exists || trip.data()?['status'] != 'inProgress') {
          throw Exception('Please start the trip before marking attendance.');
        }
        final old = await tx.get(ref);
        if (old.exists) {
          throw Exception(
            'Attendance has already been recorded for this student on this trip.',
          );
        }
        tx.set(ref, {
          'tripId': tripId,
          'studentId': studentId,
          'studentName': student['name'] ?? '',
          'studentCode': student['studentId'] ?? studentId,
          'busId': busId,
          'busNumber': busNumber,
          'driverId': _driverId,
          'dateKey': _dateKey,
          'boardingStop': stop,
          'boardedAt': FieldValue.serverTimestamp(),
          'droppedAt': null,
          'dropStop': null,
          'status': 'boarded',
          'boardingMethod': 'manual',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      _toast('${student['name'] ?? 'Student'} marked as boarded.');
    } catch (e) {
      _toast(
        'Unable to mark student as boarded: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _markDropped(String attendanceId, String stop) async {
    if (_working) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Student as Dropped?'),
        content: Text(
          'Confirm that the student has safely left the bus at $stop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _working = true);
    try {
      await _db.runTransaction((tx) async {
        final ref = _db.collection('attendance').doc(attendanceId);
        final current = await tx.get(ref);
        if (!current.exists || current.data()?['status'] != 'boarded') {
          throw Exception('This student is not currently marked as boarded.');
        }
        tx.update(ref, {
          'status': 'dropped',
          'dropStop': stop,
          'droppedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      _toast('Student marked as dropped successfully.');
    } catch (e) {
      _toast(
        'Unable to update drop status: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _completeTrip(String tripId, String busId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Trip?'),
        content: const Text(
          'All students currently marked as boarded will be marked as dropped at the final stop. Students who have not boarded will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete Trip'),
          ),
        ],
      ),
    );
    if (ok != true || _working) return;
    setState(() => _working = true);
    try {
      final tripRef = _db.collection('trips').doc(tripId);
      final records = await _db
          .collection('attendance')
          .where('tripId', isEqualTo: tripId)
          .where('driverId', isEqualTo: _driverId)
          .where('busId', isEqualTo: busId)
          .where('status', isEqualTo: 'boarded')
          .get();
      // Firestore allows a maximum of 500 writes per batch. Keep each
      // attendance batch below that limit, then mark the trip completed.
      for (var start = 0; start < records.docs.length; start += 450) {
        final batch = _db.batch();
        for (final doc in records.docs.skip(start).take(450)) {
          batch.update(doc.reference, {
            'status': 'dropped',
            'dropStop': 'College - Final Stop',
            'droppedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'dropMarkedByTripCompletion': true,
          });
        }
        await batch.commit();
      }
      await _db.runTransaction((tx) async {
        final currentTrip = await tx.get(tripRef);
        if (!currentTrip.exists ||
            currentTrip.data()?['status'] != 'inProgress') {
          throw Exception(
            'The trip is no longer active. Please refresh and check its status.',
          );
        }
        tx.update(tripRef, {
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      _toast(
        'Trip completed. ${records.docs.length} students marked as dropped.',
      );
    } catch (e) {
      _toast(
        'Unable to complete trip: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _toast(String message) {
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('buses')
          .where('driverId', isEqualTo: _driverId)
          .snapshots(),
      builder: (context, busSnapshot) {
        if (busSnapshot.hasError)
          return _message('Unable to load assigned bus: ${busSnapshot.error}');
        if (!busSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        if (busSnapshot.data!.docs.isEmpty)
          return _message(
            'No bus is assigned to your account yet. Please contact the Admin.',
          );
        final busDoc = busSnapshot.data!.docs.first;
        final bus = busDoc.data();
        final busId = busDoc.id;
        final busNumber = (bus['busNumber'] ?? busId).toString();
        final tripId = '${busId}_$_dateKey';
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _db.collection('trips').doc(tripId).snapshots(),
          builder: (context, tripSnapshot) {
            final trip = tripSnapshot.data?.data();
            final started = trip?['status'] == 'inProgress';
            final completed = trip?['status'] == 'completed';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Attendance • $busNumber',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        completed
                            ? 'Completed'
                            : started
                            ? 'Trip In Progress'
                            : 'Not Started',
                      ),
                      backgroundColor: completed
                          ? Colors.green.shade100
                          : started
                          ? Colors.orange.shade100
                          : Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _stopController,
                  decoration: const InputDecoration(
                    labelText: 'Current Stop (optional)',
                    hintText: 'e.g. Satara MIDC',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working || started || completed
                            ? null
                            : () => _startTrip(busId, bus),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Trip'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _working || !started
                            ? null
                            : () => _completeTrip(tripId, busId),
                        icon: const Icon(Icons.flag),
                        label: const Text('Complete Trip'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!started && !completed)
                  const Text('Please start the trip before taking attendance.'),
                if (started || completed) _attendanceStats(tripId, busId),
                const SizedBox(height: 14),
                const Text(
                  'Students Assigned to This Bus',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _db
                      .collection('users')
                      .where('role', isEqualTo: 'student')
                      .where('busId', isEqualTo: busId)
                      .snapshots(),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.hasError)
                      return _message(
                        'Unable to load students: ${studentSnapshot.error}',
                      );
                    if (!studentSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    if (studentSnapshot.data!.docs.isEmpty)
                      return _message('No students are assigned to this bus.');
                    return Column(
                      children: [
                        for (final studentDoc in studentSnapshot.data!.docs)
                          _studentTile(
                            studentDoc.id,
                            studentDoc.data(),
                            tripId,
                            busId,
                            busNumber,
                            started,
                            completed,
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _attendanceStats(String tripId, String busId) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('busId', isEqualTo: busId)
            .snapshots(),
        builder: (context, studentSnapshot) {
          final expected = studentSnapshot.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('attendance')
                .where('tripId', isEqualTo: tripId)
                .where('driverId', isEqualTo: _driverId)
                .where('busId', isEqualTo: busId)
                .snapshots(),
            builder: (context, attendanceSnapshot) {
              final docs = attendanceSnapshot.data?.docs ?? [];
              final boarded = docs
                  .where((d) => d.data()['status'] == 'boarded')
                  .length;
              final dropped = docs
                  .where((d) => d.data()['status'] == 'dropped')
                  .length;
              final waiting = (expected - boarded - dropped).clamp(0, expected);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _stat('Expected', '$expected', Colors.blue),
                  _stat('On Bus', '$boarded', Colors.green),
                  _stat('Dropped', '$dropped', Colors.teal),
                  _stat('Waiting', '$waiting', Colors.deepOrange),
                ],
              );
            },
          );
        },
      );

  Widget _stat(String label, String value, Color color) => Container(
    width: 130,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(.09),
      borderRadius: BorderRadius.circular(12),
    ),
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
        Text(label),
      ],
    ),
  );

  Widget _studentTile(
    String studentId,
    Map<String, dynamic> student,
    String tripId,
    String busId,
    String busNumber,
    bool started,
    bool completed,
  ) {
    final attendanceId = '${tripId}_$studentId';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _db.collection('attendance').doc(attendanceId).snapshots(),
      builder: (context, attendanceSnapshot) {
        final attendance = attendanceSnapshot.data?.data();
        final status = attendance?['status']?.toString() ?? 'notBoarded';
        final name = (student['name'] ?? 'Student').toString();
        final stop =
            (student['pickupStop'] ?? student['stop'] ?? 'Stop not set')
                .toString();
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S'),
            ),
            title: Text(name),
            subtitle: Text(
              '${student['studentId'] ?? studentId} • $stop\nStatus: ${status == 'notBoarded' ? 'Not Boarded' : status}',
            ),
            isThreeLine: true,
            trailing: status == 'dropped'
                ? const Icon(Icons.check_circle, color: Colors.green)
                : status == 'boarded'
                ? TextButton(
                    onPressed: _working || completed
                        ? null
                        : () => _markDropped(
                            attendanceId,
                            _stopController.text.trim().isEmpty
                                ? 'College / Current Stop'
                                : _stopController.text.trim(),
                          ),
                    child: const Text('Mark Dropped'),
                  )
                : FilledButton.tonal(
                    onPressed: _working || !started || completed
                        ? null
                        : () => _markBoarded(
                            tripId: tripId,
                            busId: busId,
                            busNumber: busNumber,
                            studentId: studentId,
                            student: student,
                          ),
                    child: const Text('Mark Boarded'),
                  ),
          ),
        );
      },
    );
  }

  Widget _message(String message) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
