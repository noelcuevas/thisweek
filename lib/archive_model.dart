import 'package:hive/hive.dart';
import 'task_model.dart';

part 'archive_model.g.dart';

@HiveType(typeId: 1)
class WeekArchive extends HiveObject {
  @HiveField(0)
  final String weekStartDate; // Format: 'yyyy-MM-dd'

  @HiveField(1)
  final String weekEndDate; // Format: 'yyyy-MM-dd'

  @HiveField(2)
  final List<TaskModel> tasks;

  @HiveField(3)
  final DateTime archiveDate;

  WeekArchive({
    required this.weekStartDate,
    required this.weekEndDate,
    required this.tasks,
    required this.archiveDate,
  });
}
