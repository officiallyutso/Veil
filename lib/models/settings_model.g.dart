// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 0;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      useSystemColors: fields[0] as bool,
      themeMode: fields[1] as ThemeMode,
      enableJavaScript: fields[2] as bool,
      blockTrackers: fields[3] as bool,
      enableIncognitoByDefault: fields[4] as bool,
      defaultSearchEngine: fields[5] as String,
      enableFocusMode: fields[6] as bool,
      focusModeTimeLimit: fields[7] as int,
      enableGestureNavigation: fields[8] as bool,
      enableGlassMode: fields[9] as bool,
      adaptToLighting: fields[10] as bool,
      activePersona: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.useSystemColors)
      ..writeByte(1)
      ..write(obj.themeMode)
      ..writeByte(2)
      ..write(obj.enableJavaScript)
      ..writeByte(3)
      ..write(obj.blockTrackers)
      ..writeByte(4)
      ..write(obj.enableIncognitoByDefault)
      ..writeByte(5)
      ..write(obj.defaultSearchEngine)
      ..writeByte(6)
      ..write(obj.enableFocusMode)
      ..writeByte(7)
      ..write(obj.focusModeTimeLimit)
      ..writeByte(8)
      ..write(obj.enableGestureNavigation)
      ..writeByte(9)
      ..write(obj.enableGlassMode)
      ..writeByte(10)
      ..write(obj.adaptToLighting)
      ..writeByte(11)
      ..write(obj.activePersona);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonaAdapter extends TypeAdapter<Persona> {
  @override
  final int typeId = 1;

  @override
  Persona read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Persona(
      name: fields[0] as String,
      blockTrackers: fields[1] as bool,
      enableJavaScript: fields[2] as bool,
      clearCookiesOnExit: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Persona obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.blockTrackers)
      ..writeByte(2)
      ..write(obj.enableJavaScript)
      ..writeByte(3)
      ..write(obj.clearCookiesOnExit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
