import 'package:dio/dio.dart';
import '../../../domain/entities/episode.dart';

abstract class EpisodeRemoteDataSource {
  Future<List<Episode>> getEpisodesByPodcastId(String podcastId);
  Future<Episode?> getEpisodeById(String id);
}

class EpisodeRemoteDataSourceImpl implements EpisodeRemoteDataSource {
  final Dio _dio;

  EpisodeRemoteDataSourceImpl(this._dio);

  @override
  Future<List<Episode>> getEpisodesByPodcastId(String podcastId) async {
    try {
      final response = await _dio.get('/podcasts/$podcastId/episodes');
      final List<dynamic> episodesJson = response.data['episodes'];
      return episodesJson.map((json) => Episode(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        audioUrl: json['audioUrl'],
        imageUrl: json['imageUrl'],
        duration: Duration(seconds: json['duration']),
        publishDate: DateTime.parse(json['publishDate']),
        podcastId: json['podcastId'],
        guid: json['guid'],
        isPlayed: false,
        isDownloaded: false,
        episodeNumber: json['episodeNumber'],
        seasonNumber: json['seasonNumber'],
      )).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Episode?> getEpisodeById(String id) async {
    try {
      final response = await _dio.get('/episodes/$id');
      final json = response.data;
      return Episode(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        audioUrl: json['audioUrl'],
        imageUrl: json['imageUrl'],
        duration: Duration(seconds: json['duration']),
        publishDate: DateTime.parse(json['publishDate']),
        podcastId: json['podcastId'],
        guid: json['guid'],
        isPlayed: false,
        isDownloaded: false,
        episodeNumber: json['episodeNumber'],
        seasonNumber: json['seasonNumber'],
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
} 