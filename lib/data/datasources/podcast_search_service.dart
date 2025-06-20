import 'package:podcast_search/podcast_search.dart' as ps;
import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/podcast.dart';
import '../../domain/entities/episode.dart';
import '../../core/constants/app_constants.dart';

class PodcastSearchService {
  static PodcastSearchService? _instance;
  static PodcastSearchService get instance {
    _instance ??= PodcastSearchService._internal();
    return _instance!;
  }

  PodcastSearchService._internal();

  final ps.Search _search = ps.Search();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: AppConstants.networkTimeout,
    receiveTimeout: AppConstants.networkTimeout,
  ));

  /// 搜尋 Podcast 頻道
  Future<List<Podcast>> searchPodcasts(String query) async {
    try {
      final searchResult = await _search.search(
        query,
        country: ps.Country.taiwan,
        limit: 50,
      );

      if (searchResult.resultCount > 0) {
        return searchResult.items
            .map((item) => _searchResultToPodcast(item))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('搜尋失敗: $e');
    }
  }

  /// 獲取熱門 Podcast
  Future<List<Podcast>> getTopPodcasts() async {
    try {
      final charts = await _search.charts(
        country: ps.Country.taiwan,
        limit: 50,
      );

      return charts.items
          .map((item) => _searchResultToPodcast(item))
          .toList();
    } catch (e) {
      throw Exception('獲取熱門 Podcast 失敗: $e');
    }
  }

  /// 解析 RSS Feed 獲取集數資訊
  Future<List<Episode>> getPodcastEpisodes(String feedUrl) async {
    try {
      final response = await _dio.get(feedUrl);
      final document = XmlDocument.parse(response.data);
      
      final channel = document.findAllElements('channel').first;
      final podcastId = _generatePodcastId(feedUrl);
      
      final episodes = <Episode>[];
      final items = channel.findAllElements('item');
      
      for (var i = 0; i < items.length; i++) {
        final item = items.elementAt(i);
        final episode = _parseEpisodeFromXml(item, podcastId, i + 1);
        if (episode != null) {
          episodes.add(episode);
        }
      }
      
      return episodes;
    } catch (e) {
      throw Exception('解析 RSS Feed 失敗: $e');
    }
  }

  /// 獲取 Podcast 詳細資訊
  Future<Podcast?> getPodcastDetails(String podcastId) async {
    // 這個功能暫時不可用，返回 null
    return null;
  }

  // 私有方法
  Podcast _searchResultToPodcast(ps.Item item) {
    return Podcast(
      id: item.trackId.toString(),
      title: item.trackName ?? '未知標題',
      description: item.trackViewUrl ?? '',
      imageUrl: item.artworkUrl600 ?? item.artworkUrl100 ?? '',
      feedUrl: item.feedUrl ?? '',
      author: item.artistName ?? '未知作者',
      category: item.primaryGenreName ?? '未知分類',
      language: 'zh-TW',
      lastUpdate: DateTime.now(),
      episodeCount: item.trackCount ?? 0,
      categories: [
        if (item.primaryGenreName != null) item.primaryGenreName!,
      ],
    );
  }

  Episode? _parseEpisodeFromXml(XmlElement item, String podcastId, int episodeNumber) {
    try {
      final title = item.findElements('title').firstOrNull?.innerText ?? '未知標題';
      final description = item.findElements('description').firstOrNull?.innerText ?? 
                         item.findElements('itunes:summary').firstOrNull?.innerText ?? '';
      
      // 查找音訊 URL
      final enclosure = item.findElements('enclosure').firstOrNull;
      final audioUrl = enclosure?.getAttribute('url') ?? '';
      
      if (audioUrl.isEmpty) return null;
      
      // 解析發布日期
      final pubDateText = item.findElements('pubDate').firstOrNull?.innerText ?? '';
      DateTime publishDate;
      try {
        publishDate = DateTime.parse(pubDateText);
      } catch (e) {
        publishDate = DateTime.now();
      }
      
      // 解析持續時間
      final durationText = item.findElements('itunes:duration').firstOrNull?.innerText ?? '0';
      Duration duration = _parseDuration(durationText);
      
      // 獲取圖片 URL
      final imageElement = item.findElements('itunes:image').firstOrNull;
      final imageUrl = imageElement?.getAttribute('href') ?? '';
      
      // 獲取 GUID
      final guid = item.findElements('guid').firstOrNull?.innerText ?? 
                   DateTime.now().millisecondsSinceEpoch.toString();
      
      return Episode(
        id: _generateEpisodeId(podcastId, guid),
        podcastId: podcastId,
        title: title,
        description: description,
        audioUrl: audioUrl,
        imageUrl: imageUrl,
        duration: duration,
        publishDate: publishDate,
        episodeNumber: episodeNumber,
        seasonNumber: 1, // 預設為第一季
        guid: guid,
      );
    } catch (e) {
      return null;
    }
  }

  Duration _parseDuration(String durationText) {
    try {
      // 支援不同格式：HH:MM:SS, MM:SS, 秒數
      if (durationText.contains(':')) {
        final parts = durationText.split(':').map(int.parse).toList();
        if (parts.length == 3) {
          return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
        } else if (parts.length == 2) {
          return Duration(minutes: parts[0], seconds: parts[1]);
        }
      } else {
        final seconds = int.tryParse(durationText) ?? 0;
        return Duration(seconds: seconds);
      }
    } catch (e) {
      // 解析失敗時返回零長度
    }
    return Duration.zero;
  }

  String _generatePodcastId(String feedUrl) {
    return feedUrl.hashCode.toString();
  }

  String _generateEpisodeId(String podcastId, String guid) {
    return '${podcastId}_${guid.hashCode}';
  }

  /// 驗證 RSS Feed URL
  Future<bool> validateFeedUrl(String feedUrl) async {
    try {
      final response = await _dio.head(feedUrl);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 搜尋建議
  Future<List<String>> getSearchSuggestions(String query) async {
    // 這裡可以實現搜尋建議功能
    // 目前返回一些常見的 podcast 分類作為建議
    final suggestions = [
      '新聞',
      '商業',
      '科技',
      '健康',
      '教育',
      '娛樂',
      '音樂',
      '體育',
      '歷史',
      '科學',
    ];
    
    return suggestions
        .where((suggestion) => 
            suggestion.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void dispose() {
    _dio.close();
  }
} 