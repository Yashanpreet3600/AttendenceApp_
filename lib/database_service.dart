import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================================================
  // 1. GENERAL & PROFILE
  // ==================================================

  Future<Map<String, dynamic>> getUserProfile() async {
    User? user = _auth.currentUser;
    if (user == null) return {};
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return {};
  }

  // ==================================================
  // 2. STUDENT: ACADEMICS
  // ==================================================

  Future<List<String>> getClassSubjects(String className) async {
    try {
      DocumentSnapshot doc = await _db.collection('classes').doc(className).get();
      if (doc.exists && doc.data() != null) {
        return List<String>.from(doc['subjects']);
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats(String className, String subject) async {
    User? user = _auth.currentUser;
    if (user == null) return {'total': 0, 'attended': 0, 'percentage': 0.0};
    String uid = user.uid;

    try {
      QuerySnapshot snapshot = await _db.collection('attendance')
          .where('classId', isEqualTo: className)
          .where('subject', isEqualTo: subject)
          .get();

      int totalLectures = snapshot.docs.length;
      int attended = 0;

      for (var doc in snapshot.docs) {
        Map<String, dynamic> records = doc['records'] as Map<String, dynamic>;
        if (records.containsKey(uid) && records[uid] == 'P') {
          attended++;
        }
      }
      return {
        'total': totalLectures,
        'attended': attended,
        'percentage': totalLectures == 0 ? 0.0 : (attended / totalLectures),
      };
    } catch (e) {
      return {'total': 0, 'attended': 0, 'percentage': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> getAttendanceHistory(String className, String subject) async {
    try {
      QuerySnapshot snapshot = await _db.collection('attendance')
          .where('classId', isEqualTo: className)
          .where('subject', isEqualTo: subject)
          .orderBy('timestamp', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStudentMarks(String className, String subject) async {
    User? user = _auth.currentUser;
    if (user == null) return [];
    String myUid = user.uid;

    try {
      QuerySnapshot snapshot = await _db.collection('marks')
          .where('classId', isEqualTo: className)
          .where('subject', isEqualTo: subject)
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> myResults = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> scores = data['scores'] ?? {};
        if (scores.keys.any((k) => k.toString() == myUid)) {
          var key = scores.keys.firstWhere((k) => k.toString() == myUid);
          myResults.add({
            'testName': data['testName'],
            'totalMarks': data['totalMarks'],
            'myScore': scores[key],
          });
        }
      }
      return myResults;
    } catch (e) {
      return [];
    }
  }

  // ==================================================
  // 3. FACULTY: CLASS MANAGEMENT
  // ==================================================

  Future<List<Map<String, dynamic>>> getStudentsByClass(String className) async {
    try {
      QuerySnapshot snapshot = await _db.collection('users')
          .where('role', isEqualTo: 'Student')
          .where('class', isEqualTo: className)
          .get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> submitAttendance({
    required String className,
    required String subject,
    required String date,
    required Map<String, String> attendanceMap,
  }) async {
    User? faculty = _auth.currentUser;
    await _db.collection('attendance').add({
      'date': date,
      'classId': className,
      'subject': subject,
      'facultyId': faculty?.uid ?? "Unknown",
      'timestamp': FieldValue.serverTimestamp(),
      'records': attendanceMap,
    });
  }

  Future<void> submitTestScores({
    required String className,
    required String subject,
    required String testName,
    required double totalMarks,
    required Map<String, double> scores,
  }) async {
    await _db.collection('marks').add({
      'testName': testName,
      'classId': className,
      'subject': subject,
      'totalMarks': totalMarks,
      'scores': scores,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ==================================================
  // 4. LEAVE SYSTEM (ADVANCED)
  // ==================================================

  // Upload Image Logic
  Future<String?> uploadLeaveAttachment(File imageFile) async {
    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      // Save in 'leave_attachments' folder in storage
      Reference ref = _storage.ref().child('leave_attachments').child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllFaculty() async {
    try {
      QuerySnapshot snapshot = await _db.collection('users')
          .where('role', isEqualTo: 'Faculty')
          .get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> applyLeave({
    required String reason,
    required String facultyUid,
    required String studentName,
    required String className,
    String? attachmentUrl, // Optional Image URL
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('leaves').add({
      'applicantUid': user.uid,
      'name': studentName,
      'classId': className,
      'reason': reason,
      'facultyUid': facultyUid,
      'status': 'Pending',
      'attachment': attachmentUrl ?? "", // Save URL or empty string
      'facultyRemark': "", // Start empty
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMyLeaves() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('leaves')
        .where('applicantUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getIncomingLeaves() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db.collection('leaves')
        .where('facultyUid', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Update Status AND Add Remark
  Future<void> updateLeaveStatus(String docId, String newStatus, String remark) async {
    await _db.collection('leaves').doc(docId).update({
      'status': newStatus,
      'facultyRemark': remark,
    });
  }
}