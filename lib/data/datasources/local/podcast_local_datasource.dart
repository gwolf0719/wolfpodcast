import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/podcast.dart';
import '../../../core/storage/hive_storage.dart';

abstract class PodcastLocalDataSource {
  Future<List<Podcast>> getAllPodcasts();
  Future<List<Podcast>> getSubscribedPodcasts();
  Future<Podcast?> getPodcastById(String id);
  Future<Podcast?> getPodcastByFeedUrl(String feedUrl);
  Future<void> insertPodcast(Podcast podcast);
  Future<void> updatePodcast(Podcast podcast);
  Future<void> deletePodcast(String id);
  Future<void> subscribeToPodcast(String id);
  Future<void> unsubscribeFromPodcast(String id);
  Future<List<Podcast>> searchLocalPodcasts(String query);
  Future<void> clearCache();
  Future<void> cachePopularPodcasts(List<Podcast> podcasts);
  Future<List<Podcast>> getPopularPodcastsFromCache();
}

class PodcastLocalDataSourceImpl implements PodcastLocalDataSource {
  final Database database;
  final HiveStorage _storage;

  PodcastLocalDataSourceImpl(this.database, this._storage);

  @override
  Future<List<Podcast>> getAllPodcasts() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'podcasts',
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToPodcast(map)).toList();
  }

  @override
  Future<List<Podcast>> getSubscribedPodcasts() async {
    final List<Map<String, dynamic>> maps = await database.query(
      'podcasts',
      where: 'is_subscribed = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToPodcast(map)).toList();
  }

  @override
  Future<Podcast?> getPodcastById(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _mapToPodcast(maps.first);
    }
    return null;
  }

  @override
  Future<Podcast?> getPodcastByFeedUrl(String feedUrl) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'podcasts',
      where: 'rss_url = ?',
      whereArgs: [feedUrl],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return _mapToPodcast(maps.first);
    }
    return null;
  }

  @override
  Future<void> insertPodcast(Podcast podcast) async {
    await database.insert(
      'podcasts',
      _podcastToMap(podcast),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updatePodcast(Podcast podcast) async {
    await database.update(
      'podcasts',
      _podcastToMap(podcast),
      where: 'id = ?',
      whereArgs: [podcast.id],
    );
  }

  @override
  Future<void> deletePodcast(String id) async {
    await database.delete(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> subscribeToPodcast(String id) async {
    await database.update(
      'podcasts',
      {
        'is_subscribed': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> unsubscribeFromPodcast(String id) async {
    await database.update(
      'podcasts',
      {
        'is_subscribed': 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Podcast>> searchLocalPodcasts(String query) async {
    final List<Map<String, dynamic>> maps = await database.query(
      'podcasts',
      where: 'title LIKE ? OR description LIKE ? OR author LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );

    return maps.map((map) => _mapToPodcast(map)).toList();
  }

  @override
  Future<void> clearCache() async {
    await database.delete('podcasts');
  }

  @override
  Future<void> cachePopularPodcasts(List<Podcast> podcasts) async {
    for (final podcast in podcasts) {
      // Convert podcast to map format for storage
    final podcastMap = {
      'id': podcast.id,
      'title': podcast.title,
      'description': podcast.description,
      'imageUrl': podcast.imageUrl,
      'author': podcast.author,
      'feedUrl': podcast.feedUrl,
    };
    await _storage.setSetting('podcast_${podcast.id}', podcastMap);
    }
  }

  @override
  Future<List<Podcast>> getPopularPodcastsFromCache() async {
    final popularPodcasts = await _storage.getPopularPodcasts();
    return popularPodcasts.map((model) => model.toEntity()).toList();
  }

  // 私有輔助方法
  Map<String, dynamic> _podcastToMap(Podcast podcast) {
    return {
      'id': podcast.id,
      'title': podcast.title,
      'description': podcast.description,
      'image_url': podcast.imageUrl,
      'rss_url': podcast.feedUrl,
      'author': podcast.author,
      'category': podcast.category,
      'language': podcast.language,
      'is_subscribed': podcast.isSubscribed ? 1 : 0,
      'created_at': podcast.createdAt?.toIso8601String(),
      'updated_at': podcast.lastUpdate.toIso8601String(),
    };
  }

  Podcast _mapToPodcast(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      feedUrl: map['rss_url'] as String,
      author: map['author'] as String? ?? '',
      category: map['category'] as String? ?? '',
      language: map['language'] as String? ?? 'zh-TW',
      isSubscribed: (map['is_subscribed'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      lastUpdate: DateTime.parse(map['updated_at'] as String),
      episodeCount: 0, // 需要另外查詢
      categories: [
        if (map['category'] != null && (map['category'] as String).isNotEmpty)
          map['category'] as String,
      ],
    );
  }
} 