import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_note_app/hive_box.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final box = Hive.box('notes_box');

  final myhive = CustomHiveBox();
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    items = myhive.refreshItems(); // Load data when app starts
  }

  final TextEditingController noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(
              // the list of items
              itemCount: items.length,
              itemBuilder: (_, index) {
                final currentItem = items[index];
                return Card(
                  color: Colors.orange.shade100,
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                      title: Text(currentItem['note']),
                      subtitle: Text(currentItem['date'].toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          IconButton(
                              icon: const Icon(Icons.edit), onPressed: () => _showForm(context, currentItem['key'])),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => myhive.deleteItem(currentItem['key']).then((value) {
                              items = value;
                              setState(() {});
                            }),
                          ),
                        ],
                      )),
                );
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext ctx, int? itemKey) async {
    // itemKey == null -> create new item
    // itemKey != null -> update an existing item

    var noteDate = "";

    if (itemKey != null) {
      final existingItem = items.firstWhere((element) => element['key'] == itemKey);
      noteController.text = existingItem['note'];
      noteDate = existingItem['date'];
    } else {
      final now = DateTime.now();
      String formattedDate = DateFormat('yyyy/MM/dd hh:mm a').format(now);
      noteDate = formattedDate;
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 15, left: 15, right: 15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(hintText: 'Note'),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new item
                      if (itemKey == null) {
                        myhive.createItem({"note": noteController.text, "date": noteDate}).then((value) {
                          items = value;
                          setState(() {});
                        });
                      }

                      // update an existing item
                      if (itemKey != null) {
                        myhive
                            .updateItem(itemKey, {'note': noteController.text.trim(), 'date': noteDate}).then((value) {
                          items = value;
                          setState(() {});
                        });
                      }

                      // Clear the text fields
                      noteController.text = '';

                      Navigator.of(context).pop(); // Close the bottom sheet
                    },
                    child: Text(itemKey == null ? 'Create New' : 'Update'),
                  ),
                  const SizedBox(
                    height: 15,
                  )
                ],
              ),
            ));
  }
}
