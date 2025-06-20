import 'package:hive/hive.dart';
import '../../domain/entities/episode.dart';

part 'episode_model.g.dart';

@HiveType(typeId: 1)
class EpisodeModel extends Episode {
  const EpisodeModel({
    required String id,
    required String podcastId,
    required String title,
    required String description,
    required String imageUrl,
    required String audioUrl,
    required Duration duration,
    required DateTime publishDate,
    String? downloadPath,
    bool isDownloaded = false,
    bool isDownloading = false,
    double downloadProgress = 0.0,
    bool isPlayed = false,
    Duration? position,
    int? episodeNumber,
    int? seasonNumber,
    String? guid,
  }) : super(
          id: id,
          podcastId: podcastId,
          title: title,
          description: description,
          imageUrl: imageUrl,
          audioUrl: audioUrl,
          duration: duration,
          publishDate: publishDate,
          downloadPath: downloadPath,
          isDownloaded: isDownloaded,
          isDownloading: isDownloading,
          downloadProgress: downloadProgress,
          isPlayed: isPlayed,
          position: position,
          episodeNumber: episodeNumber,
          seasonNumber: seasonNumber,
          guid: guid,
        );

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    return EpisodeModel(
      id: json['id'] as String,
      podcastId: json['podcastId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      audioUrl: json['audioUrl'] as String,
      duration: Duration(seconds: json['duration'] as int),
      publishDate: DateTime.parse(json['publishDate'] as String),
      downloadPath: json['downloadPath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      isDownloading: json['isDownloading'] as bool? ?? false,
      downloadProgress: json['downloadProgress'] as double? ?? 0.0,
      isPlayed: json['isPlayed'] as bool? ?? false,
      position: json['position'] != null
          ? Duration(seconds: json['position'] as int)
          : null,
      episodeNumber: json['episodeNumber'] as int?,
      seasonNumber: json['seasonNumber'] as int?,
      guid: json['guid'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcastId': podcastId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration.inSeconds,
      'publishDate': publishDate.toIso8601String(),
      'downloadPath': downloadPath,
      'isDownloaded': isDownloaded,
      'isDownloading': isDownloading,
      'downloadProgress': downloadProgress,
      'isPlayed': isPlayed,
      'position': position?.inSeconds,
      'episodeNumber': episodeNumber,
      'seasonNumber': seasonNumber,
      'guid': guid,
    };
  }

  factory EpisodeModel.fromEntity(Episode episode) {
    return EpisodeModel(
      id: episode.id,
      podcastId: episode.podcastId,
      title: episode.title,
      description: episode.description,
      imageUrl: episode.imageUrl,
      audioUrl: episode.audioUrl,
      duration: episode.duration,
      publishDate: episode.publishDate,
      downloadPath: episode.downloadPath,
      isDownloaded: episode.isDownloaded,
      isDownloading: episode.isDownloading,
      downloadProgress: episode.downloadProgress,
      isPlayed: episode.isPlayed,
      position: episode.position,
      episodeNumber: episode.episodeNumber,
      seasonNumber: episode.seasonNumber,
      guid: episode.guid,
    );
  }
} 