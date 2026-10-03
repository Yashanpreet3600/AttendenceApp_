import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'main.dart';
import 'attendance.dart';
import 'mark_test_screen.dart';
import 'leave_approvals.dart'; // Ensure this is imported

class FacultyDashboard extends StatefulWidget {
  const FacultyDashboard({super.key});
  @override
  State<FacultyDashboard> createState() => _FacultyDashboardState();
}

class _FacultyDashboardState extends State<FacultyDashboard> {
  final DatabaseService _db = DatabaseService();
  String facultyName = "Loading...";
  String facultyUid = "";
  List<String> myClasses = ['BTech1'];
  String selectedClass = 'BTech1';
  String selectedSubject = "Loading...";
  List<String> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacultyProfile();
    _loadSubjects();
  }

  void _loadFacultyProfile() async {
    var profile = await _db.getUserProfile();
    if(mounted) {
      setState(() {
        facultyName = profile['name'] ?? "Faculty";
        facultyUid = FirebaseAuth.instance.currentUser?.uid ?? "";
      });
    }
  }

  void _loadSubjects() async {
    setState(() => isLoading = true);
    var subs = await _db.getClassSubjects(selectedClass);
    if (mounted) {
      setState(() {
        subjects = subs;
        if (subs.isNotEmpty) selectedSubject = subs[0];
        else selectedSubject = "No Subjects";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Faculty Dashboard'), backgroundColor: const Color(0xFF002046), foregroundColor: Colors.white),
      drawer: _buildSideBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: const Color(0xFF002046), child: Text(facultyName.isNotEmpty ? facultyName[0] : "F", style: const TextStyle(color: Colors.white))),
              title: Text("Welcome, $facultyName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text("Faculty ID: $facultyUid"),
            ),
            const Divider(),
            const SizedBox(height: 10),

            const Text("Select Class:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: selectedClass,
              isExpanded: true,
              onChanged: (val) { setState(() => selectedClass = val!); _loadSubjects(); },
              items: myClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            ),

            const SizedBox(height: 10),
            const Text("Select Subject:", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: subjects.contains(selectedSubject) ? selectedSubject : null,
              hint: const Text("Loading..."),
              isExpanded: true,
              onChanged: (val) => setState(() => selectedSubject = val!),
              items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),

            const SizedBox(height: 30),

            // ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: _actionButton(context, Icons.check_circle_outline, "Mark\nAttendance", const Color(0xFF002046), () {
                    if(subjects.isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MarkAttendanceScreen(className: "$selectedClass - $selectedSubject")));
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(context, Icons.assignment_outlined, "Upload\nMarks", Colors.teal, () {
                    if(subjects.isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MarkTestScreen(className: "$selectedClass - $selectedSubject")));
                  }),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                // LEAVE REQUESTS BUTTON
                Expanded(
                  child: _actionButton(context, Icons.notification_important, "Leave\nRequests", Colors.orange[800]!, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveApprovalsScreen()));
                  }),
                ),
                const SizedBox(width: 10),
                // REPORT BUTTON
                Expanded(
                  child: _actionButton(context, Icons.bar_chart, "View\nReports", Colors.blue[800]!, () {
                    if(subjects.isEmpty) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FacultyReportScreen(className: selectedClass, subject: selectedSubject)));
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: const Color(0xFF002046)),
            accountName: Text(facultyName),
            accountEmail: Text(facultyUid),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF002046))),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// --- SUB-SCREEN: REPORT ---
class FacultyReportScreen extends StatefulWidget {
  final String className;
  final String subject;
  const FacultyReportScreen({required this.className, required this.subject});
  @override
  State<FacultyReportScreen> createState() => _FacultyReportScreenState();
}

class _FacultyReportScreenState extends State<FacultyReportScreen> {
  final DatabaseService _db = DatabaseService();
  bool isLoading = true;
  List<Map<String, dynamic>> report = [];

  @override
  void initState() {
    super.initState();
    _genReport();
  }

  void _genReport() async {
    var students = await _db.getStudentsByClass(widget.className);
    var logs = await _db.getAttendanceHistory(widget.className, widget.subject);
    List<Map<String, dynamic>> temp = [];

    for (var s in students) {
      String uid = s['uid'];
      int presentCount = 0;
      for (var log in logs) {
        if ((log['records'] ?? {})[uid] == 'P') presentCount++;
      }
      temp.add({
        'name': s['name'],
        'roll': s['uid'],
        'attended': presentCount,
        'total': logs.length,
        'pct': logs.isEmpty ? 0.0 : presentCount / logs.length
      });
    }
    setState(() { report = temp; isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report: ${widget.subject}"), backgroundColor: const Color(0xFF002046), foregroundColor: Colors.white),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : ListView.separated(
        itemCount: report.length,
        separatorBuilder: (c,i) => const Divider(),
        itemBuilder: (c, i) {
          var item = report[i];
          double pct = item['pct'];
          return ListTile(
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${item['roll']}"),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${item['attended']}/${item['total']}"),
                Text("${(pct*100).toInt()}%", style: TextStyle(color: pct < 0.75 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))
              ],
            ),
          );
        },
      ),
    );
  }
}