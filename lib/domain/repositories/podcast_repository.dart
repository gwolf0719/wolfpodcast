import '../entities/podcast.dart';
import '../entities/episode.dart';

abstract class PodcastRepository {
  Future<List<Podcast>> searchPodcasts(String query);
  Future<List<Podcast>> getTopPodcasts();
  Future<List<Podcast>> getSubscribedPodcasts();
  Future<List<Episode>> getPodcastEpisodes(String feedUrl);
  Future<void> subscribeToPodcast(Podcast podcast);
  Future<void> unsubscribeFromPodcast(String podcastId);
  Future<Podcast?> getPodcastById(String id);

  /// 獲取熱門播客
  /// [limit] 限制返回的播客數量
  /// [category] 可選的分類過濾
  Future<List<Podcast>> getPopularPodcasts({
    int limit = 20,
    String? category,
  });

  /// 刷新播客資訊
  /// [podcastId] 播客ID
  /// 返回更新後的播客資訊，如果沒有更新則返回null
  Future<Podcast?> refreshPodcast(String podcastId);

  /// 獲取播客的最後更新時間
  Future<DateTime> getLastUpdateTime(String podcastId);

  /// 設置自動更新
  Future<void> setAutoUpdate(bool enabled);

  /// 獲取自動更新狀態
  Future<bool> getAutoUpdateEnabled();
} 