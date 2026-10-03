import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'main.dart'; // For LoginScreen
import 'apply_leave.dart'; // Import the leave screen

class StudentDashboard extends StatefulWidget {
  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final DatabaseService _db = DatabaseService();

  String studentName = "Loading...";
  String universityId = "";
  String className = "";
  String selectedSubject = "";
  List<String> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  void _loadStudentData() async {
    var profile = await _db.getUserProfile();
    if (mounted) {
      setState(() {
        studentName = profile['name'] ?? "Student";
        universityId = profile['uid'] ?? "N/A";
        className = profile['class'] ?? "";
      });

      if (className.isNotEmpty) {
        var subs = await _db.getClassSubjects(className);
        setState(() {
          subjects = subs;
          if (subs.isNotEmpty) selectedSubject = subs[0];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF002046),
        foregroundColor: Colors.white,
      ),
      drawer: _buildSideBar(context),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            const Text("Academic Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (subjects.isEmpty)
              Card(child: Padding(padding: EdgeInsets.all(16), child: Text("No subjects found for class '$className'.")))
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSubject,
                    isExpanded: true,
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => selectedSubject = val!),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // ATTENDANCE CARD
            if (selectedSubject.isNotEmpty)
              FutureBuilder<Map<String, dynamic>>(
                future: _db.getAttendanceStats(className, selectedSubject),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: LinearProgressIndicator());
                  var data = snapshot.data ?? {'percentage': 0.0, 'attended': 0, 'total': 0};
                  double pct = data['percentage'];
                  bool isLow = pct < 0.75;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (_) => StudentHistoryScreen(className: className, subject: selectedSubject)
                      ));
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedSubject, style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 100, width: 100,
                                  child: CircularProgressIndicator(
                                    value: pct, strokeWidth: 10,
                                    backgroundColor: Colors.grey[200],
                                    color: isLow ? Colors.red : Colors.green,
                                  ),
                                ),
                                Text("${(pct * 100).toInt()}%", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text("Attended: ${data['attended']} / ${data['total']}", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 15),

            // MARKS BUTTON
            if (selectedSubject.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.assignment),
                  label: Text("View Test Scores"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 15)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                        builder: (_) => StudentMarksScreen(className: className, subject: selectedSubject)
                    ));
                  },
                ),
              ),

            const SizedBox(height: 15),

            // APPLY LEAVE BUTTON (NEW)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.mail_outline),
                label: Text("Apply for Leave"),
                style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: Color(0xFF002046)),
                    foregroundColor: Color(0xFF002046)
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ApplyLeaveScreen(studentName: studentName, className: className)
                  ));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: const Color(0xFF002046),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 30,
          child: Text(studentName.isNotEmpty ? studentName[0] : "S", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF002046))),
        ),
        title: Text("Hello, $studentName", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text("ID: $universityId\nClass: $className", style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildSideBar(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: const Color(0xFF002046)),
            accountName: Text(studentName),
            accountEmail: Text(universityId),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFF002046))),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginScreen()), (route) => false);
            },
          )
        ],
      ),
    );
  }
}

// --- HISTORY SUB-SCREEN ---
class StudentHistoryScreen extends StatelessWidget {
  final String className;
  final String subject;
  StudentHistoryScreen({required this.className, required this.subject});
  final DatabaseService _db = DatabaseService();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$subject History"), backgroundColor: Color(0xFF002046), foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getAttendanceHistory(className, subject),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No records found"));
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) {
              var log = snapshot.data![i];
              String status = (log['records'] ?? {})[myUid] ?? "NA";
              bool isP = status == "P";
              return ListTile(
                title: Text("Date: ${log['date']}"),
                trailing: Chip(label: Text(isP ? "Present" : "Absent", style: TextStyle(color: Colors.white)), backgroundColor: isP ? Colors.green : Colors.red),
              );
            },
          );
        },
      ),
    );
  }
}

// --- MARKS SUB-SCREEN ---
class StudentMarksScreen extends StatelessWidget {
  final String className;
  final String subject;
  StudentMarksScreen({required this.className, required this.subject});
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$subject Marks"), backgroundColor: Color(0xFF002046), foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getStudentMarks(className, subject),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (snapshot.data!.isEmpty) return Center(child: Text("No marks uploaded yet."));
          return ListView.builder(
            itemCount: snapshot.data!.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var test = snapshot.data![index];
              double myScore = double.tryParse(test['myScore'].toString()) ?? 0;
              double total = double.tryParse(test['totalMarks'].toString()) ?? 20;
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 15),
                child: ListTile(
                  title: Text(test['testName'], style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text("$myScore / $total", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                ),
              );
            },
          );
        },
      ),
    );
  }
}