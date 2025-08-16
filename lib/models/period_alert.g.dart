// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeriodAlertAdapter extends TypeAdapter<PeriodAlert> {
  @override
  final int typeId = 3;

  @override
  PeriodAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PeriodAlert(
      message: fields[0] as String,
      timestamp: fields[1] as DateTime,
      type: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PeriodAlert obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeriodAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
