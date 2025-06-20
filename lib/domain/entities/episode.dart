import 'package:equatable/equatable.dart';

enum EpisodePlayStatus {
  notPlayed,
  playing,
  paused,
  completed,
}

class Episode extends Equatable {
  final String id;
  final String podcastId;
  final String title;
  final String description;
  final String imageUrl;
  final String audioUrl;
  final Duration duration;
  final DateTime publishDate;
  final String? downloadPath;
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  final bool isPlayed;
  final Duration? position;
  final int? episodeNumber;
  final int? seasonNumber;

  const Episode({
    required this.id,
    required this.podcastId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.audioUrl,
    required this.duration,
    required this.publishDate,
    this.downloadPath,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isPlayed = false,
    this.position,
    this.episodeNumber,
    this.seasonNumber,
  });

  @override
  List<Object?> get props => [
    id,
    podcastId,
    title,
    description,
    imageUrl,
    audioUrl,
    duration,
    publishDate,
    downloadPath,
    isDownloaded,
    isDownloading,
    downloadProgress,
    isPlayed,
    position,
    episodeNumber,
    seasonNumber,
  ];

  Episode copyWith({
    String? id,
    String? podcastId,
    String? title,
    String? description,
    String? imageUrl,
    String? audioUrl,
    Duration? duration,
    DateTime? publishDate,
    String? downloadPath,
    bool? isDownloaded,
    bool? isDownloading,
    double? downloadProgress,
    bool? isPlayed,
    Duration? position,
    int? episodeNumber,
    int? seasonNumber,
  }) {
    return Episode(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
      publishDate: publishDate ?? this.publishDate,
      downloadPath: downloadPath ?? this.downloadPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isPlayed: isPlayed ?? this.isPlayed,
      position: position ?? this.position,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      seasonNumber: seasonNumber ?? this.seasonNumber,
    );
  }

  // 計算播放進度百分比
  double get progressPercent {
    if (duration == Duration.zero) return 0.0;
    return position?.inMilliseconds?.toDouble() ?? 0.0 / duration.inMilliseconds;
  }

  // 是否正在播放
  bool get isPlaying => isPlayed;

  // 是否暫停
  bool get isPaused => !isPlayed;

  // 格式化持續時間
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // 格式化當前位置
  String get formattedCurrentPosition {
    if (position == null) return '0:00';
    final hours = position!.inHours;
    final minutes = position!.inMinutes.remainder(60);
    final seconds = position!.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

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
    };
  }

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
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
    );
  }

  factory Episode.empty() {
    return Episode(
      id: '',
      podcastId: '',
      title: '',
      description: '',
      imageUrl: '',
      audioUrl: '',
      duration: Duration.zero,
      publishDate: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Episode{id: $id, title: $title, isDownloaded: $isDownloaded, isDownloading: $isDownloading, progress: $downloadProgress}';
  }
} 