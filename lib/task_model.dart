import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  final int hour;

  @HiveField(1)
  final int minute;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? note;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  final String dateKey; // Format: 'yyyy-MM-dd'
  // Add timeString getter to format the hour and minute
  String get timeString =>
      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
  TaskModel({
    required this.hour,
    required this.minute,
    required this.title,
    this.note,
    this.isDone = false,
    required this.dateKey,
  });

  // Convert from Task to TaskModel
  factory TaskModel.fromTask(Task task, String dateKey) {
    return TaskModel(
      hour: task.time.hour,
      minute: task.time.minute,
      title: task.title,
      note: task.note,
      isDone: task.isDone,
      dateKey: dateKey,
    );
  }

  // Convert from TaskModel to Task
  Task toTask() {
    return Task(
      time: TimeOfDay(hour: hour, minute: minute),
      title: title,
      note: note,
      isDone: isDone,
    );
  }
}

// Original Task class (keep this for UI compatibility)
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
