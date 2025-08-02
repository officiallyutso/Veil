// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tab_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TabAdapter extends TypeAdapter<Tab> {
  @override
  final int typeId = 2;

  @override
  Tab read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tab(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      favicon: fields[3] as String,
      isIncognito: fields[4] as bool,
      scrollPosition: fields[5] as double,
      lastAccessed: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Tab obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.favicon)
      ..writeByte(4)
      ..write(obj.isIncognito)
      ..writeByte(5)
      ..write(obj.scrollPosition)
      ..writeByte(6)
      ..write(obj.lastAccessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 3;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      name: fields[1] as String,
      tabs: (fields[2] as List).cast<Tab>(),
      createdAt: fields[3] as DateTime?,
      lastAccessed: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.tabs)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.lastAccessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
