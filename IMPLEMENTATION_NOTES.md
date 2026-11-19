# CampusBusAI 360 – Attendance and Parent Linking Update

## Included in this update
- Student registration creates a unique `STUXXXXXXXX` Student ID and a separate unique `CBUS-XXXXXXXX` Student Bus ID from the Firebase Auth UID. The Student Bus ID is displayed directly under the student name and in a copyable card.
- Optional College Roll Number is stored separately.
- Admin Students list includes an Assign Bus action; it writes the selected Firestore bus document ID to `users/{studentUid}.busId`.
- Parent registration accepts the student-specific Student Bus ID (not the shared vehicle bus document ID) and creates a pending `parent_link_requests` record. The Student Bus ID resolves to exactly one student through `student_bus_id_lookup`.
- Student Dashboard displays pending parent requests and allows Approve / Reject.
- After approval, the parent can read the linked student's profile and the Parent Dashboard displays that student.
- Driver Attendance tab loads the bus where `buses.driverId == currentDriverUid`, then loads only students with `users.busId == thatBusDocumentId`.
- Start Trip, Mark Boarded, Mark Dropped, and Complete Trip are Firestore-backed.
- Attendance document ID is deterministic (`{tripId}_{studentUid}`), and transaction checks prevent duplicate attendance for the same student in a trip.
- Complete Trip marks only currently-boarded students as dropped at the college final stop. Students not boarded are not changed.
- Admin Attendance / Attendance History page reads live Firestore attendance records.
- Firestore rules and composite indexes updated.

## Required data convention
- `buses/{busDocumentId}.driverId` must contain the assigned driver's Firebase Auth UID.
- `users/{studentUid}.busId` must contain the bus Firestore document ID, not just the displayed bus number.
- Student records should use `role: student`.

## Deploy Firestore configuration
From the project root, run:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Make sure the Firebase CLI is logged into the same project used by `lib/firebase_options.dart`.

## Important limitations / next work
- PDF and Excel file generation/export is not included in this package yet; the Admin page currently shows live records and history. Add the export layer as a separate next step after verifying the live data flow.
- This environment did not have Flutter/Dart installed, so `flutter analyze` and a browser run could not be performed here. Run `flutter pub get` and `flutter analyze` on the development machine before deploying.
- Driver trip IDs are one per bus per calendar day (`{busId}_YYYYMMDD`). If the bus runs multiple trips in one day, add a trip sequence or separate AM/PM trip selector.
- Parent approval and attendance are client-driven and protected by Firestore rules; for production, consider moving sensitive transitions to Cloud Functions for stronger server-side validation.

## Student Bus ID vs vehicle Bus ID
- `studentBusId` (format `CBUS-XXXXXXXX`) is a unique per-student code. Parent manually enters this code during registration to request linking to exactly one student.
- `busId` is the actual vehicle's Firestore document ID, assigned by Admin to the student. Multiple students can share this vehicle `busId`.
- The Student Bus ID is not the vehicle's Bus ID; this avoids linking a parent to every student travelling on the same bus.
