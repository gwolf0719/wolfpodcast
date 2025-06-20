import 'dart:async';
import '../../core/storage/hive_storage.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/episode_repository.dart';
import '../datasources/local/episode_local_datasource.dart';
import '../datasources/remote/episode_remote_datasource.dart';
import '../datasources/download_manager.dart';


class EpisodeRepositoryImpl implements EpisodeRepository {
  final EpisodeLocalDataSource _localDataSource;
  final EpisodeRemoteDataSource _remoteDataSource;
  final DownloadManager _downloadManager;
  // ignore: unused_field
  final HiveStorage _hiveStorage;
  final Map<String, StreamController<double>> _progressControllers = {};

  EpisodeRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._downloadManager,
    this._hiveStorage,
  );

  @override
  Stream<DownloadProgress> get downloadProgress => _downloadManager.downloadProgress;

  @override
  Future<List<Episode>> getEpisodes(String podcastId) async {
    try {
      final localEpisodes = await _localDataSource.getDownloadedEpisodes();
      final filteredLocal = localEpisodes.where((e) => e.podcastId == podcastId).toList();
      if (filteredLocal.isNotEmpty) {
        return filteredLocal;
      }

      final remoteEpisodes = await _remoteDataSource.getEpisodesByPodcastId(podcastId);
      for (var episode in remoteEpisodes) {
        await _localDataSource.saveEpisode(episode);
      }
      return remoteEpisodes;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Episode?> getEpisode(String episodeId) async {
    try {
      return await _localDataSource.getEpisode(episodeId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePlaybackPosition(String episodeId, Duration position) async {
    try {
      final episode = await _localDataSource.getEpisode(episodeId);
      if (episode != null) {
        final updatedEpisode = episode.copyWith(position: position);
        await _localDataSource.saveEpisode(updatedEpisode);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsPlayed(String episodeId) async {
    try {
      final episode = await _localDataSource.getEpisode(episodeId);
      if (episode != null) {
        final updatedEpisode = episode.copyWith(isPlayed: true);
        await _localDataSource.saveEpisode(updatedEpisode);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> downloadEpisode(Episode episode) async {
    try {
      // Create progress controller
      final progressController = StreamController<double>.broadcast();
      _progressControllers[episode.id] = progressController;

      // Update episode status to downloading
      final updatedEpisode = episode.copyWith(
        downloadProgress: 0.0,
        isDownloading: true,
      );
      await _localDataSource.saveEpisode(updatedEpisode);

      // Start download using DownloadManager
      await _downloadManager.downloadEpisode(episode);

      // Listen to download progress
      _downloadManager.getDownloadProgress(episode.id).listen(
        (progress) async {
          progressController.add(progress);

          // Update episode download status
          final currentEpisode = await _localDataSource.getEpisode(episode.id);
          if (currentEpisode != null) {
            final updatedEpisode = currentEpisode.copyWith(
              downloadProgress: progress,
              isDownloaded: progress >= 1.0,
              isDownloading: progress < 1.0,
              downloadPath: progress >= 1.0 ? '${episode.id}.mp3' : null,
            );
            await _localDataSource.saveEpisode(updatedEpisode);
          }

          // Handle download completion
          if (progress >= 1.0) {
            await progressController.close();
            _progressControllers.remove(episode.id);
          }
        },
        onError: (error) async {
          await _localDataSource.saveEpisode(
            episode.copyWith(
              downloadProgress: 0.0,
              isDownloading: false,
              isDownloaded: false,
              downloadPath: null,
            ),
          );
          await progressController.close();
          _progressControllers.remove(episode.id);
        },
      );
    } catch (e) {
      // Clean up on error
      final progressController = _progressControllers[episode.id];
      if (progressController != null) {
        await progressController.close();
        _progressControllers.remove(episode.id);
      }
      await _localDataSource.saveEpisode(
        episode.copyWith(
          downloadProgress: 0.0,
          isDownloading: false,
          isDownloaded: false,
          downloadPath: null,
        ),
      );
      rethrow;
    }
  }

  @override
  void cancelDownload(String episodeId) {
    _downloadManager.cancelDownload(episodeId);

    // Close progress controller
    final progressController = _progressControllers[episodeId];
    if (progressController != null) {
      progressController.close();
      _progressControllers.remove(episodeId);
    }
  }

  @override
  Future<void> deleteDownloadedEpisode(String episodeId) async {
    try {
      final episode = await _localDataSource.getEpisode(episodeId);
      if (episode != null && episode.downloadPath != null) {
        // Delete file
        await _downloadManager.deleteDownloadedEpisode(episodeId);
        
        // Update episode status
        final updatedEpisode = episode.copyWith(
          downloadPath: null,
          isDownloaded: false,
          downloadProgress: 0.0,
        );
        await _localDataSource.saveEpisode(updatedEpisode);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Episode>> getEpisodesByPodcastId(String podcastId) async {
    try {
      final episodes = await _localDataSource.getDownloadedEpisodes();
      final filteredEpisodes = episodes.where((e) => e.podcastId == podcastId).toList();
      if (filteredEpisodes.isEmpty) {
        final remoteEpisodes = await _remoteDataSource.getEpisodesByPodcastId(podcastId);
        for (var episode in remoteEpisodes) {
          await _localDataSource.saveEpisode(episode);
        }
        return remoteEpisodes;
      }
      return filteredEpisodes;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Episode?> getEpisodeById(String id) async {
    try {
      final episode = await _localDataSource.getEpisode(id);
      if (episode == null) {
        final remoteEpisode = await _remoteDataSource.getEpisodeById(id);
        if (remoteEpisode != null) {
          await _localDataSource.saveEpisode(remoteEpisode);
        }
        return remoteEpisode;
      }
      return episode;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isEpisodeDownloaded(String episodeId) async {
    return await _downloadManager.isEpisodeDownloaded(episodeId);
  }

  @override
  Stream<double> getDownloadProgress(String episodeId) {
    return _downloadManager.getDownloadProgress(episodeId);
  }

  @override
  Future<List<Episode>> getDownloadedEpisodes() async {
    return await _localDataSource.getDownloadedEpisodes();
  }

  @override
  Future<void> updateEpisode(Episode episode) async {
    try {
      await _localDataSource.saveEpisode(episode);
    } catch (e) {
      throw Exception('Failed to update episode: $e');
    }
  }

  void dispose() {
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
  }
} 