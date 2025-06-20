// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'podcast_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PodcastModelAdapter extends TypeAdapter<PodcastModel> {
  @override
  final int typeId = 2;

  @override
  PodcastModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PodcastModel(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String,
      imageUrl: fields[4] as String,
      feedUrl: fields[5] as String,
      categories: (fields[6] as List?)?.cast<String>() ?? [],
      lastUpdated: fields[7] as DateTime,
      category: fields[8] as String,
      language: fields[9] as String,
      isSubscribed: fields[10] as bool? ?? false,
      createdAt: fields[11] as DateTime?,
      episodeCount: fields[12] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, PodcastModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.author)
      ..writeByte(5)
      ..write(obj.feedUrl)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.language)
      ..writeByte(8)
      ..write(obj.isSubscribed)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.episodeCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PodcastModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
} 