import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveApprovalsScreen extends StatefulWidget {
  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  final DatabaseService _db = DatabaseService();

  void _showActionDialog(BuildContext context, String docId, String? imageUrl) {
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Take Action"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const Text("Attachment:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Image.network(imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => const Text("Could not load image"),
                  ),
                  const SizedBox(height: 15),
                ],
                const Text("Add a Message (Optional):"),
                TextField(
                  controller: remarkController,
                  decoration: const InputDecoration(hintText: "e.g., Get well soon"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Reject"),
              onPressed: () {
                _db.updateLeaveStatus(docId, "Rejected", remarkController.text);
                Navigator.pop(ctx);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("Approve"),
              onPressed: () {
                _db.updateLeaveStatus(docId, "Approved", remarkController.text);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave Requests"), backgroundColor: const Color(0xFF002046), foregroundColor: Colors.white),
      body: StreamBuilder(
        stream: _db.getIncomingLeaves(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("No pending requests."));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String status = data['status'];
              String? imageUrl = data['attachment'];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['name'] ?? "Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(data['classId'] ?? "", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Reason: ${data['reason']}"),

                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text("📎 Has Attachment", style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                        ),

                      const Divider(),

                      if (status == 'Pending')
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _showActionDialog(context, doc.id, imageUrl),
                            child: const Text("Review & Action"),
                          ),
                        )
                      else
                        Text("Status: $status", style: const TextStyle(fontStyle: FontStyle.italic)),
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