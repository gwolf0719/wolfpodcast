import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/episode.dart';

class DownloadProgress {
  final String episodeId;
  final double progress;
  final bool isCompleted;
  final String? error;

  DownloadProgress({
    required this.episodeId,
    required this.progress,
    this.isCompleted = false,
    this.error,
  });
}

class DownloadManager {
  final Dio _dio;
  final Map<String, BehaviorSubject<double>> _progressControllers = {};
  final Map<String, CancelToken> _cancelTokens = {};
  final _downloadQueue = <String>[];
  final _maxConcurrentDownloads = 3;
  int _activeDownloads = 0;

  final _downloadController = BehaviorSubject<DownloadProgress>();
  Stream<DownloadProgress> get downloadProgress => _downloadController.stream;

  DownloadManager({Dio? dio}) : _dio = dio ?? Dio();

  void addToQueue(String episodeId, String url, String filename) {
    if (!_downloadQueue.contains(episodeId)) {
      _downloadQueue.add(episodeId);
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_activeDownloads >= _maxConcurrentDownloads || _downloadQueue.isEmpty) {
      return;
    }

    final episodeId = _downloadQueue.first;
    _downloadQueue.removeAt(0);
    _activeDownloads++;

    try {
      final cancelToken = CancelToken();
      _cancelTokens[episodeId] = cancelToken;

      final progress = BehaviorSubject<double>();
      _progressControllers[episodeId] = progress;

      progress.listen((value) {
        _downloadController.add(DownloadProgress(
          episodeId: episodeId,
          progress: value,
          isCompleted: value >= 1.0,
        ));
      });

      await downloadFile(
        url: url,
        filename: filename,
        onProgress: (progress) {
          _progressControllers[episodeId]?.add(progress);
        },
        cancelToken: cancelToken,
      );

      _downloadController.add(DownloadProgress(
        episodeId: episodeId,
        progress: 1.0,
        isCompleted: true,
      ));
    } catch (e) {
      _downloadController.add(DownloadProgress(
        episodeId: episodeId,
        progress: 0.0,
        error: e.toString(),
      ));
    } finally {
      _activeDownloads--;
      _progressControllers[episodeId]?.close();
      _progressControllers.remove(episodeId);
      _processQueue();
    }
  }

  Future<void> downloadEpisode(Episode episode) async {
    if (_progressControllers.containsKey(episode.id)) {
      return;
    }

    final progressController = BehaviorSubject<double>();
    _progressControllers[episode.id] = progressController;

    final cancelToken = CancelToken();
    _cancelTokens[episode.id] = cancelToken;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${episode.id}.mp3';
      final savePath = '${appDir.path}/episodes/$fileName';

      await _dio.download(
        episode.audioUrl,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            progressController.add(progress);
          }
        },
      );

      progressController.add(1.0);
    } catch (e) {
      progressController.addError(e);
      rethrow;
    } finally {
      await progressController.close();
      _progressControllers.remove(episode.id);
      _cancelTokens.remove(episode.id);
    }
  }

  void cancelDownload(String id) {
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('使用者取消下載');
      _cancelTokens.remove(id);
      _downloadQueue.remove(id);
      _progressControllers[id]?.close();
      _progressControllers.remove(id);
      _activeDownloads = _activeDownloads > 0 ? _activeDownloads - 1 : 0;
      _processQueue();
    }
  }

  Future<void> deleteDownloadedEpisode(String episodeId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/episodes/$episodeId.mp3';
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> isEpisodeDownloaded(String episodeId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/episodes/$episodeId.mp3';
    final file = File(filePath);
    return await file.exists();
  }

  Stream<double> getDownloadProgress(String episodeId) {
    return _progressControllers[episodeId]?.stream ?? Stream.value(0.0);
  }

  void dispose() {
    for (var token in _cancelTokens.values) {
      if (!token.isCancelled) {
        token.cancel('Manager disposed');
      }
    }
    _cancelTokens.clear();
    for (var controller in _progressControllers.values) {
      controller.close();
    }
    _progressControllers.clear();
    _downloadController.close();
  }
} 