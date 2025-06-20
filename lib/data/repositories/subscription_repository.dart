import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/podcast.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_storage.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/podcast_model.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final HiveStorage _storage;

  SubscriptionRepositoryImpl({required HiveStorage storage}) : _storage = storage;

  @override
  Future<List<String>> getSubscriptionCategories() async {
    return await _storage.getSubscriptionCategories();
  }

  @override
  Future<List<Podcast>> getSubscriptionsByCategory(String category) async {
    final podcastModels = await _storage.getSubscriptionsByCategory(category);
    return podcastModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> updatePodcastCategories(String podcastId, List<String> categories) async {
    final podcast = await _storage.getPodcast(podcastId);
    if (podcast != null) {
      final updatedPodcast = PodcastModel(
        id: podcast.id,
        title: podcast.title,
        description: podcast.description,
        imageUrl: podcast.imageUrl,
        feedUrl: podcast.feedUrl,
        author: podcast.author,
        category: podcast.category,
        language: podcast.language,
        isSubscribed: podcast.isSubscribed,
        createdAt: podcast.createdAt,
        lastUpdate: podcast.lastUpdate,
        episodeCount: podcast.episodeCount,
        categories: categories,
      );
      await _storage.updatePodcast(updatedPodcast);
    }
  }

  static SubscriptionRepository? _instance;
  static SubscriptionRepository get instance {
    _instance ??= SubscriptionRepositoryImpl(storage: HiveStorage());
    return _instance!;
  }

  late Box<Map> _subscriptionsBox;
  bool _isInitialized = false;

  // 初始化 Hive Box
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 註冊 Adapter（如果需要）
      if (!Hive.isAdapterRegistered(0)) {
        // 這裡可以註冊自定義的 TypeAdapter
      }
      
      _subscriptionsBox = await Hive.openBox<Map>('subscriptions');
      _isInitialized = true;
    } catch (e) {
      throw Exception('初始化訂閱資料庫失敗: $e');
    }
  }

  // 訂閱 Podcast
  Future<void> subscribePodcast(Podcast podcast) async {
    await _ensureInitialized();
    
    final podcastData = {
      'id': podcast.id,
      'title': podcast.title,
      'description': podcast.description,
      'imageUrl': podcast.imageUrl,
      'feedUrl': podcast.feedUrl,
      'author': podcast.author,
      'category': podcast.category,
      'language': podcast.language,
      'lastUpdate': podcast.lastUpdate.millisecondsSinceEpoch,
      'episodeCount': podcast.episodeCount,
      'categories': podcast.categories,
      'subscribedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _subscriptionsBox.put(podcast.id, podcastData);
  }

  // 取消訂閱 Podcast
  Future<void> unsubscribePodcast(String podcastId) async {
    await _ensureInitialized();
    await _subscriptionsBox.delete(podcastId);
  }

  // 檢查是否已訂閱
  Future<bool> isSubscribed(String podcastId) async {
    await _ensureInitialized();
    return _subscriptionsBox.containsKey(podcastId);
  }

  // 獲取所有訂閱的 Podcast
  Future<List<Podcast>> getSubscribedPodcasts() async {
    await _ensureInitialized();
    
    final List<Podcast> podcasts = [];
    
    for (final key in _subscriptionsBox.keys) {
      final data = _subscriptionsBox.get(key);
      if (data != null) {
        try {
          final podcast = _mapToPodcast(data);
          podcasts.add(podcast);
        } catch (e) {
          // 忽略無效的資料
          continue;
        }
      }
    }
    
    // 按訂閱時間排序（最新的在前）
    podcasts.sort((a, b) {
      final aTime = _subscriptionsBox.get(a.id)?['subscribedAt'] ?? 0;
      final bTime = _subscriptionsBox.get(b.id)?['subscribedAt'] ?? 0;
      return bTime.compareTo(aTime);
    });
    
    return podcasts;
  }

  // 獲取訂閱數量
  Future<int> getSubscriptionCount() async {
    await _ensureInitialized();
    return _subscriptionsBox.length;
  }

  // 切換訂閱狀態
  Future<bool> toggleSubscription(Podcast podcast) async {
    await _ensureInitialized();
    
    if (await isSubscribed(podcast.id)) {
      await unsubscribePodcast(podcast.id);
      return false; // 已取消訂閱
    } else {
      await subscribePodcast(podcast);
      return true; // 已訂閱
    }
  }

  // 清除所有訂閱
  Future<void> clearAllSubscriptions() async {
    await _ensureInitialized();
    await _subscriptionsBox.clear();
  }

  // 更新 Podcast 資訊
  Future<void> updatePodcast(Podcast podcast) async {
    await _ensureInitialized();
    
    if (await isSubscribed(podcast.id)) {
      final existingData = _subscriptionsBox.get(podcast.id);
      final subscribedAt = existingData?['subscribedAt'] ?? DateTime.now().millisecondsSinceEpoch;
      
      final updatedData = {
        'id': podcast.id,
        'title': podcast.title,
        'description': podcast.description,
        'imageUrl': podcast.imageUrl,
        'feedUrl': podcast.feedUrl,
        'author': podcast.author,
        'category': podcast.category,
        'language': podcast.language,
        'lastUpdate': podcast.lastUpdate.millisecondsSinceEpoch,
        'episodeCount': podcast.episodeCount,
        'categories': podcast.categories,
        'subscribedAt': subscribedAt,
      };
      
      await _subscriptionsBox.put(podcast.id, updatedData);
    }
  }

  // 根據分類篩選訂閱
  Future<List<Podcast>> getSubscribedPodcastsByCategory(String category) async {
    await _ensureInitialized();
    
    final allSubscribed = await getSubscribedPodcasts();
    return allSubscribed.where((podcast) => 
        podcast.category.toLowerCase() == category.toLowerCase() ||
        podcast.categories.any((cat) => cat.toLowerCase() == category.toLowerCase())
    ).toList();
  }

  // 搜尋訂閱的 Podcast
  Future<List<Podcast>> searchSubscribedPodcasts(String query) async {
    await _ensureInitialized();
    
    if (query.trim().isEmpty) {
      return await getSubscribedPodcasts();
    }
    
    final allSubscribed = await getSubscribedPodcasts();
    final lowerQuery = query.toLowerCase();
    
    return allSubscribed.where((podcast) =>
        podcast.title.toLowerCase().contains(lowerQuery) ||
        podcast.author.toLowerCase().contains(lowerQuery) ||
        podcast.description.toLowerCase().contains(lowerQuery) ||
        podcast.category.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // 私有方法
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Podcast _mapToPodcast(Map data) {
    return Podcast(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '未知標題',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
      feedUrl: data['feedUrl']?.toString() ?? '',
      author: data['author']?.toString() ?? '未知作者',
      category: data['category']?.toString() ?? '未知分類',
      language: data['language']?.toString() ?? 'zh-TW',
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdate']?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      ),
      episodeCount: data['episodeCount']?.toInt() ?? 0,
      categories: List<String>.from(data['categories'] ?? []),
      isSubscribed: true, // 從訂閱資料庫來的都是已訂閱的
    );
  }

  // 關閉資源
  Future<void> dispose() async {
    if (_isInitialized) {
      await _subscriptionsBox.close();
      _isInitialized = false;
    }
  }
} 