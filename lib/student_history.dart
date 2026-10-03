import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';

class StudentHistoryScreen extends StatefulWidget {
  final String className;
  final String subject;

  const StudentHistoryScreen({super.key, required this.className, required this.subject});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  final DatabaseService _db = DatabaseService();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} History"),
        backgroundColor: const Color(0xFF002046),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getAttendanceHistory(widget.className, widget.subject),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          var logs = snapshot.data!;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index];
              String date = log['date'] ?? "Unknown Date";
              Map records = log['records'] ?? {};

              // Check status for THIS student
              String status = records[myUid] ?? "Not Marked";
              bool isPresent = status == "P";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: const Color(0xFF002046),
                  ),
                  title: Text("Date: $date", style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isPresent ? Colors.green : Colors.red)
                    ),
                    child: Text(
                      isPresent ? "Present" : "Absent",
                      style: TextStyle(
                        color: isPresent ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}