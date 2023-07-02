import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'main.dart';

class DisplayScreen extends StatefulWidget {
  @override
  _DisplayScreenState createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  List<DataItem> dataItems = [];

  Future<void> fetchData() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'data.db');
    final database = await openDatabase(path);

    final List<Map<String, dynamic>> results = await database.query('test');
    final sortedResults = results.toList()..sort((a, b) => a['id'] - b['id']);
    setState(() {
      dataItems = sortedResults.map((data) => DataItem.fromMap(data)).toList();
    });

    await database.close();
  }

  Future<void> toggleValue(int id) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'data.db');
    final database = await openDatabase(path);

    final updatedValue = await database.rawQuery('SELECT done FROM test WHERE id = ?', [id]);
    final newValue = updatedValue[0]['done'] == 0 ? 1 : 0;

    await database.update('test', {'done': newValue}, where: 'id = ?', whereArgs: [id]);

    await fetchData();
    await database.close();
  }

  Future<void> deleteData(int id) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'data.db');
    final database = await openDatabase(path);

    await database.delete('test', where: 'id = ?', whereArgs: [id]);

    await fetchData();
    await database.close();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Table'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 60.0,
          columns: [
            DataColumn(
              label: Text(
                'S. No.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Bill No.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: dataItems
              .asMap()
              .entries
              .map(
                (entry) => DataRow(
              cells: [
                DataCell(Text((entry.key + 1).toString())),
                DataCell(Text(entry.value.billNo)),
                DataCell(
                  GestureDetector(
                    onTap: () => toggleValue(entry.value.id),
                    child: Text(
                      entry.value.done == 1 ? 'Yes' : 'No',
                      style: TextStyle(
                        color: entry.value.done == 1 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteData(entry.value.id),
                  ),
                ),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}
