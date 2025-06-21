import 'package:dio/dio.dart';
import '../../../domain/entities/podcast.dart';
import '../../../domain/entities/episode.dart';
import '../podcast_search_service.dart';

abstract class PodcastRemoteDataSource {
  Future<List<Podcast>> getPopularPodcasts(String category);
  Future<Podcast?> getPodcastById(String id);
  Future<List<Podcast>> searchPodcasts(String query);
  Future<List<Podcast>> getTopPodcasts();
  Future<List<Episode>> getPodcastEpisodes(String feedUrl);
}

class PodcastRemoteDataSourceImpl implements PodcastRemoteDataSource {
  final Dio _dio;
  late final PodcastSearchService _searchService;

  PodcastRemoteDataSourceImpl(this._dio) {
    _searchService = PodcastSearchService.instance;
  }

  @override
  Future<List<Podcast>> getPopularPodcasts(String category) async {
    try {
      final response = await _dio.get(
        '/podcasts/popular',
        queryParameters: {
          if (category.isNotEmpty) 'category': category,
        },
      );
      final List<dynamic> podcastsJson = response.data['podcasts'];
      return podcastsJson.map((json) => Podcast(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        feedUrl: json['feedUrl'],
        author: json['author'],
        category: json['category'],
        language: json['language'],
        isSubscribed: false,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        lastUpdate: DateTime.parse(json['lastUpdate']),
        episodeCount: json['episodeCount'] ?? 0,
        categories: List<String>.from(json['categories'] ?? []),
      )).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Podcast?> getPodcastById(String id) async {
    try {
      final response = await _dio.get('/podcasts/$id');
      final json = response.data;
      return Podcast(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        feedUrl: json['feedUrl'],
        author: json['author'],
        category: json['category'],
        language: json['language'],
        isSubscribed: false,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
        lastUpdate: DateTime.parse(json['lastUpdate']),
        episodeCount: json['episodeCount'] ?? 0,
        categories: List<String>.from(json['categories'] ?? []),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<Podcast>> searchPodcasts(String query) async {
    try {
      // 使用 PodcastSearchService 進行真實的搜尋
      return await _searchService.searchPodcasts(query);
    } catch (e) {
      throw Exception('搜尋 Podcast 失敗: $e');
    }
  }

  @override
  Future<List<Podcast>> getTopPodcasts() async {
    try {
      return await _searchService.getTopPodcasts();
    } catch (e) {
      throw Exception('獲取熱門 Podcast 失敗: $e');
    }
  }

  @override
  Future<List<Episode>> getPodcastEpisodes(String feedUrl) async {
    try {
      return await _searchService.getPodcastEpisodes(feedUrl);
    } catch (e) {
      throw Exception('獲取 Podcast 集數失敗: $e');
    }
  }
} 