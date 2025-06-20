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
      podcastId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String,
      imageUrl: fields[4] as String,
      audioUrl: fields[5] as String,
      duration: Duration(milliseconds: fields[6] as int),
      publishDate: fields[7] as DateTime,
      downloadPath: fields[8] as String?,
      isDownloaded: fields[9] as bool? ?? false,
      isDownloading: fields[10] as bool? ?? false,
      downloadProgress: fields[11] as double? ?? 0.0,
      isPlayed: fields[12] as bool? ?? false,
      position: fields[13] != null ? Duration(milliseconds: fields[13] as int) : null,
      episodeNumber: fields[14] as int?,
      seasonNumber: fields[15] as int?,
      guid: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EpisodeModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.podcastId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.audioUrl)
      ..writeByte(6)
      ..write(obj.duration.inMilliseconds)
      ..writeByte(7)
      ..write(obj.publishDate)
      ..writeByte(8)
      ..write(obj.downloadPath)
      ..writeByte(9)
      ..write(obj.isDownloaded)
      ..writeByte(10)
      ..write(obj.isDownloading)
      ..writeByte(11)
      ..write(obj.downloadProgress)
      ..writeByte(12)
      ..write(obj.isPlayed)
      ..writeByte(13)
      ..write(obj.position?.inMilliseconds)
      ..writeByte(14)
      ..write(obj.episodeNumber)
      ..writeByte(15)
      ..write(obj.seasonNumber)
      ..writeByte(16)
      ..write(obj.guid);
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