// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeekArchiveAdapter extends TypeAdapter<WeekArchive> {
  @override
  final int typeId = 1;

  @override
  WeekArchive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeekArchive(
      weekStartDate: fields[0] as String,
      weekEndDate: fields[1] as String,
      tasks: (fields[2] as List).cast<TaskModel>(),
      archiveDate: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeekArchive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.weekStartDate)
      ..writeByte(1)
      ..write(obj.weekEndDate)
      ..writeByte(2)
      ..write(obj.tasks)
      ..writeByte(3)
      ..write(obj.archiveDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeekArchiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
