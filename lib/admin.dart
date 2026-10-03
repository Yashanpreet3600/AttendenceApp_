import 'package:flutter/material.dart';

// ==========================================
// 1. DATA MODELS
// ==========================================

// Mock Data for Classes
List<Map<String, dynamic>> allClasses = [
  {
    'className': 'CS - Year 1 (Sec A)',
    'dept': 'Computer Science',
    'studentCount': 54,
    'room': 'B-101',
    'teacher': 'Prof. Anjali',
    'attendanceAvg': 0.85,
    'testScores': [
      {'date': '20 Nov', 'topic': 'Java Basics', 'avg': 78, 'total': 100},
      {'date': '13 Nov', 'topic': 'OOPs Concept', 'avg': 65, 'total': 100},
    ]
  },
  {
    'className': 'CS - Year 3 (Sec B)',
    'dept': 'Computer Science',
    'studentCount': 45,
    'room': 'C-202',
    'teacher': 'Dr. Sharma',
    'attendanceAvg': 0.91,
    'testScores': []
  },
  {
    'className': 'ME - Year 1',
    'dept': 'Mechanical Eng',
    'studentCount': 60,
    'room': 'LAB-1',
    'teacher': 'Mr. Rahul',
    'attendanceAvg': 0.65,
    'testScores': [
      {'date': '18 Nov', 'topic': 'Thermodynamics', 'avg': 55, 'total': 100},
    ]
  },
];

// Mock Data for Faculty
List<Map<String, dynamic>> allFaculty = [
  {
    'name': 'Dr. Sharma',
    'dept': 'Computer Science',
    'role': 'HOD',
    'subjects': [
      {'name': 'Data Structures', 'class': 'CS - Year 3 (Sec B)', 'dept': 'Computer Science'},
      {'name': 'AI Basics', 'class': 'CS - Year 3 (Sec B)', 'dept': 'Computer Science'}
    ]
  },
  {
    'name': 'Prof. Anjali',
    'dept': 'Computer Science',
    'role': 'Assistant Prof',
    'subjects': [
      {'name': 'Java', 'class': 'CS - Year 1 (Sec A)', 'dept': 'Computer Science'},
      {'name': 'Web Dev', 'class': 'CS - Year 3 (Sec B)', 'dept': 'Computer Science'}
    ]
  },
  {
    'name': 'Mr. Rahul',
    'dept': 'Mechanical Eng',
    'role': 'Lab Assistant',
    'subjects': [
      {'name': 'Thermodynamics', 'class': 'ME - Year 1', 'dept': 'Mechanical Eng'}
    ]
  },
];

// Mock Data for Students
Map<String, List<String>> mockStudents = {
  'CS - Year 1 (Sec A)': ['Amit Kumar', 'Priya Singh', 'Rohan Das'],
  'CS - Year 3 (Sec B)': ['Vikram R', 'Sneha G', 'Arun K'],
  'ME - Year 1': ['John Doe', 'Mike Ross'],
};

// Timetable Data
Map<String, List<Map<String, String>>> timetableData = {
  'CS - Year 1 (Sec A)': [
    {'time': '09:00 AM', 'title': 'Java', 'sub': 'Prof. Anjali (Room B-101)'},
    {'time': '10:00 AM', 'title': 'Maths', 'sub': 'Dr. X (Room B-102)'},
  ],
  'Prof. Anjali': [
    {'time': '09:00 AM', 'title': 'Java', 'sub': 'CS - Year 1 (Sec A)'},
  ]
};

// ==========================================
// 2. MAIN APP & LOGIN (FIXED)
// ==========================================
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    // ENSURE THIS SAYS LoginPage(), NOT AdminDashboard()
    home: LoginPage(),
  ));
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.school, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("College Admin Portal", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              // THIS BUTTON TAKES YOU TO THE DASHBOARD
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard())),
              icon: const Icon(Icons.login),
              label: const Text("ENTER DASHBOARD"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. MAIN DASHBOARD
// ==========================================
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  String selectedDepartment = 'Computer Science';
  final List<String> departments = ['Computer Science', 'Mechanical Eng', 'Civil Eng', 'Commerce'];

  int _sideBarIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    String title;

    switch (_sideBarIndex) {
      case 1:
        bodyContent = const HierarchicalTimetablePage();
        title = "Timetable Manager";
        break;
      case 2:
        bodyContent = const AdvancedBroadcastPage();
        title = "Broadcast & Messages";
        break;
      case 0:
      default:
        bodyContent = _buildDashboardTabs();
        title = "Admin Console";
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(title),
        elevation: 0,
        // ADDED LOGOUT BUTTON IN APP BAR
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
          )
        ],
        bottom: _sideBarIndex == 0
            ? PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDepartment,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
                    isExpanded: true,
                    items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)))).toList(),
                    onChanged: (val) => setState(() => selectedDepartment = val!),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 4,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [Tab(text: "FACULTY", icon: Icon(Icons.people)), Tab(text: "CLASSES", icon: Icon(Icons.class_outlined))],
              ),
            ],
          ),
        )
            : null,
      ),
      drawer: _buildDrawer(),
      body: bodyContent,
    );
  }

  // ===============================================
  // 4. DASHBOARD TABS (HOME)
  // ===============================================
  Widget _buildDashboardTabs() {
    final facultyList = allFaculty.where((e) => e['dept'] == selectedDepartment).toList();
    final classList = allClasses.where((e) => e['dept'] == selectedDepartment).toList();

    return TabBarView(
      controller: _tabController,
      children: [
        // --- TAB 1: FACULTY ---
        ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: facultyList.length,
          itemBuilder: (ctx, i) {
            final f = facultyList[i];
            List<dynamic> subjects = f['subjects'];
            return Card(
              elevation: 2,
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: Colors.indigo.shade50, child: Text(f['name'][0])),
                title: Text(f['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(f['role']),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Assigned Subjects:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: subjects.map((sub) {
                            return Chip(
                              label: Text("${sub['name']}\n(${sub['class']})"),
                              backgroundColor: Colors.indigo.shade50,
                              labelStyle: TextStyle(color: Colors.indigo[900], fontSize: 12),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showSubjectManager(f),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text("Manage Subjects"),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),

        // --- TAB 2: CLASSES (WITH MONDAY TEST PERFORMANCE) ---
        ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: classList.length,
          itemBuilder: (ctx, i) {
            final c = classList[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              child: Column(
                children: [
                  ListTile(
                    title: Text(c['className'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text("${c['teacher']} • Room ${c['room']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                      child: Text("${(c['attendanceAvg'] * 100).toInt()}% Att.", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const Divider(height: 0),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.insights),
                        label: const Text("MONDAY TEST PERFORMANCE"),
                        onPressed: () => _openMondayTestDashboard(c),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ===============================================
  // 5. MONDAY TEST DASHBOARD LOGIC
  // ===============================================
  void _openMondayTestDashboard(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            List<dynamic> scores = c['testScores'];

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Performance Report", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(c['className'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showAddTestDialog(context, c, setStateSheet);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("ADD NEW TEST RESULT"),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // List of Tests
                  Expanded(
                    child: scores.isEmpty
                        ? const Center(child: Text("No tests conducted yet.", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                      itemCount: scores.length,
                      itemBuilder: (ctx, i) {
                        final test = scores[i];
                        double percentage = (test['avg'] / test['total']);
                        Color color = percentage >= 0.75 ? Colors.green : (percentage >= 0.5 ? Colors.orange : Colors.red);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              // Circular Score
                              Container(
                                width: 50, height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 2),
                                ),
                                child: Text("${test['avg']}", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                              ),
                              const SizedBox(width: 15),
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(test['topic'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("Date: ${test['date']} • Max: ${test['total']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(value: percentage, color: color, backgroundColor: Colors.grey.shade200, minHeight: 6),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddTestDialog(BuildContext context, Map<String, dynamic> c, StateSetter setStateSheet) {
    TextEditingController topicCtrl = TextEditingController();
    TextEditingController avgCtrl = TextEditingController();
    TextEditingController totalCtrl = TextEditingController(text: "100");
    TextEditingController dateCtrl = TextEditingController(text: "Today");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Monday Test"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: "Test Topic")),
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: "Date")),
              Row(
                children: [
                  Expanded(child: TextField(controller: avgCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Class Avg"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Total Marks"))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
            onPressed: () {
              if (topicCtrl.text.isNotEmpty && avgCtrl.text.isNotEmpty) {
                setStateSheet(() {
                  c['testScores'].insert(0, {
                    'date': dateCtrl.text,
                    'topic': topicCtrl.text,
                    'avg': double.tryParse(avgCtrl.text) ?? 0,
                    'total': double.tryParse(totalCtrl.text) ?? 100
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save Result"),
          )
        ],
      ),
    );
  }

  // ===============================================
  // 6. SUBJECT MANAGER
  // ===============================================
  void _showSubjectManager(Map<String, dynamic> faculty) {
    TextEditingController subjectNameCtrl = TextEditingController();
    TextEditingController classNameCtrl = TextEditingController();
    String editDept = faculty['dept'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            List<dynamic> currentSubjects = faculty['subjects'];
            return AlertDialog(
              title: Text("Manage ${faculty['name']}'s Subjects"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (currentSubjects.isEmpty) const Text("No subjects assigned.", style: TextStyle(fontStyle: FontStyle.italic)),
                      ...currentSubjects.map((sub) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text("${sub['class']} • ${sub['dept']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () { setStateDialog(() { currentSubjects.remove(sub); }); setState(() {}); })
                            ],
                          ),
                        );
                      }).toList(),
                      const Divider(height: 30),
                      const Text("Add New Assignment:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      TextField(controller: subjectNameCtrl, decoration: const InputDecoration(labelText: "Subject Name", isDense: true)),
                      TextField(controller: classNameCtrl, decoration: const InputDecoration(labelText: "Class (e.g. CS Yr 1)", isDense: true)),
                      DropdownButtonFormField<String>(
                        value: editDept,
                        decoration: const InputDecoration(labelText: "Department", isDense: true),
                        items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (val) => setStateDialog(() => editDept = val!),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (subjectNameCtrl.text.isNotEmpty && classNameCtrl.text.isNotEmpty) {
                              setStateDialog(() {
                                faculty['subjects'].add({'name': subjectNameCtrl.text, 'class': classNameCtrl.text, 'dept': editDept});
                                subjectNameCtrl.clear();
                                classNameCtrl.clear();
                              });
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.add), label: const Text("Assign Subject"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            accountName: Text("Admin Console"),
            accountEmail: Text("admin@college.edu"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.school, color: Colors.indigo)),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text("Dashboard"), selected: _sideBarIndex == 0, onTap: () { setState(() => _sideBarIndex = 0); Navigator.pop(context); }),
          ListTile(leading: const Icon(Icons.calendar_today), title: const Text("Timetables"), selected: _sideBarIndex == 1, onTap: () { setState(() => _sideBarIndex = 1); Navigator.pop(context); }),
          ListTile(leading: const Icon(Icons.campaign), title: const Text("Broadcast / Message"), selected: _sideBarIndex == 2, onTap: () { setState(() => _sideBarIndex = 2); Navigator.pop(context); }),
          const Divider(),
          // DRAWER LOGOUT BUTTON
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("Logout", style: TextStyle(color: Colors.red)), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
        ],
      ),
    );
  }
}

// ==========================================
// 7. HIERARCHICAL TIMETABLE PAGE
// ==========================================
class HierarchicalTimetablePage extends StatefulWidget {
  const HierarchicalTimetablePage({super.key});

  @override
  State<HierarchicalTimetablePage> createState() => _HierarchicalTimetablePageState();
}

class _HierarchicalTimetablePageState extends State<HierarchicalTimetablePage> {
  String? selectedDept;
  final List<String> departments = ['Computer Science', 'Mechanical Eng', 'Civil Eng', 'Commerce'];
  String? selectedRole;
  String? selectedEntityName;

  List<String> getAvailableNames() {
    if (selectedDept == null || selectedRole == null) return [];
    if (selectedRole == 'Faculty') {
      return allFaculty.where((f) => f['dept'] == selectedDept).map((f) => f['name'] as String).toList();
    } else {
      return allClasses.where((c) => c['dept'] == selectedDept).map((c) => c['className'] as String).toList();
    }
  }

  List<Map<String, String>> getCurrentSchedule() {
    if (selectedEntityName == null) return [];
    return timetableData[selectedEntityName] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterLabel("1. Select Department"),
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  decoration: _inputDeco(),
                  items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() { selectedDept = val; selectedRole = null; selectedEntityName = null; }),
                ),
                if (selectedDept != null) ...[
                  const SizedBox(height: 10),
                  _buildFilterLabel("2. Select Role"),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: _inputDeco(),
                    items: const [DropdownMenuItem(value: 'Faculty', child: Text("Faculty (Assign Time)")), DropdownMenuItem(value: 'Students', child: Text("Students (View Class Time)"))],
                    onChanged: (val) => setState(() { selectedRole = val; selectedEntityName = null; }),
                  ),
                ],
                if (selectedRole != null) ...[
                  const SizedBox(height: 10),
                  _buildFilterLabel(selectedRole == 'Faculty' ? "3. Select Professor" : "3. Select Class"),
                  DropdownButtonFormField<String>(
                    value: selectedEntityName,
                    decoration: _inputDeco(),
                    items: getAvailableNames().map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                    onChanged: (val) => setState(() => selectedEntityName = val),
                  ),
                ]
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: selectedEntityName == null
                ? Center(child: Text("Select filters to view timetable", style: TextStyle(color: Colors.grey[600])))
                : _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: (selectedRole == 'Faculty' && selectedEntityName != null)
          ? FloatingActionButton.extended(
        onPressed: _showAssignTimeDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_alarm),
        label: const Text("Add Slot"),
      )
          : null,
    );
  }

  Widget _buildFilterLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)));

  Widget _buildScheduleList() {
    final schedule = getCurrentSchedule();
    if (schedule.isEmpty) return Center(child: Text("No schedule found for $selectedEntityName"));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      itemBuilder: (ctx, i) {
        final item = schedule[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(5)), child: Text(item['time']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo))),
            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['sub']!),
            trailing: selectedRole == 'Faculty' ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => schedule.removeAt(i))) : null,
          ),
        );
      },
    );
  }

  void _showAssignTimeDialog() {
    final timeCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final detailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Add Slot for $selectedEntityName"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: "Time")), TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: "Subject")), TextField(controller: detailCtrl, decoration: const InputDecoration(labelText: "Class / Room Detail"))]),
        actions: [ElevatedButton(onPressed: () { setState(() { if (!timetableData.containsKey(selectedEntityName)) timetableData[selectedEntityName!] = []; timetableData[selectedEntityName]!.add({'time': timeCtrl.text, 'title': subjectCtrl.text, 'sub': detailCtrl.text}); timetableData[selectedEntityName]!.sort((a,b) => a['time']!.compareTo(b['time']!)); }); Navigator.pop(ctx); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("Save Slot"))],
      ),
    );
  }

  InputDecoration _inputDeco() => const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), isDense: true);
}

// ==========================================
// 8. BROADCAST PAGE
// ==========================================
class AdvancedBroadcastPage extends StatefulWidget {
  const AdvancedBroadcastPage({super.key});

  @override
  State<AdvancedBroadcastPage> createState() => _AdvancedBroadcastPageState();
}

class _AdvancedBroadcastPageState extends State<AdvancedBroadcastPage> {
  String? selectedDept;
  final List<String> departments = ['Computer Science', 'Mechanical Eng', 'Civil Eng', 'Commerce'];
  String? selectedRole;
  String? selectedFaculty;
  String? selectedClass;
  String? selectedStudent;
  final TextEditingController _messageCtrl = TextEditingController();

  List<String> getAvailableClasses() => selectedDept == null ? [] : allClasses.where((c) => c['dept'] == selectedDept).map((c) => c['className'] as String).toList();
  List<String> getAvailableFaculty() => selectedDept == null ? [] : allFaculty.where((f) => f['dept'] == selectedDept).map((f) => f['name'] as String).toList();
  List<String> getAvailableStudents() => selectedClass == null ? [] : mockStudents[selectedClass] ?? [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Compose Message", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 20),
            _buildLabel("1. Select Department"),
            DropdownButtonFormField<String>(value: selectedDept, decoration: _inputDeco(), items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (val) => setState(() { selectedDept = val; selectedRole = null; })),
            if (selectedDept != null) ...[
              const SizedBox(height: 15),
              _buildLabel("2. Select Recipient Group"),
              DropdownButtonFormField<String>(value: selectedRole, decoration: _inputDeco(), items: ['Faculty', 'Students'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), onChanged: (val) => setState(() { selectedRole = val; selectedClass = null; selectedFaculty = null; })),
            ],
            if (selectedRole == 'Faculty') ...[
              const SizedBox(height: 15),
              _buildLabel("3. Select Faculty"),
              DropdownButtonFormField<String>(value: selectedFaculty, decoration: _inputDeco(), items: [const DropdownMenuItem(value: 'All', child: Text("All Faculty")), ...getAvailableFaculty().map((f) => DropdownMenuItem(value: f, child: Text(f)))], onChanged: (val) => setState(() => selectedFaculty = val)),
            ],
            if (selectedRole == 'Students') ...[
              const SizedBox(height: 15),
              _buildLabel("3. Select Class"),
              DropdownButtonFormField<String>(value: selectedClass, decoration: _inputDeco(), items: getAvailableClasses().map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (val) => setState(() { selectedClass = val; selectedStudent = null; })),
              if (selectedClass != null) ...[
                const SizedBox(height: 15),
                _buildLabel("4. Select Student"),
                DropdownButtonFormField<String>(value: selectedStudent, decoration: _inputDeco(), items: [const DropdownMenuItem(value: null, child: Text("All Students")), ...getAvailableStudents().map((s) => DropdownMenuItem(value: s, child: Text(s)))], onChanged: (val) => setState(() => selectedStudent = val)),
              ]
            ],
            const SizedBox(height: 25),
            const Text("Message Content:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            TextField(controller: _messageCtrl, maxLines: 4, decoration: const InputDecoration(border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sent!"))), icon: const Icon(Icons.send), label: const Text("SEND"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)));
  InputDecoration _inputDeco() => const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), isDense: true);
}