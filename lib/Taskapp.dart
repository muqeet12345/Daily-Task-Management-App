import 'package:flutter/material.dart';
import 'database_helper.dart'; // Your SQLite Database Helper Class
import 'add_task_dialog.dart'; // Your AddTaskDialog Widget
import 'TaskDetailsScreen.dart'; // The new page where tasks for a day will be displayed

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks();

    groupedTasks.clear();
    for (var task in tasks) {
      String day = task['day'];
      if (!groupedTasks.containsKey(day)) {
        groupedTasks[day] = [];
      }
      groupedTasks[day]!.add(task);
    }

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);
    _fetchTasks();
  }

  Future<void> _addTask(String description, String time, String date, String day) async {
    if (description.isEmpty || time.isEmpty || date.isEmpty || day.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final existingTasks = await dbHelper.getTasks();
      for (var task in existingTasks) {
        if (task['description'] == description &&
            task['time'] == time &&
            task['date'] == date &&
            task['day'] == day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task already exists!')),
          );
          return;
        }
      }

      await dbHelper.insertTask({
        'description': description,
        'time': time,
        'date': date,
        'day': day,
      });

      _fetchTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id);
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        title: const Text(
          'Task List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedTasks.isEmpty
          ? const Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: groupedTasks.length,
        itemBuilder: (context, dayIndex) {
          String day = groupedTasks.keys.elementAt(dayIndex);
          List<Map<String, dynamic>> tasksForDay = groupedTasks[day]!;

          // Get the date for the first task in the group (all tasks in the group share the same date)
          String date = tasksForDay.first['date'];

          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                '$day, $date',  // Showing both day and date
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: Colors.teal.shade600,
              ),
              onTap: () {
                // Navigate to the task details page for this day
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailsScreen(day: day, date: date),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade600,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: (description, time, date, day) async {
                  await _addTask(description, time, date, day);
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'database_helper.dart'; // Your SQLite Database Helper Class
import 'add_task_dialog.dart'; // Your AddTaskDialog Widget
import 'TaskDetailsScreen.dart'; // The new page where tasks for a day will be displayed

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks();

    groupedTasks.clear();
    for (var task in tasks) {
      String day = task['day'];
      if (!groupedTasks.containsKey(day)) {
        groupedTasks[day] = [];
      }
      groupedTasks[day]!.add(task);
    }

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);
    _fetchTasks();
  }

  Future<void> _addTask(String description, String time, String date, String day) async {
    if (description.isEmpty || time.isEmpty || date.isEmpty || day.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final existingTasks = await dbHelper.getTasks();
      for (var task in existingTasks) {
        if (task['description'] == description &&
            task['time'] == time &&
            task['date'] == date &&
            task['day'] == day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task already exists!')),
          );
          return;
        }
      }

      await dbHelper.insertTask({
        'description': description,
        'time': time,
        'date': date,
        'day': day,
      });

      _fetchTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id);
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedTasks.isEmpty
          ? const Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: groupedTasks.length,
        itemBuilder: (context, dayIndex) {
          String day = groupedTasks.keys.elementAt(dayIndex);
          List<Map<String, dynamic>> tasksForDay = groupedTasks[day]!;

          // Get the date for the first task in the group (all tasks in the group share the same date)
          String date = tasksForDay.first['date'];

          return ListTile(
            title: Text(
              '$day, $date',  // Showing both day and date
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // Navigate to the task details page for this day
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailsScreen(day: day, date: date),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: (description, time, date, day) async {
                  await _addTask(description, time, date, day);
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} */

/* import 'package:flutter/material.dart';
import 'database_helper.dart'; // Your SQLite Database Helper Class
import 'add_task_dialog.dart'; // Your AddTaskDialog Widget

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedTasks = {};

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks();

    groupedTasks.clear();
    for (var task in tasks) {
      String day = task['day'];
      if (!groupedTasks.containsKey(day)) {
        groupedTasks[day] = [];
      }
      groupedTasks[day]!.add(task);
    }

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);
    _fetchTasks();
  }

  Future<void> _addTask(String description, String time, String date, String day) async {
    if (description.isEmpty || time.isEmpty || date.isEmpty || day.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      final existingTasks = await dbHelper.getTasks();
      for (var task in existingTasks) {
        if (task['description'] == description &&
            task['time'] == time &&
            task['date'] == date &&
            task['day'] == day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task already exists!')),
          );
          return;
        }
      }

      await dbHelper.insertTask({
        'description': description,
        'time': time,
        'date': date,
        'day': day,
      });

      _fetchTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id);
    _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedTasks.isEmpty
          ? const Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: groupedTasks.length,
        itemBuilder: (context, dayIndex) {
          String day = groupedTasks.keys.elementAt(dayIndex);
          List<Map<String, dynamic>> tasksForDay = groupedTasks[day]!;

          // Get the date for the first task in the group (all tasks in the group share the same date)
          String date = tasksForDay.first['date'];

          return ExpansionTile(
            title: Text(
              '$day, $date',  // Showing both day and date
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: tasksForDay.map((task) {
              final isComplete = task['status'] == 1;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: isComplete ? Colors.green.shade100 : null,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Time: ${task['time']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isComplete ? Colors.green : Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.check_circle,
                                    color: isComplete ? Colors.green : Colors.grey,
                                  ),
                                  onPressed: () {
                                    _markTaskComplete(task['id'], isComplete);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTask(task['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Description:',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task['description'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: (description, time, date, day) async {
                  await _addTask(description, time, date, day);
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} */




/* class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = []; // To store tasks fetched from DB
  bool _isLoading = true; // Show loading indicator while fetching data

  @override
  void initState() {
    super.initState();
    _fetchTasks(); // Fetch tasks from the database
  }
  Future<void> _markTaskComplete(int id, bool isCurrentlyComplete) async {
    final dbHelper = DatabaseHelper();

    // Update the task's status in the database
    await dbHelper.updateTaskStatus(id, isCurrentlyComplete ? 0 : 1);

    // Refresh the task list to show the updated status
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final dbHelper = DatabaseHelper();
    final tasks = await dbHelper.getTasks(); // Get all tasks from the database
    setState(() {
      _tasks = tasks;
      _isLoading = false; // Data loading completed
    });
  }

  Future<void> _addTask(String description, String time, String date, String day) async {
    if (description.isEmpty || time.isEmpty || date.isEmpty || day.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required!')),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();

      // Check for duplicates
      final existingTasks = await dbHelper.getTasks();
      for (var task in existingTasks) {
        if (task['description'] == description &&
            task['time'] == time &&
            task['date'] == date &&
            task['day'] == day) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task already exists!')),
          );
          return;
        }
      }

      // Insert the task into the database
      await dbHelper.insertTask({
        'description': description,
        'time': time,
        'date': date,
        'day': day,
      });

      // Refresh the task list
      _fetchTasks();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
    } catch (e) {
      // Handle any unexpected errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _deleteTask(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteTask(id); // Delete task by ID from the database
    _fetchTasks(); // Refresh the list after deletion
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _tasks.isEmpty
          ? const Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          final isComplete = task['status'] == 1; // Check if the task is complete

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              color: isComplete ? Colors.green.shade100 : null, // Change background color for complete tasks
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Day: ${task['day']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isComplete ? Colors.green : Colors.black, // Change text color for complete tasks
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: isComplete ? Colors.green : Colors.grey, // Toggle check icon color
                              ),
                              onPressed: () {
                                _markTaskComplete(task['id'], isComplete);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(task['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${task['date']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Time: ${task['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      task['description'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),

        floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: (description, time, date, day) async {
                  // Add the task to the database
                  await _addTask(description, time, date, day);

                  // Close the dialog only if it is still open
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} */

/* @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : _tasks.isEmpty
          ? Center(
        child: Text(
          'No tasks available',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4, // Add shadow to the card
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Day: ${task['day']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(task['id']),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${task['date']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Time: ${task['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      task['description'],
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: (description, time, date, day) async {
                  // Add the task to the database
                  await _addTask(description, time, date, day);

                  // Close the dialog only if it is still open
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} */













/* import 'package:flutter/material.dart';
import 'task_model.dart'; // Import the Task model
import 'add_task_dialog.dart'; // Import the AddTaskDialog widget

class TaskHomePage extends StatefulWidget {
  @override
  _TaskHomePageState createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  final List<Task> _tasks = []; // List to store tasks

  // Function to add a task
  void _addTask(String description, String time, String date, String day) {
    setState(() {
      _tasks.add(Task(
        description: description,
        time: time,
        date: date,
        day: day,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Manager'),
        backgroundColor: Colors.teal,
      ),
      body: _tasks.isEmpty
          ? Center(
        child: Text(
          'No tasks added yet!',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(
                _tasks[index].description,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'Day: ${_tasks[index].day}\nTime: ${_tasks[index].time}\nDate: ${_tasks[index].date}'),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _tasks.removeAt(index); // Remove task
                  });
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AddTaskDialog(
                onAdd: _addTask, // Pass the add task function
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
} */
