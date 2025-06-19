import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetNumber extends StatefulWidget {
  const SetNumber({super.key});

  @override
  State<SetNumber> createState() => _SetNumberState();
}

class _SetNumberState extends State<SetNumber> {
  final TextEditingController serialController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  void uploadNumberList() async {
    String serial = serialController.text.trim();
    String rawNumbers = numberController.text.trim();

    if (serial.isEmpty || rawNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Serial and numbers cannot be empty")),
      );
      return;
    }

    List<String> numberList = rawNumbers
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    Map<String, dynamic> data = {
      'serial': serial,
      'numbers': numberList,
    };

    try {
      await FirebaseFirestore.instance.collection('numberlist').add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data uploaded successfully")),
      );
      serialController.clear();
      numberController.clear();
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload: $e")),
      );
    }
  }

  void pasteFromClipboard() async {
    ClipboardData? clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData != null && clipboardData.text != null) {
      numberController.text = clipboardData.text!;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Clipboard is empty")),
      );
    }
  }

  void deleteDocument(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('numberlist')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deleted successfully")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete: $e")),
      );
    }
  }

  void showDeleteDialog(String docId, String serial) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete '$serial'?"),
        content: const Text("Are you sure you want to delete this list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteDocument(docId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Number Lists")),
      body: Row(
        children: [
          // Left panel: Form
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: serialController,
                    decoration: const InputDecoration(
                      labelText: 'Serial Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        "Paste your numbers below:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: pasteFromClipboard,
                        icon: const Icon(Icons.paste),
                        label: const Text("Paste Numbers"),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TextField(
                      controller: numberController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        labelText: 'Numbers (one per line)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: uploadNumberList,
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload to Firestore"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right panel: List
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Saved Number Lists",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('numberlist')
                          .orderBy('serial')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text("No serial lists found."));
                        }

                        return ListView(
                          children: snapshot.data!.docs.map((doc) {
                            String serial = doc['serial'] ?? 'Unnamed';
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(serial),
                                trailing:
                                    const Icon(Icons.delete, color: Colors.red),
                                onTap: () => showDeleteDialog(doc.id, serial),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
