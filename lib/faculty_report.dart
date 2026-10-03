import 'package:flutter/material.dart';
import 'database_service.dart';

class FacultyReportScreen extends StatefulWidget {
  final String className;
  final String subject;

  const FacultyReportScreen({super.key, required this.className, required this.subject});

  @override
  State<FacultyReportScreen> createState() => _FacultyReportScreenState();
}

class _FacultyReportScreenState extends State<FacultyReportScreen> {
  final DatabaseService _db = DatabaseService();
  bool isLoading = true;
  List<Map<String, dynamic>> reportData = [];

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  void _generateReport() async {
    // 1. Get all Students in the class
    var students = await _db.getStudentsByClass(widget.className);

    // 2. Get all Attendance Logs for this subject
    var logs = await _db.getAttendanceHistory(widget.className, widget.subject);

    int totalLectures = logs.length;
    List<Map<String, dynamic>> calculatedData = [];

    // 3. Calculate for each student
    for (var student in students) {
      String uid = student['uid'];
      String name = student['name'];
      String roll = student['uid']; // Or rollNo if you have it

      int attended = 0;

      for (var log in logs) {
        Map records = log['records'];
        if (records.containsKey(uid) && records[uid] == 'P') {
          attended++;
        }
      }

      double percentage = totalLectures == 0 ? 0 : (attended / totalLectures);

      calculatedData.add({
        'name': name,
        'roll': roll,
        'attended': attended,
        'total': totalLectures,
        'percentage': percentage,
      });
    }

    if (mounted) {
      setState(() {
        reportData = calculatedData;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report: ${widget.subject}"),
        backgroundColor: const Color(0xFF002046),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Text("Total Lectures Delivered: ${reportData.isNotEmpty ? reportData[0]['total'] : 0}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: ListView.separated(
              separatorBuilder: (c, i) => const Divider(),
              itemCount: reportData.length,
              itemBuilder: (context, index) {
                var data = reportData[index];
                double pct = data['percentage'];
                bool isShort = pct < 0.75;

                return ListTile(
                  title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ID: ${data['roll']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${data['attended']}/${data['total']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${(pct*100).toInt()}%", style: TextStyle(
                              color: isShort ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold
                          )),
                        ],
                      ),
                      const SizedBox(width: 10),
                      if (isShort) const Icon(Icons.warning, color: Colors.red, size: 20)
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}