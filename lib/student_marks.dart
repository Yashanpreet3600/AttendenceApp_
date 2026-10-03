import 'package:flutter/material.dart';
import 'database_service.dart';

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
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No marks uploaded yet."));
          }

          var marksList = snapshot.data!;

          return ListView.builder(
            itemCount: marksList.length,
            padding: EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var test = marksList[index];
              double myScore = double.parse(test['myScore'].toString());
              double total = double.parse(test['totalMarks'].toString());
              double percentage = total == 0 ? 0 : myScore / total;

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircularProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[200],
                        color: percentage >= 0.5 ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(test['testName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Score: $myScore / $total", style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                        ],
                      ),
                      Spacer(),
                      Text("${(percentage * 100).toInt()}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
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