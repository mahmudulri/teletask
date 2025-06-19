import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Mynumberpage extends StatefulWidget {
  const Mynumberpage({super.key});

  @override
  State<Mynumberpage> createState() => _MynumberpageState();
}

class _MynumberpageState extends State<Mynumberpage> {
  Map<String, Set<String>> copiedNumbersMap = {};
  String? selectedListId;
  String? selectedListName;
  List<String> selectedNumbers = [];

  void copyToClipboard(String number) {
    Clipboard.setData(ClipboardData(text: number));
    setState(() {
      copiedNumbersMap.putIfAbsent(selectedListId!, () => {});
      copiedNumbersMap[selectedListId!]!.add(number);
    });
  }

  void undoCopy(String number) {
    setState(() {
      copiedNumbersMap[selectedListId!]?.remove(number);
    });
  }

  void deleteList(String docId, String serial) async {
    await FirebaseFirestore.instance
        .collection('numberlist')
        .doc(docId)
        .delete();
    if (docId == selectedListId) {
      setState(() {
        selectedListId = null;
        selectedListName = null;
        selectedNumbers = [];
      });
    }
  }

  void showDeleteDialog(String docId, String serial) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete '$serial'"),
        content: const Text("Are you sure you want to delete this list?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              deleteList(docId, serial);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    final copiedSet = copiedNumbersMap[selectedListId] ?? {};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.black,
        title: Row(
          children: const [
            Text("Telegram Work--", style: TextStyle(color: Colors.white)),
            SizedBox(width: 5),
            Text("Rafiuzzaman",
                style: TextStyle(fontSize: 10, color: Colors.white)),
          ],
        ),
      ),
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Left Panel (Serial List)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.blueGrey,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('numberlist')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final docs = snapshot.data!.docs;

                      // Auto-select first list
                      if (docs.isNotEmpty && selectedListId == null) {
                        final firstDoc = docs.first;
                        final firstData =
                            firstDoc.data() as Map<String, dynamic>;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() {
                            selectedListId = firstDoc.id;
                            selectedListName = firstData['serial'];
                            selectedNumbers =
                                List<String>.from(firstData['numbers'] ?? []);
                          });
                        });
                      }

                      return docs.isEmpty
                          ? const Center(
                              child: Text("No serial lists available",
                                  style: TextStyle(color: Colors.white)))
                          : ListView(
                              children: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final serial = data['serial'] ?? '';
                                final isSelected = doc.id == selectedListId;

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedListId = doc.id;
                                        selectedListName = serial;
                                        selectedNumbers = List<String>.from(
                                            data['numbers'] ?? []);
                                      });
                                    },
                                    onLongPress: () =>
                                        showDeleteDialog(doc.id, serial),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      height: 70,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 1, color: Colors.white),
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        serial,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                    },
                  ),
                ),
              ),

              // Right Panel (Number List)
              Expanded(
                flex: 5,
                child: Container(
                  color: Colors.white,
                  child: selectedNumbers.isEmpty
                      ? const Center(
                          child: Text(
                            "No data available now",
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: selectedNumbers.length,
                          itemBuilder: (context, index) {
                            final myindex = index + 1;
                            final number = selectedNumbers[index];
                            final isCopied = copiedSet.contains(number);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  CircleAvatar(
                                      radius: 12,
                                      child: Text(
                                        myindex.toString(),
                                      )),
                                  const SizedBox(width: 5),
                                  Text(
                                    number,
                                    style: TextStyle(
                                      color:
                                          isCopied ? Colors.red : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.copy),
                                    onPressed: () => copyToClipboard(number),
                                  ),
                                  if (isCopied)
                                    IconButton(
                                      icon: const Icon(Icons.undo),
                                      onPressed: () => undoCopy(number),
                                    ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
