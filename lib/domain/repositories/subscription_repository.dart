import '../entities/podcast.dart';

abstract class SubscriptionRepository {
  // ... existing code ...

  /// 獲取所有訂閱的分類
  Future<List<String>> getSubscriptionCategories();

  /// 獲取指定分類的訂閱播客
  Future<List<dynamic>> getSubscriptionsByCategory(String category);

  /// 更新播客的分類
  Future<void> updatePodcastCategories(String podcastId, List<String> categories);

  Future<bool> getAutoUpdateEnabled();
  Future<void> setAutoUpdate(bool enabled);
  Future<List<Podcast>> getSubscribedPodcasts();
} 