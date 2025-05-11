import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
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
      home: ThisWeekHomePage(),
    );
  }
}

class ThisWeekHomePage extends StatefulWidget {
  @override
  _ThisWeekHomePageState createState() => _ThisWeekHomePageState();
}

class _ThisWeekHomePageState extends State<ThisWeekHomePage> {
  late DateTime _monday;
  final Map<String, List<Task>> _tasks = {};
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monday = now.subtract(Duration(days: now.weekday - 1));
  }

  void _addTask(DateTime date, Task task) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      if (_tasks.containsKey(key)) {
        final exists = _tasks[key]!.any(
              (t) =>
          t.title == task.title &&
              t.time.hour == task.time.hour &&
              t.time.minute == task.time.minute,
        );
        if (!exists) {
          _tasks[key]!.add(task);
        }
      } else {
        _tasks[key] = [task];
      }
    });
  }

  void _updateTasks(DateTime date, List<Task> updatedTasks) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      _tasks[key] = updatedTasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'This Week',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                      );
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

class Task {
  final TimeOfDay time;
  final String title;
  final String? note;
  bool isDone;

  Task({
    required this.time,
    required this.title,
    this.note,
    this.isDone = false,
  });
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
    localTasks = List.from(widget.tasks);
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
                          title: title,
                          note: note.isNotEmpty ? note : null,
                        );
                        widget.onAddTask(task);
                        widget.onUpdateTasks([...localTasks, task]);
                        setState(() {
                          localTasks = [...localTasks, task];
                          localTasks.sort(
                                (a, b) =>
                            a.time.hour != b.time.hour
                                ? a.time.hour.compareTo(b.time.hour)
                                : a.time.minute.compareTo(b.time.minute),
                          );
                        });
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
                  setState(() => localTasks.removeAt(index));
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
                                      title: title,
                                      note:
                                      note.isNotEmpty ? note : null,
                                      isDone: task.isDone,
                                    );
                                    localTasks.sort(
                                          (a, b) =>
                                      a.time.hour != b.time.hour
                                          ? a.time.hour.compareTo(
                                        b.time.hour,
                                      )
                                          : a.time.minute.compareTo(
                                        b.time.minute,
                                      ),
                                    );
                                  });
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
                    widget.onUpdateTasks(localTasks);
                  });
                },
              ),
              title: Text(
                '${task.time.format(context)} - ${task.title}',
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
                        task.note != null
                            ? Icons.article_outlined
                            : Icons.note_add_outlined,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child:
                        task.note != null
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
