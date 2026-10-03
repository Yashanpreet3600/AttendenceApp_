import 'package:flutter/material.dart';
import 'database_service.dart'; // Import service

class MarkAttendanceScreen extends StatefulWidget {
  final String className; // e.g., "BTech1 - Artificial Intelligence"

  const MarkAttendanceScreen({super.key, required this.className});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final DatabaseService _db = DatabaseService();

  // State
  bool isLoading = true;
  List<Map<String, dynamic>> students = [];
  Map<String, String> attendanceStatus = {}; // Stores UID -> "P" or "A"
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    // Parse "BTech1 - SubjectName" to get just "BTech1"
    String actualClass = widget.className.split(' - ')[0].trim();

    var list = await _db.getStudentsByClass(actualClass);

    setState(() {
      students = list;
      // Default everyone to "Present" (P) initially
      for (var s in list) {
        String uid = s['uid']; // This is the Document ID (like 'yYhR...') or the 'uid' field
        attendanceStatus[uid] = "P";
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Parse subject name for display
    String subject = widget.className.contains('-')
        ? widget.className.split('-')[1].trim()
        : "General";

    return Scaffold(
      appBar: AppBar(
        title: Text("Mark Attendance"),
        backgroundColor: const Color(0xFF002046),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. DATE PICKER BAR
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Subject: $subject", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // 2. STUDENT LIST
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? Center(child: Text("No students found in this class."))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                var student = students[index];
                // Use the name and ID from database
                String name = student['name'] ?? "Unknown";
                String roll = student['uid'] ?? "No ID"; // Using your 'uid' field (Roll No)
                String docId = student['uid']; // The Firestore Doc ID or unique key

                bool isPresent = attendanceStatus[docId] == "P";

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPresent ? Colors.green : Colors.red,
                      child: Text(name[0], style: TextStyle(color: Colors.white)),
                    ),
                    title: Text(name),
                    subtitle: Text("ID: $roll"),
                    trailing: Switch(
                      value: isPresent,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      inactiveTrackColor: Colors.red[100],
                      onChanged: (val) {
                        setState(() {
                          attendanceStatus[docId] = val ? "P" : "A";
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. SUBMIT BUTTON
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002046),
                  padding: EdgeInsets.symmetric(vertical: 15)
              ),
              child: Text("UPLOAD ATTENDANCE", style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: _submitData,
            ),
          )
        ],
      ),
    );
  }

  void _submitData() async {
    setState(() => isLoading = true);

    // Split "BTech1 - AI" into parts
    String actualClass = widget.className.split(' - ')[0].trim();
    String subject = widget.className.contains('-') ? widget.className.split('-')[1].trim() : "General";

    // Use format DD-MM-YYYY
    String dateStr = "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}";

    await _db.submitAttendance(
      className: actualClass,
      subject: subject,
      date: dateStr,
      attendanceMap: attendanceStatus,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Attendance Uploaded!"), backgroundColor: Colors.green));
      Navigator.pop(context); // Go back
    }
  }
}