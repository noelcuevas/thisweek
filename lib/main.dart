import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For SystemChannels
import 'storage_service.dart';
import 'task_model.dart';
import 'archive_model.dart';
import 'archive_page.dart';

void main() async {
  // This is important - ensures Flutter is initialized before we do anything else
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage first
  await StorageService.init();

  // Register app lifecycle callbacks to properly handle Hive
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    debugPrint('App lifecycle state changed: $msg');
    if (msg == AppLifecycleState.detached.toString()) {
      // App is being terminated, close Hive boxes properly
      await StorageService.closeBoxes();
    }
    return null;
  });

  // Run the app
  runApp(ThisWeekApp());
}

class ThisWeekApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'This Week',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Create animation controller
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _controller.forward();

    // Initialize app and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Check and archive previous week if needed
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (today.weekday == DateTime.monday) {
        await StorageService.archivePreviousWeek(today);
      }

      // Create a smoother transition by adding a delay
      await Future.delayed(Duration(milliseconds: 2500));

      // Mark initialization as complete
      setState(() {
        _isInitialized = true;
      });

      // Navigate to home page
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => ThisWeekHomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Show error state if needed
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animation
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Image.asset(
                      'assets/logo.png',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Progress indicator with animation
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                SizedBox(height: 24),
                // Loading text with animation
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ThisWeekHomePage extends StatefulWidget {
  @override
  _ThisWeekHomePageState createState() => _ThisWeekHomePageState();
}

class _ThisWeekHomePageState extends State<ThisWeekHomePage>
    with WidgetsBindingObserver {
  late DateTime _monday;
  final Map<String, List<Task>> _tasks = {};
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final now = DateTime.now();
    _monday = now.subtract(Duration(days: now.weekday - 1));

    // Check if we need to archive last week
    _checkAndArchivePreviousWeek();

    // Load tasks for the current week - defer to post frame callback to ensure it's safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasksForCurrentWeek();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');
    if (state == AppLifecycleState.resumed) {
      // App resumed from background, reload data - use post frame callback for safety
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTasksForCurrentWeek();
      });
    }
  }

  Future<void> _checkAndArchivePreviousWeek() async {
    // Gets today's date at midnight
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // If today is Monday, archive previous week
    if (today.weekday == DateTime.monday) {
      await StorageService.archivePreviousWeek(today);
    }
  }

  void _loadTasksForCurrentWeek() {
    // Clear existing tasks
    _tasks.clear();

    // Load tasks for each day of the week
    for (int i = 0; i < 7; i++) {
      final date = _monday.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      _tasks[dateKey] = StorageService.getTasksForDate(date);
    }

    if (mounted) {
      setState(() {}); // Refresh UI only if widget is still mounted
    }
  }

  void _addTask(DateTime date, Task task) {
    final key = DateFormat('yyyy-MM-dd').format(date);

    // Check for duplicates by comparing title and time
    bool isDuplicate = false;
    if (_tasks.containsKey(key)) {
      isDuplicate = _tasks[key]!.any(
        (t) =>
            t.title == task.title &&
            t.time.hour == task.time.hour &&
            t.time.minute == task.time.minute,
      );
    }

    if (!isDuplicate) {
      debugPrint('Adding task "${task.title}" for date $key');

      if (mounted) {
        setState(() {
          if (_tasks.containsKey(key)) {
            _tasks[key]!.add(task);
          } else {
            _tasks[key] = [task];
          }
        });
      }

      // Save to Hive
      StorageService.saveTask(date, task);
    } else {
      debugPrint(
        'Task "${task.title}" already exists for date $key, not adding duplicate',
      );
    }
  }

  void _updateTasks(DateTime date, List<Task> updatedTasks) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    debugPrint('Updating ${updatedTasks.length} tasks for date $key');

    if (mounted) {
      setState(() {
        _tasks[key] = List.from(
          updatedTasks,
        ); // Create a new list to avoid reference issues

        // Sort tasks by time
        _tasks[key]!.sort(
          (a, b) =>
              a.time.hour != b.time.hour
                  ? a.time.hour.compareTo(b.time.hour)
                  : a.time.minute.compareTo(b.time.minute),
        );
      });
    }

    // Update in Hive
    StorageService.updateTasksForDate(date, updatedTasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'This Week',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                // Archive button
                IconButton(
                  icon: Icon(Icons.archive_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ArchivePage()),
                    ).then((_) {
                      // Reload data when returning from archive page
                      _loadTasksForCurrentWeek();
                    });
                  },
                  tooltip: 'View Archives',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                final date = _monday.add(Duration(days: index));
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final hasTasks = _tasks[dateStr]?.isNotEmpty ?? false;
                final isToday =
                    date.year == _today.year &&
                    date.month == _today.month &&
                    date.day == _today.day;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DayDetailPage(
                                date: date,
                                tasks: _tasks[dateStr] ?? [],
                                onAddTask: (task) => _addTask(date, task),
                                onUpdateTasks:
                                    (newTasks) => _updateTasks(date, newTasks),
                              ),
                        ),
                      ).then((_) {
                        // Reload tasks when returning from day detail page
                        _loadTasksForCurrentWeek();
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: hasTasks ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${date.day}',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isToday)
                          Container(width: 20, height: 2, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class DayDetailPage extends StatefulWidget {
  final DateTime date;
  final List<Task> tasks;
  final void Function(Task) onAddTask;
  final void Function(List<Task>) onUpdateTasks;

  DayDetailPage({
    required this.date,
    required this.tasks,
    required this.onAddTask,
    required this.onUpdateTasks,
  });

  @override
  _DayDetailPageState createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  late List<Task> localTasks;

  @override
  void initState() {
    super.initState();
    // Move task initialization here to avoid the error
    localTasks = List.from(widget.tasks);

    // Debug: Print the tasks we received but DON'T use context here
    debugPrint('DayDetailPage initialized with ${widget.tasks.length} tasks');
    _logTasksWithoutContext();
  }

  // Function to log tasks without using context
  void _logTasksWithoutContext() {
    for (var task in widget.tasks) {
      // Format time manually without using context
      final hour = task.time.hour;
      final minute = task.time.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute';
      debugPrint('Task: ${task.title} at $timeStr');
    }
  }

  // Format time using a helper function that can be used outside build
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _openAddTaskDialog() async {
    TimeOfDay selectedTime = TimeOfDay.now();
    String title = '';
    String note = '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Add Task"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Task'),
                      onChanged: (value) => title = value,
                    ),
                    TextField(
                      decoration: InputDecoration(labelText: 'Note'),
                      onChanged: (value) => note = value,
                    ),
                    const SizedBox(height: 12),
                    Text('Selected Time: ${selectedTime.format(context)}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      child: Text('Pick Time'),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            selectedTime = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    foregroundColor: Colors.indigo,
                  ),
                  child: Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    foregroundColor: Colors.indigo,
                  ),
                  child: Text('Add'),
                  onPressed: () {
                    if (title.trim().isNotEmpty) {
                      final exists = localTasks.any(
                        (t) =>
                            t.title == title.trim() &&
                            t.time.hour == selectedTime.hour &&
                            t.time.minute == selectedTime.minute,
                      );
                      if (!exists) {
                        final task = Task(
                          time: selectedTime,
                          title: title.trim(),
                          note: note.isNotEmpty ? note.trim() : null,
                        );

                        // Add task to local list first
                        setState(() {
                          localTasks.add(task);
                          _sortTasks();
                        });

                        // Then notify parent to persist the task
                        widget.onAddTask(task);

                        debugPrint('Added new task: ${task.title}');
                      } else {
                        debugPrint('Task already exists, not adding duplicate');
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to sort tasks by time
  void _sortTasks() {
    localTasks.sort(
      (a, b) =>
          a.time.hour != b.time.hour
              ? a.time.hour.compareTo(b.time.hour)
              : a.time.minute.compareTo(b.time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM d').format(widget.date);

    return Scaffold(
      appBar: AppBar(title: Text(dateStr)),
      body:
          localTasks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No tasks yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: localTasks.length,
                itemBuilder: (context, index) {
                  final task = localTasks[index];
                  return GestureDetector(
                    onLongPress: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Center(
                                child: Text(
                                  '${task.time.format(context)} - ${task.title}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              content: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey),
                                      foregroundColor: Colors.indigo,
                                    ),
                                    child: Text('Edit'),
                                    onPressed:
                                        () => Navigator.pop(context, 'edit'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey),
                                      foregroundColor: Colors.indigo,
                                    ),
                                    child: Text('Delete'),
                                    onPressed:
                                        () => Navigator.pop(context, 'delete'),
                                  ),
                                ],
                              ),
                            ),
                      );
                      if (result == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('Confirm Delete'),
                                content: Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey),
                                      foregroundColor: Colors.indigo,
                                    ),
                                    child: Text('Cancel'),
                                    onPressed:
                                        () => Navigator.pop(context, false),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.grey),
                                      foregroundColor: Colors.indigo,
                                    ),
                                    child: Text('Delete'),
                                    onPressed:
                                        () => Navigator.pop(context, true),
                                  ),
                                ],
                              ),
                        );
                        if (confirm == true) {
                          setState(() {
                            localTasks.removeAt(index);
                          });
                          // Update storage after removing task
                          widget.onUpdateTasks(localTasks);
                        }
                      } else if (result == 'edit') {
                        TimeOfDay selectedTime = task.time;
                        String title = task.title;
                        String note = task.note ?? '';
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  title: Text("Edit Task"),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextField(
                                          controller: TextEditingController(
                                            text: title,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Task',
                                          ),
                                          onChanged: (value) => title = value,
                                        ),
                                        TextField(
                                          controller: TextEditingController(
                                            text: note,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Note',
                                          ),
                                          onChanged: (value) => note = value,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Selected Time: ${selectedTime.format(context)}',
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          child: Text('Pick Time'),
                                          onPressed: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: selectedTime,
                                            );
                                            if (picked != null) {
                                              setStateDialog(
                                                () => selectedTime = picked,
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.grey),
                                        foregroundColor: Colors.indigo,
                                      ),
                                      child: Text('Cancel'),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.grey),
                                        foregroundColor: Colors.indigo,
                                      ),
                                      child: Text('Save'),
                                      onPressed: () {
                                        if (title.trim().isNotEmpty) {
                                          setState(() {
                                            localTasks[index] = Task(
                                              time: selectedTime,
                                              title: title.trim(),
                                              note:
                                                  note.isNotEmpty
                                                      ? note.trim()
                                                      : null,
                                              isDone: task.isDone,
                                            );
                                            _sortTasks();
                                          });
                                          // Update in storage
                                          widget.onUpdateTasks(localTasks);
                                          Navigator.pop(context);
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                    child: ExpansionTile(
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (val) {
                          setState(() {
                            task.isDone = val ?? false;
                          });
                          // Update in storage when task completion status changes
                          widget.onUpdateTasks(localTasks);
                        },
                      ),
                      title: Text(
                        '${task.time.format(context)} - ${task.title}',
                        style: TextStyle(
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 72.0,
                            right: 16.0,
                            top: 4.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                task.note != null && task.note!.isNotEmpty
                                    ? Icons.article_outlined
                                    : Icons.note_add_outlined,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child:
                                    task.note != null && task.note!.isNotEmpty
                                        ? Text(task.note!)
                                        : Text('No notes yet'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTaskDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
