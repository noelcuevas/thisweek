import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'task_model.dart';
import 'archive_model.dart';

class StorageService {
  static const String tasksBoxName = 'tasks';
  static const String archiveBoxName = 'archives';
  static bool _isInitialized = false;

  // Initialize Hive
  static Future<void> init() async {
    if (_isInitialized) return;

    // Initialize Hive with a specific path
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskModelAdapter());
    }

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(WeekArchiveAdapter());
    }

    // Open boxes
    await Hive.openBox<TaskModel>(tasksBoxName);
    await Hive.openBox<WeekArchive>(archiveBoxName);

    debugPrint(
      'Hive initialized: Tasks box location: ${(await getApplicationDocumentsDirectory()).path}',
    );
    _isInitialized = true;
  }

  // Get tasks for a specific date
  static List<Task> getTasksForDate(DateTime date) {
    if (!_isInitialized) {
      debugPrint('Warning: Attempted to access Hive before initialization');
      return [];
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final box = Hive.box<TaskModel>(tasksBoxName);

    debugPrint(
      'Getting tasks for date: $dateKey (found ${box.values.where((task) => task.dateKey == dateKey).length} tasks)',
    );

    final tasks =
        box.values
            .where((task) => task.dateKey == dateKey)
            .map((taskModel) => taskModel.toTask())
            .toList();

    // Sort by time
    tasks.sort(
      (a, b) =>
          a.time.hour != b.time.hour
              ? a.time.hour.compareTo(b.time.hour)
              : a.time.minute.compareTo(b.time.minute),
    );

    return tasks;
  }

  // Save a task for a specific date
  static void saveTask(DateTime date, Task task) {
    if (!_isInitialized) {
      debugPrint('Warning: Attempted to save to Hive before initialization');
      return;
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final box = Hive.box<TaskModel>(tasksBoxName);

    final taskModel = TaskModel.fromTask(task, dateKey);
    box.add(taskModel);
    debugPrint('Task saved: ${task.title} for date $dateKey');
  }

  // Update tasks for a specific date
  static void updateTasksForDate(DateTime date, List<Task> tasks) {
    if (!_isInitialized) {
      debugPrint('Warning: Attempted to update Hive before initialization');
      return;
    }

    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final box = Hive.box<TaskModel>(tasksBoxName);

    // Delete existing tasks for this date
    final keysToDelete =
        box.keys.where((key) {
          final task = box.get(key);
          return task != null && task.dateKey == dateKey;
        }).toList();

    box.deleteAll(keysToDelete);
    debugPrint(
      'Deleted ${keysToDelete.length} existing tasks for date $dateKey',
    );

    // Add updated tasks
    for (final task in tasks) {
      final taskModel = TaskModel.fromTask(task, dateKey);
      box.add(taskModel);
    }
    debugPrint('Added ${tasks.length} updated tasks for date $dateKey');
  }

  // Archive previous week's tasks
  static Future<void> archivePreviousWeek(DateTime currentWeekMonday) async {
    if (!_isInitialized) {
      debugPrint('Warning: Attempted to archive in Hive before initialization');
      return;
    }

    final box = Hive.box<TaskModel>(tasksBoxName);
    final archiveBox = Hive.box<WeekArchive>(archiveBoxName);

    // Calculate previous week's date range
    final previousWeekEndDate = currentWeekMonday.subtract(
      const Duration(days: 1),
    );
    final previousWeekStartDate = previousWeekEndDate.subtract(
      Duration(days: 6),
    );

    final startDateStr = DateFormat('yyyy-MM-dd').format(previousWeekStartDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(previousWeekEndDate);

    // Find all tasks from previous week
    final tasksToArchive =
        box.values.where((task) {
          final taskDate = DateTime.parse(task.dateKey);
          return taskDate.isAfter(
                previousWeekStartDate.subtract(const Duration(days: 1)),
              ) &&
              taskDate.isBefore(currentWeekMonday);
        }).toList();

    if (tasksToArchive.isNotEmpty) {
      // Create archive entry
      final weekArchive = WeekArchive(
        weekStartDate: startDateStr,
        weekEndDate: endDateStr,
        tasks: tasksToArchive,
        archiveDate: DateTime.now(),
      );

      // Save to archive box
      await archiveBox.add(weekArchive);
      debugPrint(
        'Archived ${tasksToArchive.length} tasks for week $startDateStr to $endDateStr',
      );

      // Remove archived tasks from active tasks
      final keysToDelete = tasksToArchive.map((task) => task.key).toList();
      await box.deleteAll(keysToDelete);
    }
  }

  // Get all archives
  static List<WeekArchive> getAllArchives() {
    if (!_isInitialized) {
      debugPrint('Warning: Attempted to access archives before initialization');
      return [];
    }

    final box = Hive.box<WeekArchive>(archiveBoxName);
    return box.values.toList()..sort(
      (a, b) => b.archiveDate.compareTo(a.archiveDate),
    ); // Sort newest first
  }

  // Check if box is open
  static bool isBoxOpen(String boxName) {
    return Hive.isBoxOpen(boxName);
  }

  // Explicitly close boxes when app terminates
  static Future<void> closeBoxes() async {
    if (Hive.isBoxOpen(tasksBoxName)) {
      await Hive.box(tasksBoxName).close();
    }
    if (Hive.isBoxOpen(archiveBoxName)) {
      await Hive.box(archiveBoxName).close();
    }
  }
}
