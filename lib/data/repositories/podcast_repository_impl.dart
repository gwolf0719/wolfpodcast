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
      return await localDataSource.getPopularPodcastsFromCache();
    }
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