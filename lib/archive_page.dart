import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'storage_service.dart';
import 'archive_model.dart';
import 'task_model.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late List<WeekArchive> _archives;
  int? _selectedIndex;
  final List<ExpansionTileController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _loadArchives();
  }

  void _loadArchives() {
    _archives = StorageService.getAllArchives();
    setState(() {});
  }

  Map<String, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
    final Map<String, List<TaskModel>> tasksByDate = {};
    for (final task in tasks) {
      if (!tasksByDate.containsKey(task.dateKey)) {
        tasksByDate[task.dateKey] = [];
      }
      tasksByDate[task.dateKey]!.add(task);
    }
    return tasksByDate;
  }

  List<String> _getSortedDates(Map<String, List<TaskModel>> tasksByDate) {
    final dates = tasksByDate.keys.toList();
    dates.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    return dates;
  }

  void _sortTasksByTime(List<TaskModel> tasks) {
    tasks.sort((a, b) {
      if (a.hour != b.hour) return a.hour - b.hour;
      return a.minute - b.minute;
    });
  }

  String _formatTimeString(TaskModel task) {
    final hour = task.hour;
    final minute = task.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }

  String _getDayName(String dateKey) {
    final date = DateTime.parse(dateKey);
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color highlightColor = primaryColor.withOpacity(0.15);
    final double cardBorderRadius = 15.0;
    final double taskBorderRadius = 8.0;

    if (_controllers.length < _archives.length) {
      for (int i = _controllers.length; i < _archives.length; i++) {
        _controllers.add(ExpansionTileController());
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Archives')),
      body:
          _archives.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No archives yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Archives will appear when a new week starts',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: _archives.length,
                itemBuilder: (context, index) {
                  final archive = _archives[index];
                  final tasksByDate = _groupTasksByDate(archive.tasks);
                  final sortedDates = _getSortedDates(tasksByDate);
                  for (final date in sortedDates) {
                    _sortTasksByTime(tasksByDate[date]!);
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(cardBorderRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        splashColor: highlightColor,
                        highlightColor: highlightColor,
                      ),
                      child: Stack(
                        children: [
                          ExpansionTile(
                            controller: _controllers[index],
                            initiallyExpanded: _selectedIndex == index,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _selectedIndex = expanded ? index : null;
                              });
                            },
                            title: Text(
                              'Week of ${DateFormat('MMM d').format(DateTime.parse(archive.weekStartDate))} - ${DateFormat('MMM d, yyyy').format(DateTime.parse(archive.weekEndDate))}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${archive.tasks.length} tasks'),
                            children: [
                              for (final dateKey in sortedDates)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                          top: 8.0,
                                          bottom: 4.0,
                                        ),
                                        child: Text(
                                          _getDayName(dateKey),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                      ),
                                      for (final task in tasksByDate[dateKey]!)
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              taskBorderRadius,
                                            ),
                                            splashColor: highlightColor,
                                            highlightColor: highlightColor,
                                            onTap:
                                                task.note != null &&
                                                        task.note!.isNotEmpty
                                                    ? () {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (
                                                              context,
                                                            ) => AlertDialog(
                                                              title: Text(
                                                                task.title,
                                                              ),
                                                              content: Text(
                                                                task.note!,
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  child:
                                                                      const Text(
                                                                        'Close',
                                                                      ),
                                                                  onPressed:
                                                                      () => Navigator.pop(
                                                                        context,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                      );
                                                    }
                                                    : null,
                                            child: Container(
                                              width: double.infinity,
                                              child: ListTile(
                                                dense: true,
                                                leading: Icon(
                                                  task.isDone
                                                      ? Icons.check_circle
                                                      : Icons.circle_outlined,
                                                  color:
                                                      task.isDone
                                                          ? Colors.green
                                                          : Colors.grey,
                                                ),
                                                title: Text(
                                                  task.title,
                                                  style: TextStyle(
                                                    decoration:
                                                        task.isDone
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : null,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  _formatTimeString(task),
                                                ),
                                                trailing:
                                                    task.note != null &&
                                                            task
                                                                .note!
                                                                .isNotEmpty
                                                        ? const Icon(
                                                          Icons
                                                              .article_outlined,
                                                          color: Colors.grey,
                                                          size: 16,
                                                        )
                                                        : null,
                                                onTap: null,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 74,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: highlightColor,
                                highlightColor: highlightColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(cardBorderRadius),
                                  topRight: Radius.circular(cardBorderRadius),
                                  bottomLeft:
                                      _selectedIndex == index
                                          ? Radius.zero
                                          : Radius.circular(cardBorderRadius),
                                  bottomRight:
                                      _selectedIndex == index
                                          ? Radius.zero
                                          : Radius.circular(cardBorderRadius),
                                ),
                                onTap: () {
                                  final isCurrentlyExpanded =
                                      _selectedIndex == index;
                                  if (isCurrentlyExpanded) {
                                    _controllers[index].collapse();
                                    setState(() {
                                      _selectedIndex = null;
                                    });
                                  } else {
                                    if (_selectedIndex != null) {
                                      _controllers[_selectedIndex!].collapse();
                                    }
                                    _controllers[index].expand();
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  }
                                },
                              ),
                            ),
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
