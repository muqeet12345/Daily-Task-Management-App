import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd;

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedDay = "";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _createNotificationChannel();
    _updateDateController();
    _updateDay();
  }

  void _initializeNotifications() {
    tz.initializeTimeZones();
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    _notificationsPlugin.initialize(initializationSettings).then((_) {
      print("Notifications initialized");
    }).catchError((error) {
      print("Error initializing notifications: $error");
    });
  }

  void _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_channel', // Same as the channel ID in your code
      'Task Notifications', // Channel name
      description: 'Reminder for tasks', // Channel description
      importance: Importance.max,
      playSound: true, // Enable sound
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Add sound
      enableVibration: true, // Enable vibration
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  void _updateDay() {
    _selectedDay = DateFormat('EEEE').format(_selectedDate);
  }

  Future<void> _scheduleNotification(DateTime taskDateTime, String description) async {
    final notificationTime = taskDateTime.subtract(const Duration(minutes: 5));

    print("Scheduling notification for: $notificationTime");
    print("Notification title: Task Reminder");
    print("Notification body: Upcoming Task: $description");

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.zonedSchedule(
      notificationId, // Use a unique ID
      "Task Reminder",
      "Upcoming Task: $description",
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Reminder for tasks',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('notification_sound'), // Add sound
          playSound: true, // Ensure sound is played
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
    ).then((_) {
      print("Notification scheduled successfully");
    }).catchError((error) {
      print("Error scheduling notification: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Task Date',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Task Time',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.teal),
                  onPressed: _selectTime,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal, // Text color
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _updateDateController();
        _updateDay();
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _saveTask() async {
    String description = _descriptionController.text.trim();
    String time = _timeController.text.trim();

    if (description.isEmpty || time.isEmpty || _selectedTime == null) {
      _showError('Please enter both description and time!');
      return;
    }

    final taskDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (taskDateTime.isBefore(DateTime.now())) {
      _showError('You cannot set a task in the past!');
      return;
    }

    await _scheduleNotification(taskDateTime, description);

    // Save the task to your database or state management
    widget.onAdd(description, time, _dateController.text, _selectedDay);

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}




/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'database_helper.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd;

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedDay = "";
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  late FlutterLocalNotificationsPlugin _notificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _updateDateController();
    _updateDay();
  }

  void _initializeNotifications() {
    tz.initializeTimeZones();
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);

    _notificationsPlugin.initialize(initializationSettings);
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  void _updateDay() {
    _selectedDay = DateFormat('EEEE').format(_selectedDate);
  }

  Future<void> _scheduleNotification(DateTime taskDateTime, String description) async {
    final notificationTime = taskDateTime.subtract(const Duration(minutes: 5));

    await _notificationsPlugin.zonedSchedule(
      0, // Notification ID
      "Task Reminder",
      "Upcoming Task: $description",
      tz.TZDateTime.from(notificationTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_channel',
          'Task Notifications',
          channelDescription: 'Reminder for tasks',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Task Date',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Task Time',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.teal),
                  onPressed: _selectTime,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal, // Text color
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _updateDateController();
        _updateDay();
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _saveTask() async {
    String description = _descriptionController.text.trim();
    String time = _timeController.text.trim();

    if (description.isEmpty || time.isEmpty || _selectedTime == null) {
      _showError('Please enter both description and time!');
      return;
    }

    final taskDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (taskDateTime.isBefore(DateTime.now())) {
      _showError('You cannot set a task in the past!');
      return;
    }

    await _scheduleNotification(taskDateTime, description);

    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertTask({
      'description': description,
      'time': time,
      'date': _dateController.text,
      'day': _selectedDay,
    });

    widget.onAdd(description, time, _dateController.text, _selectedDay);

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} */


/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd;

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedDay = "";
  DateTime _selectedDate = DateTime.now();
  final int _maxDescriptionWords = 50;

  @override
  void initState() {
    super.initState();
    // Set the initial values
    _updateDateController();
    _updateDay();
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  void _updateDay() {
    _selectedDay = DateFormat('EEEE').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Task Date',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.teal, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Day: $_selectedDay',
              style: const TextStyle(fontSize: 16, color: Colors.teal),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLength: _maxDescriptionWords,
              decoration: const InputDecoration(
                labelText: 'Task Description (Max 50 words)',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
              ),
              onChanged: (value) {
                List<String> words = value.trim().split(' ');
                if (words.length > _maxDescriptionWords) {
                  setState(() {
                    _descriptionController.text = words.take(_maxDescriptionWords).join(' ');
                  });
                  _descriptionController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _descriptionController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Task Time',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.teal),
                  onPressed: _selectTime,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.teal)),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.teal, // Text color
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _updateDateController();
        _updateDay();
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay now = TimeOfDay.now(); // Current time
    TimeOfDay initialTime = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year
        ? now
        : TimeOfDay(hour: 0, minute: 0);

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final formattedTime = DateFormat.jm().format(
        DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );

      // Check if the selected time is in the past
      if (_selectedDate.day == DateTime.now().day &&
          _selectedDate.month == DateTime.now().month &&
          _selectedDate.year == DateTime.now().year &&
          (pickedTime.hour < now.hour ||
              (pickedTime.hour == now.hour && pickedTime.minute <= now.minute))) {
        _showPastTimeError();
        return;
      }

      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  // Stylish custom dialog when past time is selected
  void _showPastTimeError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade200, Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_alarm, size: 50, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "You cannot select a past time for today.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.teal, backgroundColor: Colors.white,
                  ),
                  child: const Text("OK"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveTask() async {
    String description = _descriptionController.text.trim();
    String time = _timeController.text.trim();

    if (description.isEmpty || time.isEmpty) {
      _showError('Please enter both description and time!');
      return;
    }

    Map<String, dynamic> task = {
      'description': description,
      'time': time,
      'date': _dateController.text,
      'day': _selectedDay,
    };

    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertTask(task);

    widget.onAdd(description, time, _dateController.text, _selectedDay);

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} */



/* import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd;

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _selectedDay = "";
  DateTime _selectedDate = DateTime.now();
  final int _maxDescriptionWords = 50;

  @override
  void initState() {
    super.initState();
    // Set the initial values
    _updateDateController();
    _updateDay();
  }

  void _updateDateController() {
    _dateController.text = DateFormat('dd MMM yyyy').format(_selectedDate);
  }

  void _updateDay() {
    _selectedDay = DateFormat('EEEE').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Task Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Day: $_selectedDay',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLength: _maxDescriptionWords,
              decoration: const InputDecoration(
                labelText: 'Task Description (Max 50 words)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                List<String> words = value.trim().split(' ');
                if (words.length > _maxDescriptionWords) {
                  setState(() {
                    _descriptionController.text = words.take(_maxDescriptionWords).join(' ');
                  });
                  _descriptionController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _descriptionController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _timeController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Task Time',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _selectTime,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _updateDateController();
        _updateDay();
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      final formattedTime = DateFormat.jm().format(
        DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute),
      );
      setState(() {
        _timeController.text = formattedTime;
      });
    }
  }

  Future<void> _saveTask() async {
    String description = _descriptionController.text.trim();
    String time = _timeController.text.trim();

    if (description.isEmpty || time.isEmpty) {
      _showError('Please enter both description and time!');
      return;
    }

    Map<String, dynamic> task = {
      'description': description,
      'time': time,
      'date': _dateController.text,
      'day': _selectedDay,
    };

    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.insertTask(task);

    widget.onAdd(description, time, _dateController.text, _selectedDay);

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
} */







/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd; // Callback with 4 arguments

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _currentDateTime = ""; // For current date and time
  String _selectedDay = ""; // Automatically set day based on selected date
  DateTime _selectedDate = DateTime.now(); // Default selected date is current date

  // Maximum word limit for description
  final int _maxDescriptionWords = 50;

  @override
  void initState() {
    super.initState();
    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd MMM yyyy').format(now); // Format date
    String formattedTime = DateFormat.jm().format(now); // Format time (e.g., "5:00 PM")
    _currentDateTime = '$formattedDate at $formattedTime'; // Combine date and time

    // Set the initial day based on the current date
    _selectedDay = DateFormat('EEEE').format(now); // Get the full name of the day
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today: $_currentDateTime', // Display formatted current date and time
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Date Picker to select date
            Row(
              children: [
                Text(
                  'Select Date:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate, // Open date picker when tapped
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(
                          text: DateFormat('dd MMM yyyy').format(_selectedDate), // Format selected date
                        ),
                        decoration: InputDecoration(
                          labelText: 'Task Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Display the selected day
            Text(
              'Day: $_selectedDay', // Display automatically selected day
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLength: 50, // Optional: Set max length for description
              decoration: InputDecoration(
                labelText: 'Task Description (Max 50 words)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Limit description to 50 words
                List<String> words = value.trim().split(' ');
                if (words.length > _maxDescriptionWords) {
                  setState(() {
                    _descriptionController.text = words.take(_maxDescriptionWords).join(' ');
                  });
                  _descriptionController.selection = TextSelection.fromPosition(TextPosition(offset: _descriptionController.text.length)); // Move cursor to the end
                }
              },
            ),
            SizedBox(height: 10),
            TextField(
              controller: _timeController,
              readOnly: true, // Make the time field read-only
              decoration: InputDecoration(
                labelText: 'Task Time',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.access_time), // Time picker icon
                  onPressed: _selectTime, // Open time picker when icon is pressed
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String description = _descriptionController.text.trim();
            String time = _timeController.text.trim();
            if (description.isNotEmpty && time.isNotEmpty) {
              widget.onAdd(description, time, DateFormat('dd MMM yyyy').format(_selectedDate), _selectedDay); // Pass values back to parent
              Navigator.of(context).pop(); // Close dialog
            } else {
              // Show error if any field is empty
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter both description and time!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    // Open the date picker
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Use current date as default
      firstDate: DateTime(2020), // Start from 2020 (or any other year)
      lastDate: DateTime(2101), // End at 2101 (or any other year)
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate; // Update selected date
        _selectedDay = DateFormat('EEEE').format(pickedDate); // Update the day based on the selected date
      });
    }
  }

  Future<void> _selectTime() async {
    // Open a time picker
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Format the selected time as a string
      final now = DateTime.now();
      final formattedTime = DateFormat.jm().format(DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
      setState(() {
        _timeController.text = formattedTime; // Update the time controller
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }
} */








/* import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String, String) onAdd; // Callback with 4 arguments

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _currentDateTime = ""; // For current date and time
  String _selectedDay = "Monday"; // Default selected day

  // List of days for dropdown
  final List<String> _days = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    // Get current date and time
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd MMM yyyy').format(now); // Format date
    String formattedTime = DateFormat.jm().format(now); // Format time (e.g., "5:00 PM")
    _currentDateTime = '$formattedDate at $formattedTime'; // Combine date and time
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today: $_currentDateTime', // Display formatted current date and time
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Dropdown to select day
            Row(
              children: [
                Text(
                  'Select Day:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedDay,
                    isExpanded: true,
                    items: _days.map((String day) {
                      return DropdownMenuItem<String>(
                        value: day,
                        child: Text(day),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedDay = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Task Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Task Time (e.g., 5:00 PM)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String description = _descriptionController.text.trim();
            String time = _timeController.text.trim();
            if (description.isNotEmpty && time.isNotEmpty) {
              widget.onAdd(description, time, _currentDateTime, _selectedDay); // Pass values back to parent
              Navigator.of(context).pop(); // Close dialog
            } else {
              // Show error if any field is empty
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter both description and time!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }
} */





/* import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String) onAdd; // Callback with 3 arguments

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd MMM yyyy').format(DateTime.now()); // Format date (e.g., '16 Jan 2025')
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Today Date: $_currentDate', // Display formatted current date
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Task Description',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _timeController,
            decoration: InputDecoration(
              labelText: 'Task Time (e.g., 5:00 PM)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String description = _descriptionController.text.trim();
            String time = _timeController.text.trim();
            if (description.isNotEmpty && time.isNotEmpty) {
              widget.onAdd(description, time, _currentDate); // Pass values back to parent
              Navigator.of(context).pop(); // Close dialog
            } else {
              // Show error if any field is empty
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter both description and time!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }
} */



/* import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package for date formatting

class AddTaskDialog extends StatefulWidget {
  final Function(String, String, String) onAdd; // Callback with 3 arguments

  AddTaskDialog({required this.onAdd});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateFormat('dd MMM yyyy').format(DateTime.now()); // Format date
  }

  Future<void> _selectTime() async {
    // Open a time picker
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Format the selected time as a string
      final now = DateTime.now();
      final formattedTime = DateFormat.jm().format(DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      ));
      setState(() {
        _timeController.text = formattedTime; // Update the time controller
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Today Date: $_currentDate', // Display formatted current date
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Task Description',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _timeController,
            readOnly: true, // Make the time field read-only
            decoration: InputDecoration(
              labelText: 'Task Time',
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.access_time), // Time picker icon
                onPressed: _selectTime, // Open time picker when icon is pressed
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            String description = _descriptionController.text.trim();
            String time = _timeController.text.trim();
            if (description.isNotEmpty && time.isNotEmpty) {
              widget.onAdd(description, time, _currentDate); // Pass values back to parent
              Navigator.of(context).pop(); // Close dialog
            } else {
              // Show error if any field is empty
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please enter both description and time!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _descriptionController.dispose();
    _timeController.dispose();
    super.dispose();
  }
} */

