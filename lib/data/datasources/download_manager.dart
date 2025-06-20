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

  void _processQueue() {
    while (_activeDownloads < _maxConcurrentDownloads && _downloadQueue.isNotEmpty) {
      _downloadQueue.removeAt(0);
      _activeDownloads++;
      // Process download for episodeId
    }
  }

  Future<String> downloadEpisode(Episode episode) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final filename = '${episode.id}.mp3';
      final filePath = '${downloadDir.path}/$filename';
      
      final cancelToken = CancelToken();
      _cancelTokens[episode.id] = cancelToken;

      // 創建進度控制器
      final progressController = BehaviorSubject<double>();
      _progressControllers[episode.id] = progressController;

      await downloadFile(
        episode.audioUrl,
        filePath,
        onProgress: (progress) {
          progressController.add(progress);
          _downloadController.add(DownloadProgress(
            episodeId: episode.id,
            progress: progress,
          ));
        },
        cancelToken: cancelToken,
      );

      // 下載完成
      progressController.add(1.0);
      _downloadController.add(DownloadProgress(
        episodeId: episode.id,
        progress: 1.0,
        isCompleted: true,
      ));

      // 清理
      _cancelTokens.remove(episode.id);
      _progressControllers.remove(episode.id);

      return filePath;
    } catch (e) {
      _downloadController.add(DownloadProgress(
        episodeId: episode.id,
        progress: 0.0,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<void> downloadFile(
    String url,
    String filePath, {
    required Function(double) onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
          }
        },
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw Exception('下載失敗: $e');
    }
  }

  void cancelDownload(String episodeId) {
    final cancelToken = _cancelTokens[episodeId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('用戶取消下載');
    }
    
    // 清理控制器
    final progressController = _progressControllers[episodeId];
    if (progressController != null) {
      progressController.close();
      _progressControllers.remove(episodeId);
    }
    
    _cancelTokens.remove(episodeId);
  }

  Future<void> deleteDownloadedEpisode(String episodeId) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final filename = '$episodeId.mp3';
      final file = File('${downloadDir.path}/$filename');
      
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('刪除下載文件失敗: $e');
    }
  }

  Future<bool> isEpisodeDownloaded(String episodeId) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final filename = '$episodeId.mp3';
      final file = File('${downloadDir.path}/$filename');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Stream<double> getDownloadProgress(String episodeId) {
    final controller = _progressControllers[episodeId];
    if (controller != null) {
      return controller.stream;
    }
    return Stream.value(0.0);
  }

  Future<Directory> _getDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    
    return downloadDir;
  }

  Future<void> dispose() async {
    // 取消所有下載
    for (final cancelToken in _cancelTokens.values) {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('應用程式關閉');
      }
    }
    
    // 關閉所有進度控制器
    for (final controller in _progressControllers.values) {
      await controller.close();
    }
    
    _cancelTokens.clear();
    _progressControllers.clear();
    await _downloadController.close();
  }

  // 獲取下載文件大小
  Future<int> getDownloadedFileSize(String episodeId) async {
    try {
      final downloadDir = await _getDownloadDirectory();
      final filename = '$episodeId.mp3';
      final file = File('${downloadDir.path}/$filename');
      
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // 獲取所有下載文件的總大小
  Future<int> getTotalDownloadSize() async {
    try {
      final downloadDir = await _getDownloadDirectory();
      int totalSize = 0;
      
      if (await downloadDir.exists()) {
        final files = downloadDir.listSync();
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // 清空所有下載
  Future<void> clearAllDownloads() async {
    try {
      final downloadDir = await _getDownloadDirectory();
      
      if (await downloadDir.exists()) {
        await downloadDir.delete(recursive: true);
        await downloadDir.create(recursive: true);
      }
    } catch (e) {
      throw Exception('清空下載失敗: $e');
    }
  }

  Future<void> deleteDownloadedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('刪除文件失敗: $e');
    }
  }
} 