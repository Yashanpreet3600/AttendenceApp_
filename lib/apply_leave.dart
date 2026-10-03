import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Handles Gallery
import 'database_service.dart';

class ApplyLeaveScreen extends StatefulWidget {
  final String studentName;
  final String className;

  const ApplyLeaveScreen({super.key, required this.studentName, required this.className});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> facultyList = [];
  String? selectedFacultyUid;
  File? _selectedImage;

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  void _loadFaculty() async {
    var list = await _db.getAllFaculty();
    if(mounted) {
      setState(() {
        facultyList = list;
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply for Leave"), backgroundColor: const Color(0xFF002046), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TEACHER SELECTOR
            const Text("To Whom:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            isLoading
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text("Select Teacher"),
              value: selectedFacultyUid,
              items: facultyList.map((f) {
                return DropdownMenuItem(
                  value: f['uid'] as String,
                  child: Text("${f['name']} (${f['department'] ?? 'Faculty'})"),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedFacultyUid = val),
            ),

            const SizedBox(height: 15),

            // REASON INPUT
            const Text("Reason:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Enter reason...", border: OutlineInputBorder()),
            ),

            const SizedBox(height: 15),

            // IMAGE ATTACHMENT
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Attach Proof"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
                ),
                const SizedBox(width: 10),
                if (_selectedImage != null)
                  const Text("Image Added ✅", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 20),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text("SUBMIT APPLICATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const Divider(height: 30, thickness: 2),
            const Text("My Applications:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Expanded(child: _buildLeaveHistory()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveHistory() {
    return StreamBuilder(
      stream: _db.getMyLeaves(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No applications yet."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String status = data['status'];
            String remark = data['facultyRemark'] ?? "";

            Color color = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.orange);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(data['reason'], style: const TextStyle(fontWeight: FontWeight.bold))),
                        Chip(
                          label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          backgroundColor: color,
                          padding: EdgeInsets.zero,
                        )
                      ],
                    ),

                    // Show if attachment exists
                    if (data['attachment'] != null && data['attachment'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Row(children: const [Icon(Icons.image, size: 14, color: Colors.blue), SizedBox(width: 5), Text("Has Attachment", style: TextStyle(color: Colors.blue, fontSize: 12))]),
                      ),

                    // Show Faculty Remark
                    if (remark.isNotEmpty) ...[
                      const Divider(),
                      Text("Teacher: $remark", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (selectedFacultyUid == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => isSubmitting = true);

    // 1. Upload Image if exists
    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _db.uploadLeaveAttachment(_selectedImage!);
    }

    // 2. Submit Data
    await _db.applyLeave(
      reason: _reasonController.text,
      facultyUid: selectedFacultyUid!,
      studentName: widget.studentName,
      className: widget.className,
      attachmentUrl: imageUrl,
    );

    setState(() {
      isSubmitting = false;
      _selectedImage = null;
    });
    _reasonController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Sent!")));
  }
}