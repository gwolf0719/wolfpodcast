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
    headers: {
      'User-Agent': AppConstants.userAgent,
      'Accept': 'application/rss+xml, application/xml, text/xml, */*',
    },
    followRedirects: true,
    maxRedirects: 5,
  ));

  /// Apple Podcasts 分類列表
  static const List<PodcastCategory> categories = [
    PodcastCategory(id: 'arts', name: '藝術', englishName: 'Arts', subcategories: [
      'books', 'design', 'fashion-beauty', 'food', 'performing-arts', 'visual-arts'
    ]),
    PodcastCategory(id: 'business', name: '商業', englishName: 'Business', subcategories: [
      'careers', 'entrepreneurship', 'investing', 'management', 'marketing', 'non-profit'
    ]),
    PodcastCategory(id: 'comedy', name: '喜劇', englishName: 'Comedy', subcategories: [
      'comedy-interviews', 'improv', 'stand-up'
    ]),
    PodcastCategory(id: 'education', name: '教育', englishName: 'Education', subcategories: [
      'courses', 'how-to', 'language-learning', 'self-improvement'
    ]),
    PodcastCategory(id: 'fiction', name: '虛構', englishName: 'Fiction', subcategories: [
      'comedy-fiction', 'drama', 'science-fiction'
    ]),
    PodcastCategory(id: 'government', name: '政府', englishName: 'Government'),
    PodcastCategory(id: 'history', name: '歷史', englishName: 'History'),
    PodcastCategory(id: 'health-fitness', name: '健康與健身', englishName: 'Health & Fitness', subcategories: [
      'alternative-health', 'fitness', 'medicine', 'mental-health', 'nutrition', 'sexuality'
    ]),
    PodcastCategory(id: 'kids-family', name: '兒童與家庭', englishName: 'Kids & Family', subcategories: [
      'education-for-kids', 'parenting', 'pets-animals', 'stories-for-kids'
    ]),
    PodcastCategory(id: 'leisure', name: '休閒', englishName: 'Leisure', subcategories: [
      'animation-manga', 'automotive', 'aviation', 'crafts', 'games', 'hobbies', 'home-garden', 'video-games'
    ]),
    PodcastCategory(id: 'music', name: '音樂', englishName: 'Music', subcategories: [
      'music-commentary', 'music-history', 'music-interviews'
    ]),
    PodcastCategory(id: 'news', name: '新聞', englishName: 'News', subcategories: [
      'business-news', 'daily-news', 'entertainment-news', 'news-commentary', 'politics', 'sports-news', 'tech-news'
    ]),
    PodcastCategory(id: 'religion-spirituality', name: '宗教與靈性', englishName: 'Religion & Spirituality', subcategories: [
      'buddhism', 'christianity', 'hinduism', 'islam', 'judaism', 'religion', 'spirituality'
    ]),
    PodcastCategory(id: 'science', name: '科學', englishName: 'Science', subcategories: [
      'astronomy', 'chemistry', 'earth-sciences', 'life-sciences', 'mathematics', 'natural-sciences', 'nature', 'physics', 'social-sciences'
    ]),
    PodcastCategory(id: 'society-culture', name: '社會與文化', englishName: 'Society & Culture', subcategories: [
      'documentary', 'personal-journals', 'philosophy', 'places-travel', 'relationships'
    ]),
    PodcastCategory(id: 'sports', name: '運動', englishName: 'Sports', subcategories: [
      'baseball', 'basketball', 'cricket', 'fantasy-sports', 'football', 'golf', 'hockey', 'rugby', 'running', 'soccer', 'swimming', 'tennis', 'volleyball', 'wilderness', 'wrestling'
    ]),
    PodcastCategory(id: 'technology', name: '科技', englishName: 'Technology'),
    PodcastCategory(id: 'true-crime', name: '真實犯罪', englishName: 'True Crime'),
    PodcastCategory(id: 'tv-film', name: '電視與電影', englishName: 'TV & Film', subcategories: [
      'after-shows', 'film-history', 'film-interviews', 'film-reviews', 'tv-reviews'
    ]),
  ];

  /// 搜尋 Podcast 頻道
  Future<List<Podcast>> searchPodcasts(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      print('🔍 開始搜尋 podcast: $query');
      
      final searchResult = await _search.search(
        query,
        country: ps.Country.taiwan,
        limit: 50,
      );

      print('🔍 搜尋結果數量: ${searchResult.resultCount}');

      if (searchResult.resultCount > 0) {
        final podcasts = searchResult.items
            .map((item) => _searchResultToPodcast(item))
            .where((podcast) => podcast.feedUrl.isNotEmpty)
            .toList();
        
        print('🔍 有效的 podcast 數量: ${podcasts.length}');
        return podcasts;
      }
      
      print('🔍 沒有找到任何結果');
      return [];
    } catch (e) {
      print('🔥 搜尋錯誤: $e');
      throw Exception('搜尋失敗: $e');
    }
  }

  /// 按分類搜尋 Podcast
  Future<List<Podcast>> searchPodcastsByCategory(String categoryId, {int limit = 50}) async {
    try {
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => categories.first,
      );

      // 使用分類的英文名稱進行搜尋
      final searchResult = await _search.search(
        category.englishName,
        country: ps.Country.taiwan,
        limit: limit,
      );

      if (searchResult.resultCount > 0) {
        return searchResult.items
            .map((item) => _searchResultToPodcast(item))
            .toList();
      }
      
      return [];
    } catch (e) {
      throw Exception('按分類搜尋失敗: $e');
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
      print('Fetching RSS feed from: $feedUrl');
      final response = await _dio.get(feedUrl);
      print('RSS feed response status: ${response.statusCode}');
      
      if (response.data == null || response.data.toString().isEmpty) {
        throw Exception('RSS feed 為空或無效');
      }
      
      final document = XmlDocument.parse(response.data);
      final channels = document.findAllElements('channel');
      
      if (channels.isEmpty) {
        throw Exception('RSS feed 中未找到 channel 元素');
      }
      
      final channel = channels.first;
      final podcastId = _generatePodcastId(feedUrl);
      
      final episodes = <Episode>[];
      final items = channel.findAllElements('item');
      
      print('Found ${items.length} items in RSS feed');
      
      for (var i = 0; i < items.length; i++) {
        final item = items.elementAt(i);
        final episode = _parseEpisodeFromXml(item, podcastId, i + 1);
        if (episode != null) {
          episodes.add(episode);
        }
      }
      
      print('Successfully parsed ${episodes.length} episodes');
      return episodes;
    } catch (e) {
      print('Error fetching/parsing RSS feed: $e');
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
      description: item.collectionName ?? item.trackName ?? '',
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
      final title = item.findElements('title').firstOrNull?.innerText?.trim() ?? '未知標題';
      
      // 嘗試不同的描述字段
      String description = '';
      if (item.findElements('description').isNotEmpty) {
        description = item.findElements('description').first.innerText.trim();
      } else if (item.findElements('itunes:summary').isNotEmpty) {
        description = item.findElements('itunes:summary').first.innerText.trim();
      }
      
      // 查找音訊 URL - 更靈活的查找方式
      String audioUrl = '';
      final enclosures = item.findElements('enclosure');
      for (final enclosure in enclosures) {
        final url = enclosure.getAttribute('url');
        final type = enclosure.getAttribute('type');
        if (url != null && url.isNotEmpty) {
          // 優先選擇音訊類型的 enclosure
          if (type != null && type.startsWith('audio/')) {
            audioUrl = url;
            break;
          } else if (audioUrl.isEmpty) {
            audioUrl = url;
          }
        }
      }
      
      // 如果沒有找到 enclosure，跳過這個集數
      if (audioUrl.isEmpty) {
        print('Warning: No audio URL found for episode: $title');
        return null;
      }
      
      // 解析發布日期 - 使用更寬鬆的日期解析
      DateTime publishDate = DateTime.now();
      final pubDateText = item.findElements('pubDate').firstOrNull?.innerText?.trim() ?? '';
      if (pubDateText.isNotEmpty) {
        try {
          // 嘗試 RFC 2822 格式解析
          publishDate = DateTime.parse(pubDateText);
        } catch (e) {
          // 如果解析失敗，嘗試其他常見格式
          try {
            // 移除時區信息再嘗試解析
            final cleanDate = pubDateText.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
            publishDate = DateTime.parse(cleanDate);
          } catch (e2) {
            print('Warning: Cannot parse date: $pubDateText for episode: $title');
            // 使用當前時間作為後備
          }
        }
      }
      
      // 解析持續時間 - 更靈活的解析
      Duration duration = Duration.zero;
      final durationText = item.findElements('itunes:duration').firstOrNull?.innerText?.trim() ?? '';
      if (durationText.isNotEmpty) {
        duration = _parseDuration(durationText);
      }
      
      // 獲取圖片 URL - 嘗試多個來源
      String imageUrl = '';
      final imageElement = item.findElements('itunes:image').firstOrNull;
      if (imageElement != null) {
        imageUrl = imageElement.getAttribute('href') ?? '';
      }
      
      // 獲取 GUID
      final guid = item.findElements('guid').firstOrNull?.innerText?.trim() ?? 
                   '${podcastId}_$episodeNumber';
      
      print('Parsed episode: $title (audioUrl: ${audioUrl.isNotEmpty ? 'found' : 'missing'})');
      
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
      print('Error parsing episode: $e');
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