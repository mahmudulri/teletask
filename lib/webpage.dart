import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

class Webpage extends StatefulWidget {
  const Webpage({super.key});

  @override
  State<Webpage> createState() => _WebpageState();
}

class _WebpageState extends State<Webpage> {
  final box = GetStorage();
  Map<String, List<String>> columnLists = {};
  Map<String, Set<String>> copiedNumbers = {};
  Map<String, String> columnTitles = {}; // 🆕 Added for storing titles

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    final storedData = box.read<Map>('columnLists');
    if (storedData != null) {
      columnLists = Map<String, List<String>>.from(
        storedData.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
    }

    final storedCopied = box.read<Map>('copiedNumbers');
    if (storedCopied != null) {
      copiedNumbers = storedCopied.map(
        (key, value) =>
            MapEntry(key, Set<String>.from(List<String>.from(value))),
      );
    }

    final storedTitles = box.read<Map>('columnTitles');
    if (storedTitles != null) {
      columnTitles = Map<String, String>.from(storedTitles);
    }
  }

  void saveData() {
    box.write('columnLists', columnLists);
    box.write(
        'copiedNumbers', copiedNumbers.map((k, v) => MapEntry(k, v.toList())));
    box.write('columnTitles', columnTitles);
  }

  void showAddDialog(String columnName) {
    TextEditingController numberController = TextEditingController();
    TextEditingController titleController = TextEditingController(
      text: columnTitles[columnName] ?? '',
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add to $columnName"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(hintText: "Title for this list"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: numberController,
                maxLines: 8,
                decoration: const InputDecoration(hintText: "Paste numbers..."),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.paste),
                label: const Text("Paste from Clipboard"),
                onPressed: () async {
                  final clipboardData = await Clipboard.getData('text/plain');
                  if (clipboardData != null) {
                    numberController.text = clipboardData.text ?? '';
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final nums = numberController.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final title = titleController.text.trim();
              if (nums.isNotEmpty || title.isNotEmpty) {
                setState(() {
                  if (nums.isNotEmpty) {
                    columnLists[columnName] = [
                      ...columnLists[columnName] ?? [],
                      ...nums
                    ];
                  }
                  if (title.isNotEmpty) {
                    columnTitles[columnName] = title;
                  }
                  copiedNumbers.putIfAbsent(columnName, () => {});
                  saveData();
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void copyToClipboard(String number, String columnName) {
    Clipboard.setData(ClipboardData(text: number));
    setState(() {
      copiedNumbers.putIfAbsent(columnName, () => {});
      copiedNumbers[columnName]!.add(number);
      saveData();
    });
  }

  void undoCopy(String number, String columnName) {
    setState(() {
      copiedNumbers[columnName]?.remove(number);
      saveData();
    });
  }

  void deleteColumn(String columnName) {
    setState(() {
      columnLists.remove(columnName);
      copiedNumbers.remove(columnName);
      columnTitles.remove(columnName);
      saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnNames = [
      "List-1",
      "List-2",
      "List-3",
      "List-4",
      "List-5",
      "List-6"
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: columnNames.map((colName) {
          final numbers = columnLists[colName] ?? [];
          final copied = copiedNumbers[colName] ?? {};
          final title = columnTitles[colName] ?? '';

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                    right: BorderSide(width: 1, color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    color: Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(colName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () => showAddDialog(colName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text("Delete all from '$colName'?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        deleteColumn(colName);
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: numbers.length,
                      itemBuilder: (context, index) {
                        final number = numbers[index];
                        final isCopied = copied.contains(number);
                        return ListTile(
                          tileColor: isCopied ? Colors.green : null,
                          title: Text(
                            number,
                            style: TextStyle(
                                color: isCopied ? Colors.white : null),
                          ),
                          dense: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () =>
                                    copyToClipboard(number, colName),
                              ),
                              if (isCopied)
                                IconButton(
                                  icon: const Icon(Icons.undo),
                                  onPressed: () => undoCopy(number, colName),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
