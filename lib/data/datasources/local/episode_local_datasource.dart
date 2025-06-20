import 'package:hive/hive.dart';
import '../../../domain/entities/episode.dart';

abstract class EpisodeLocalDataSource {
  Future<List<Episode>> getDownloadedEpisodes();
  Future<Episode?> getEpisode(String id);
  Future<void> saveEpisode(Episode episode);
  Future<void> deleteEpisode(String id);
}

class EpisodeLocalDataSourceImpl implements EpisodeLocalDataSource {
  final Box<Map> _episodeBox;

  EpisodeLocalDataSourceImpl(this._episodeBox);

  @override
  Future<List<Episode>> getDownloadedEpisodes() async {
    final episodes = _episodeBox.values
        .where((map) => map['isDownloaded'] == true)
        .map((map) => _mapToEpisode(map))
        .toList();
    return episodes;
  }

  @override
  Future<Episode?> getEpisode(String id) async {
    final map = _episodeBox.get(id);
    if (map == null) return null;
    return _mapToEpisode(map);
  }

  @override
  Future<void> saveEpisode(Episode episode) async {
    await _episodeBox.put(episode.id, _episodeToMap(episode));
  }

  @override
  Future<void> deleteEpisode(String id) async {
    await _episodeBox.delete(id);
  }

  Episode _mapToEpisode(Map map) {
    return Episode(
      id: map['id'] as String,
      podcastId: map['podcastId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
      audioUrl: map['audioUrl'] as String,
      duration: Duration(seconds: map['duration'] as int),
      publishDate: DateTime.parse(map['publishDate'] as String),
      downloadPath: map['downloadPath'] as String?,
      isDownloaded: map['isDownloaded'] as bool? ?? false,
      downloadProgress: map['downloadProgress'] as double? ?? 0.0,
    );
  }

  Map<String, dynamic> _episodeToMap(Episode episode) {
    return {
      'id': episode.id,
      'podcastId': episode.podcastId,
      'title': episode.title,
      'description': episode.description,
      'imageUrl': episode.imageUrl,
      'audioUrl': episode.audioUrl,
      'duration': episode.duration.inSeconds,
      'publishDate': episode.publishDate.toIso8601String(),
      'downloadPath': episode.downloadPath,
      'isDownloaded': episode.isDownloaded,
      'downloadProgress': episode.downloadProgress,
    };
  }
} 