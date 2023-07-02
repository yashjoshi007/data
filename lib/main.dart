import 'package:data/table.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Database App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => InputScreen(),
        '/display': (context) => DisplayScreen(),
      },
    );
  }
}

class InputScreen extends StatefulWidget {
  @override
  _InputScreenState createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNoController = TextEditingController();
  bool _doneStatus = false;

  Future<void> saveData( BuildContext context) async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'data.db');
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, billNo TEXT, done INTEGER)');
      },
    );

    // Check if a record with the same billNo already exists
    final List<Map<String, dynamic>> existingRecords =
    await database.rawQuery('SELECT * FROM test WHERE billNo = ?', [_billNoController.text]);
    if (existingRecords.isNotEmpty) {
      await database.close();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Duplicate Bill No.'),
            content: Text('A record with the same Bill No. already exists.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Skip inserting if a record with the same billNo exists
    }




    final Map<String, dynamic> data = {
      'billNo': _billNoController.text,
      'done': _doneStatus ? 1 : 0,
    };

    await database.insert('test', data);
    await database.close();
    Navigator.pushNamed(context, '/display');
  }


  @override
  void dispose() {
    _billNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _billNoController,
                decoration: InputDecoration(labelText: 'Bill No.'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a bill number';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Done'),
                value: _doneStatus,
                onChanged: (value) {
                  setState(() {
                    _doneStatus = value;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    saveData(context).then((_) {

                    });
                  }
                },
                child: Text('Save'),
              ),
              ElevatedButton(
                onPressed: () {

                      Navigator.pushNamed(context, '/display');

                },
                child: Text('Show table'),
              )
            ],
          ),
        ),
      ),
    );
  }
}





class DataItem {
  final int id;
  final String billNo;
  final int done;

  DataItem({required this.id, required this.billNo, required this.done});

  factory DataItem.fromMap(Map<String, dynamic> map) {
    return DataItem(
      id: map['id'],
      billNo: map['billNo'],
      done: map['done'],
    );
  }
}
