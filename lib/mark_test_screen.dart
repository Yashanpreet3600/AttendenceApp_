import 'package:flutter/material.dart';
import 'database_service.dart';

class MarkTestScreen extends StatefulWidget {
  final String className; // e.g. "BTech1 - Artificial Intelligence"

  const MarkTestScreen({super.key, required this.className});

  @override
  State<MarkTestScreen> createState() => _MarkTestScreenState();
}

class _MarkTestScreenState extends State<MarkTestScreen> {
  final DatabaseService _db = DatabaseService();

  bool isLoading = true;
  List<Map<String, dynamic>> students = [];

  // To store the scores entered by teacher: UID -> Score
  Map<String, double> inputScores = {};

  final TextEditingController _testNameController = TextEditingController();
  final TextEditingController _totalMarksController = TextEditingController(text: "20");

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    // Split "BTech1 - AI" to get "BTech1"
    String actualClass = widget.className.split(' - ')[0].trim();
    var list = await _db.getStudentsByClass(actualClass);
    setState(() {
      students = list;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String subject = widget.className.split('-')[1].trim();

    return Scaffold(
      appBar: AppBar(title: Text("Upload Marks"), backgroundColor: Color(0xFF00796B), foregroundColor: Colors.white),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 1. TEST DETAILS INPUT
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              children: [
                Text("Subject: $subject", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _testNameController,
                        decoration: InputDecoration(labelText: "Test Name (e.g. Unit 1)", border: OutlineInputBorder()),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _totalMarksController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: "Max Marks", border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. STUDENT LIST
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              padding: EdgeInsets.all(10),
              itemBuilder: (context, index) {
                var student = students[index];
                String uid = student['uid'];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(student['name'][0])),
                    title: Text(student['name']),
                    subtitle: Text("ID: $uid"),
                    trailing: SizedBox(
                      width: 80,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: "0", border: OutlineInputBorder()),
                        onChanged: (val) {
                          if (val.isNotEmpty) {
                            inputScores[uid] = double.tryParse(val) ?? 0;
                          }
                        },
                      ),
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
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00796B), padding: EdgeInsets.symmetric(vertical: 15)),
              child: Text("UPLOAD SCORES", style: TextStyle(color: Colors.white)),
              onPressed: _submitScores,
            ),
          )
        ],
      ),
    );
  }

  void _submitScores() async {
    if (_testNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter Test Name")));
      return;
    }

    setState(() => isLoading = true);

    String actualClass = widget.className.split(' - ')[0].trim();
    String subject = widget.className.split('-')[1].trim();

    double total = double.tryParse(_totalMarksController.text) ?? 20;

    await _db.submitTestScores(
      className: actualClass,
      subject: subject,
      testName: _testNameController.text,
      totalMarks: total,
      scores: inputScores,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Marks Uploaded!")));
      Navigator.pop(context);
    }
  }
}