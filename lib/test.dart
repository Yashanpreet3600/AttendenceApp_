import 'package:flutter/material.dart';

class MarkTestScreen extends StatefulWidget {
  final String className;

  const MarkTestScreen({Key? key, required this.className}) : super(key: key);

  @override
  State<MarkTestScreen> createState() => _MarkTestScreenState();
}

class _MarkTestScreenState extends State<MarkTestScreen> {
  // --- BRANDING ---
  final Color kalgidharBlue = const Color(0xFF002046);
  final Color kalgidharTeal = const Color(0xFF00796B);

  // --- CONFIGURATION ---
  final int maxScore = 17;

  // Data Lists
  List<StudentModel> _allStudents = [];
  List<StudentModel> _filteredStudents = [];

  final TextEditingController _searchController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _generateMockData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all student controllers to prevent memory leaks
    for (var student in _allStudents) {
      student.controller.dispose();
    }
    super.dispose();
  }

  void _generateMockData() {
    // Generate 15 students
    _allStudents = List.generate(5, (index) {
      return StudentModel(
        id: index,
        name: 'Student ${index + 1}',
        roll: '2025-${2500 + index}',
        marks: 0,
        // We initialize the controller with empty text so it shows "0" placeholder or empty
        controller: TextEditingController(text: ""),
      );
    });
    _filteredStudents = List.from(_allStudents);
  }

  // --- LOGIC ---
  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents
            .where((s) => s.name.toLowerCase().contains(query.toLowerCase()) ||
            s.roll.contains(query))
            .toList();
      }
    });
  }

  void _updateMarks(StudentModel student, String value) {
    // 1. Handle empty input
    if (value.isEmpty) {
      setState(() => student.marks = 0);
      return;
    }

    // 2. Parse input
    int? newMark = int.tryParse(value);

    if (newMark != null) {
      if (newMark > maxScore) {
        // Error: Value too high
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Marks cannot exceed 17"),
              backgroundColor: Colors.red,
              duration: Duration(milliseconds: 1000),
            )
        );
        // Reset to Max
        student.controller.text = maxScore.toString();
        student.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: student.controller.text.length));
        setState(() => student.marks = maxScore);
      } else {
        // Valid Mark
        setState(() => student.marks = newMark);
      }
    }
  }

  Color _getStatusColor(int marks) {
    double percentage = marks / maxScore;
    if (percentage < 0.35) return Colors.redAccent;
    if (percentage < 0.70) return Colors.orangeAccent;
    return Colors.green;
  }

  Future<void> _uploadData() async {
    FocusScope.of(context).unfocus(); // Hide keyboard
    setState(() => _isUploading = true);

    // Simulate Network Delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isUploading = false);
    if (!mounted) return;

    // Calculate filled
    int filled = _allStudents.where((s) => s.marks > 0).length;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Success", style: TextStyle(color: kalgidharBlue, fontWeight: FontWeight.bold)),
          content: Text("Uploaded marks for $filled / ${_allStudents.length} students."),
          actions: [
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kalgidharBlue),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to dashboard
                },
                child: const Text("OK", style: TextStyle(color: Colors.white))
            )
          ],
        )
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9), // Light background
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: kalgidharBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Column(
          children: [
            const Text("Monday Test", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            Text(widget.className, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            width: double.infinity,
            child: Center(
                child: Text(
                    "Max Score: $maxScore",
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)
                )
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ]
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStudents,
                decoration: const InputDecoration(
                    hintText: "Search Name or Roll No...",
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(vertical: 15)
                ),
              ),
            ),
          ),

          // Student List
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(child: Text("No students found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final double progress = student.marks / maxScore;

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: kalgidharBlue.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))
                      ]
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                            child: Text(
                                student.name[0],
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kalgidharBlue)
                            )
                        ),
                      ),
                      const SizedBox(width: 15),

                      // Name Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kalgidharBlue)),
                            const SizedBox(height: 4),
                            Text(student.roll, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                          ],
                        ),
                      ),

                      // --- UNIQUE INPUT SECTION ---
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // 1. Ring
                          SizedBox(
                            width: 55, height: 55,
                            child: CircularProgressIndicator(
                              value: progress > 1.0 ? 1.0 : progress,
                              backgroundColor: Colors.grey[200],
                              color: _getStatusColor(student.marks),
                              strokeWidth: 5,
                            ),
                          ),
                          // 2. Input
                          SizedBox(
                            width: 35,
                            child: TextField(
                              controller: student.controller,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kalgidharBlue),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: "0",
                                isDense: true,
                              ),
                              onChanged: (val) => _updateMarks(student, val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Upload Button
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: _isUploading ? null : _uploadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: kalgidharBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 5,
            ),
            child: _isUploading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("UPLOAD SCORES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }
}

// --- HELPER MODEL CLASS ---
class StudentModel {
  int id;
  String name;
  String roll;
  int marks;
  TextEditingController controller;

  StudentModel({
    required this.id,
    required this.name,
    required this.roll,
    required this.marks,
    required this.controller
  });
}