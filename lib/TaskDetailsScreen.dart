import 'package:flutter/material.dart';
import 'database_helper.dart'; // Your SQLite Database Helper Class

class TaskDetailsScreen extends StatefulWidget {
  final String day;
  final String date;

  const TaskDetailsScreen({Key? key, required this.day, required this.date})
      : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, dynamic>> _tasksForDay = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasksForDay();
  }

  Future<void> _fetchTasksForDay() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks();

    setState(() {
      _tasksForDay = tasks.where((task) {
        return task['day'] == widget.day && task['date'] == widget.date;
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);
    _fetchTasksForDay();
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id);
    _fetchTasksForDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        title: Text(
          '${widget.day}, ${widget.date}', // Displaying the selected day and date
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasksForDay.isEmpty
          ? const Center(
        child: Text(
          'No tasks for this day.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tasksForDay.length,
        itemBuilder: (context, index) {
          final task = _tasksForDay[index];
          final isComplete = task['status'] == 1;

          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                task['description'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Time: ${task['time']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      isComplete
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: isComplete ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      _markTaskComplete(task['id'], isComplete);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                    onPressed: () {
                      _deleteTask(task['id']);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



/* import 'package:flutter/material.dart';
import 'database_helper.dart'; // Your SQLite Database Helper Class

class TaskDetailsScreen extends StatefulWidget {
  final String day;
  final String date;

  const TaskDetailsScreen({Key? key, required this.day, required this.date})
      : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, dynamic>> _tasksForDay = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasksForDay();
  }

  Future<void> _fetchTasksForDay() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks();

    setState(() {
      _tasksForDay = tasks.where((task) {
        return task['day'] == widget.day && task['date'] == widget.date;
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);
    _fetchTasksForDay();
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id);
    _fetchTasksForDay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.day}, ${widget.date}'),  // Displaying the selected day and date
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasksForDay.isEmpty
          ? const Center(child: Text('No tasks for this day.'))
          : ListView.builder(
        itemCount: _tasksForDay.length,
        itemBuilder: (context, index) {
          final task = _tasksForDay[index];
          final isComplete = task['status'] == 1;

          return ListTile(
            title: Text(task['description']),
            subtitle: Text('Time: ${task['time']}'),
            trailing: IconButton(
              icon: Icon(
                isComplete ? Icons.check_circle : Icons.check_circle_outline,
                color: isComplete ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                _markTaskComplete(task['id'], isComplete);
              },
            ),
            onLongPress: () {
              _deleteTask(task['id']);
            },
          );
        },
      ),
    );
  }
} */
