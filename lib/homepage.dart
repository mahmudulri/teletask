import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final box = GetStorage();
  Map<String, List<String>> namedLists = {};
  Map<String, Set<String>> copiedNumbersMap = {};
  String? selectedListName;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    final storedData = box.read<Map>('namedLists');
    if (storedData != null) {
      namedLists = Map<String, List<String>>.from(
        storedData.map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      );
      if (namedLists.isNotEmpty) {
        selectedListName = namedLists.keys.first;
      }
    }

    final storedCopiedMap = box.read<Map>('copiedNumbersMap');
    if (storedCopiedMap != null) {
      copiedNumbersMap = storedCopiedMap.map(
        (key, value) =>
            MapEntry(key, Set<String>.from(List<String>.from(value))),
      );
    }
  }

  void saveData() {
    box.write('namedLists', namedLists);
    box.write(
      'copiedNumbersMap',
      copiedNumbersMap.map((k, v) => MapEntry(k, v.toList())),
    );
  }

  void showAddDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController dataController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New List"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: "List name"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dataController,
                  maxLines: 8,
                  decoration: const InputDecoration(hintText: "Paste numbers"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text("Paste from Clipboard"),
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    if (clipboardData != null) {
                      dataController.text = clipboardData.text ?? '';
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
                String name = nameController.text.trim();
                List<String> nums = dataController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                if (name.isNotEmpty && nums.isNotEmpty) {
                  setState(() {
                    namedLists[name] = nums;
                    copiedNumbersMap[name] = {};
                    selectedListName = name;
                    saveData();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void copyToClipboard(String number) {
    Clipboard.setData(ClipboardData(text: number));
    setState(() {
      copiedNumbersMap.putIfAbsent(selectedListName!, () => {});
      copiedNumbersMap[selectedListName!]!.add(number);
      saveData();
    });
  }

  void undoCopy(String number) {
    setState(() {
      copiedNumbersMap[selectedListName!]?.remove(number);
      saveData();
    });
  }

  void deleteList(String name) {
    setState(() {
      namedLists.remove(name);
      copiedNumbersMap.remove(name);
      if (selectedListName == name) {
        selectedListName = namedLists.isNotEmpty ? namedLists.keys.first : null;
      }
      saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentNumbers =
        selectedListName != null ? namedLists[selectedListName] ?? [] : [];
    final copiedSet = copiedNumbersMap[selectedListName] ?? {};
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Text("Telegram Work--"),
            Text(
              "Rafiuzzaman",
              style: TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          CircleAvatar(
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: showAddDialog,
            ),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: Container(
        height: screenHeight,
        width: screenWidth,
        child: Column(
          children: [
            if (namedLists.isNotEmpty)
              Container(
                color: Colors.cyan,
                width: screenWidth,
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: namedLists.keys.map((name) {
                    final isSelected = name == selectedListName;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedListName = name;
                          });
                        },
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Delete '$name'?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    deleteList(name);
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: Container(
                // color: Colors.green,
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: currentNumbers.length,
                  itemBuilder: (context, index) {
                    final number = currentNumbers[index];
                    final isCopied = copiedSet.contains(number);

                    return ListTile(
                      tileColor: isCopied ? Colors.red[100] : null,
                      title: Text(
                        number,
                        style: TextStyle(color: isCopied ? Colors.red : null),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => copyToClipboard(number),
                          ),
                          if (isCopied)
                            IconButton(
                              icon: const Icon(Icons.undo),
                              onPressed: () => undoCopy(number),
                            ),
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
    );
  }
}
