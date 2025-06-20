import '../../domain/entities/podcast.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/podcast_repository.dart';
import '../datasources/local/podcast_local_datasource.dart';
import '../datasources/remote/podcast_remote_datasource.dart';
import '../../core/storage/hive_storage.dart';

class PodcastRepositoryImpl implements PodcastRepository {
  final PodcastLocalDataSource localDataSource;
  final PodcastRemoteDataSource remoteDataSource;
  final HiveStorage storage;

  PodcastRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  Future<List<Podcast>> searchPodcasts(String query) async {
    try {
      final podcasts = await remoteDataSource.searchPodcasts(query);
      // 快取搜尋結果
      for (final podcast in podcasts) {
        await localDataSource.insertPodcast(podcast);
      }
      return podcasts;
    } catch (e) {
      // 如果網路失敗，回退到本地搜尋
      return await localDataSource.searchLocalPodcasts(query);
    }
  }

  @override
  Future<List<Podcast>> getTopPodcasts() async {
    return await remoteDataSource.getTopPodcasts();
  }

  @override
  Future<List<Podcast>> getSubscribedPodcasts() async {
    return await localDataSource.getSubscribedPodcasts();
  }

  @override
  Future<List<Episode>> getPodcastEpisodes(String feedUrl) async {
    return await remoteDataSource.getPodcastEpisodes(feedUrl);
  }

  @override
  Future<void> subscribeToPodcast(Podcast podcast) async {
    final existingPodcast = await localDataSource.getPodcastByFeedUrl(podcast.feedUrl);
    if (existingPodcast == null) {
      final subscribedPodcast = podcast.copyWith(isSubscribed: true);
      await localDataSource.insertPodcast(subscribedPodcast);
    } else {
      await localDataSource.subscribeToPodcast(existingPodcast.id);
    }
  }

  @override
  Future<void> unsubscribeFromPodcast(String podcastId) async {
    await localDataSource.unsubscribeFromPodcast(podcastId);
  }

  @override
  Future<Podcast?> getPodcastById(String id) async {
    return await localDataSource.getPodcastById(id);
  }

  @override
  Future<List<Podcast>> getPopularPodcasts({
    int limit = 20,
    String? category,
  }) async {
    try {
      final popularPodcasts = await remoteDataSource.getPopularPodcasts(category ?? 'all');
      
      // 將熱門播客保存到本地緩存
      await localDataSource.cachePopularPodcasts(popularPodcasts);
      
      return popularPodcasts;
    } catch (e) {
      // 如果網絡請求失敗，嘗試從本地緩存獲取
      final cachedPodcasts = await localDataSource.getPopularPodcastsFromCache();
      
      // 如果快取也是空的，返回示例資料
      if (cachedPodcasts.isEmpty) {
        return _getSamplePopularPodcasts();
      }
      
      return cachedPodcasts;
    }
  }

  List<Podcast> _getSamplePopularPodcasts() {
    return [
      Podcast(
        id: 'sample_1',
        title: '科技聊天室',
        description: '探討最新科技趨勢和創新，每週為您帶來科技界的精彩內容。',
        imageUrl: 'https://picsum.photos/300/300?random=1',
        feedUrl: 'https://example.com/tech-podcast.xml',
        author: '科技小編',
        category: '科技',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 1)),
        episodeCount: 85,
        categories: ['科技', '創新', '趨勢'],
      ),
      Podcast(
        id: 'sample_2',
        title: '商業洞察',
        description: '深度分析商業案例，分享創業經驗和商業智慧。',
        imageUrl: 'https://picsum.photos/300/300?random=2',
        feedUrl: 'https://example.com/business-podcast.xml',
        author: '商業專家',
        category: '商業',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 2)),
        episodeCount: 120,
        categories: ['商業', '創業', '投資'],
      ),
      Podcast(
        id: 'sample_3',
        title: '健康生活誌',
        description: '分享健康生活的小秘訣，包括運動、飲食和心理健康。',
        imageUrl: 'https://picsum.photos/300/300?random=3',
        feedUrl: 'https://example.com/health-podcast.xml',
        author: '健康達人',
        category: '健康',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 3)),
        episodeCount: 95,
        categories: ['健康', '運動', '生活'],
      ),
      Podcast(
        id: 'sample_4',
        title: '文化漫談',
        description: '深入探索各地文化，分享旅行見聞和文化體驗。',
        imageUrl: 'https://picsum.photos/300/300?random=4',
        feedUrl: 'https://example.com/culture-podcast.xml',
        author: '文化探索者',
        category: '文化',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 4)),
        episodeCount: 67,
        categories: ['文化', '旅行', '歷史'],
      ),
      Podcast(
        id: 'sample_5',
        title: '音樂時光',
        description: '介紹各種音樂風格，分享音樂家的故事和音樂創作過程。',
        imageUrl: 'https://picsum.photos/300/300?random=5',
        feedUrl: 'https://example.com/music-podcast.xml',
        author: '音樂愛好者',
        category: '音樂',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 5)),
        episodeCount: 78,
        categories: ['音樂', '藝術', '創作'],
      ),
      Podcast(
        id: 'sample_6',
        title: '教育新視界',
        description: '探討現代教育理念，分享學習方法和教育資源。',
        imageUrl: 'https://picsum.photos/300/300?random=6',
        feedUrl: 'https://example.com/education-podcast.xml',
        author: '教育工作者',
        category: '教育',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 6)),
        episodeCount: 102,
        categories: ['教育', '學習', '成長'],
      ),
      Podcast(
        id: 'sample_7',
        title: '新聞焦點',
        description: '每日為您整理重要新聞，深度分析時事話題。',
        imageUrl: 'https://picsum.photos/300/300?random=7',
        feedUrl: 'https://example.com/news-podcast.xml',
        author: '新聞主播',
        category: '新聞',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(hours: 6)),
        episodeCount: 365,
        categories: ['新聞', '時事', '政治'],
      ),
      Podcast(
        id: 'sample_8',
        title: '歷史探秘',
        description: '帶您探索歷史的奧秘，重現古代文明的輝煌。',
        imageUrl: 'https://picsum.photos/300/300?random=8',
        feedUrl: 'https://example.com/history-podcast.xml',
        author: '歷史學者',
        category: '歷史',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 7)),
        episodeCount: 156,
        categories: ['歷史', '文化', '考古'],
      ),
      Podcast(
        id: 'sample_9',
        title: '心理健康小站',
        description: '關注心理健康，分享情緒管理和心理調適的方法。',
        imageUrl: 'https://picsum.photos/300/300?random=9',
        feedUrl: 'https://example.com/psychology-podcast.xml',
        author: '心理諮商師',
        category: '心理',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 8)),
        episodeCount: 89,
        categories: ['心理', '健康', '成長'],
      ),
      Podcast(
        id: 'sample_10',
        title: '科學探索',
        description: '探索科學的奧妙，從宇宙奧秘到微觀世界。',
        imageUrl: 'https://picsum.photos/300/300?random=10',
        feedUrl: 'https://example.com/science-podcast.xml',
        author: '科學家',
        category: '科學',
        language: 'zh-TW',
        isSubscribed: false,
        lastUpdate: DateTime.now().subtract(const Duration(days: 9)),
        episodeCount: 134,
        categories: ['科學', '研究', '發現'],
      ),
    ];
  }

  /// 根據分類獲取示例播客
  List<Podcast> getPodcastsByCategory(String category) {
    final allPodcasts = _getSamplePopularPodcasts();
    if (category == '全部' || category.isEmpty) {
      return allPodcasts;
    }
    return allPodcasts.where((podcast) => 
      podcast.category == category || podcast.categories.contains(category)
    ).toList();
  }

  /// 獲取所有可用分類
  List<String> getAvailableCategories() {
    return [
      '全部',
      '科技',
      '商業',
      '健康',
      '文化',
      '音樂',
      '教育',
      '新聞',
      '歷史',
      '心理',
      '科學',
    ];
  }

  @override
  Future<Podcast?> refreshPodcast(String podcastId) async {
    try {
      final currentPodcast = await localDataSource.getPodcastById(podcastId);
      if (currentPodcast == null) return null;

      final remotePodcast = await remoteDataSource.getPodcastById(podcastId);
      if (remotePodcast == null) return null;

      if (remotePodcast.lastUpdate.isAfter(currentPodcast.lastUpdate)) {
        await localDataSource.updatePodcast(remotePodcast);
        return remotePodcast;
      }
      return null;
    } catch (e) {
      print('刷新播客失敗：$e');
      return null;
    }
  }

  @override
  Future<DateTime> getLastUpdateTime(String podcastId) async {
    final podcast = await localDataSource.getPodcastById(podcastId);
    return podcast?.lastUpdate ?? DateTime.now();
  }

  @override
  Future<void> setAutoUpdate(bool enabled) async {
    await storage.setAutoUpdateEnabled(enabled);
  }

  @override
  Future<bool> getAutoUpdateEnabled() async {
    return await storage.getAutoUpdateEnabled();
  }
} 