import '../entities/podcast.dart';

abstract class SubscriptionRepository {
  /// 初始化 repository
  Future<void> initialize();

  /// 訂閱 Podcast
  Future<void> subscribePodcast(Podcast podcast);

  /// 取消訂閱 Podcast
  Future<void> unsubscribePodcast(String podcastId);

  /// 檢查是否已訂閱
  Future<bool> isSubscribed(String podcastId);

  /// 獲取所有訂閱的 Podcast
  Future<List<Podcast>> getSubscribedPodcasts();

  /// 獲取所有訂閱的分類
  Future<List<String>> getSubscriptionCategories();

  /// 獲取指定分類的訂閱播客
  Future<List<dynamic>> getSubscriptionsByCategory(String category);

  /// 更新播客的分類
  Future<void> updatePodcastCategories(String podcastId, List<String> categories);

  /// 獲取自動更新設定
  Future<bool> getAutoUpdateEnabled();
  
  /// 設定自動更新
  Future<void> setAutoUpdate(bool enabled);
} 