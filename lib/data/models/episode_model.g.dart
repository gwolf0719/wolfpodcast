// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EpisodeModelAdapter extends TypeAdapter<EpisodeModel> {
  @override
  final int typeId = 1;

  @override
  EpisodeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EpisodeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      audioUrl: fields[3] as String,
      imageUrl: fields[4] as String,
      duration: fields[5] as Duration,
      publishDate: fields[6] as DateTime,
      podcastId: fields[7] as String,
      isPlayed: fields[8] as bool,
      position: fields[9] as Duration?,
      downloadPath: fields[10] as String?,
      isDownloaded: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.audioUrl)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.publishDate)
      ..writeByte(7)
      ..write(obj.podcastId)
      ..writeByte(8)
      ..write(obj.isPlayed)
      ..writeByte(9)
      ..write(obj.position)
      ..writeByte(10)
      ..write(obj.downloadPath)
      ..writeByte(11)
      ..write(obj.isDownloaded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpisodeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
