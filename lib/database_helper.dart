import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version to allow future migrations
      onCreate: (db, version) {
        db.execute(''' 
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            time TEXT,
            date TEXT,
            day TEXT,
            status INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute('ALTER TABLE tasks ADD COLUMN status INTEGER DEFAULT 0');
        }
      },
    );
  }

  // Insert a new task into the database
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    return await db.insert('tasks', task);
  }

  // Retrieve all tasks from the database
  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return await db.query('tasks', orderBy: 'id DESC');
  }

  // Delete a task by ID
  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Update a task (not just status)
  Future<int> updateTask(int id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update('tasks', values, where: 'id = ?', whereArgs: [id]);
  }

  // Mark a task as completed by updating its status
  Future<int> updateTaskStatus(int id, int status) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'status': status}, // Update only the 'status' column
      where: 'id = ?', // Update the row with the given ID
      whereArgs: [id],
    );
  }

  // Retrieve tasks by date and day
  Future<List<Map<String, dynamic>>> getTasksByDateAndDay(String date, String day) async {
    final db = await database;
    return await db.query(
      'tasks',
      where: 'date = ? AND day = ?',
      whereArgs: [date, day],
    );
  }

  // Delete all tasks for a specific day and date
  Future<int> deleteTasksForDay(String day, String date) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'day = ? AND date = ?',
      whereArgs: [day, date],
    );
  }
}
