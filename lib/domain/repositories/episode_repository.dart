import '../../data/datasources/download_manager.dart';
import '../entities/episode.dart';

abstract class EpisodeRepository {
  Stream<DownloadProgress> get downloadProgress;
  
  Future<List<Episode>> getEpisodes(String podcastId);
  Future<Episode?> getEpisode(String episodeId);
  Future<void> updatePlaybackPosition(String episodeId, Duration position);
  Future<void> markAsPlayed(String episodeId);
  Future<void> downloadEpisode(Episode episode);
  void cancelDownload(String episodeId);
  Future<void> deleteDownloadedEpisode(String episodeId);
  Future<List<Episode>> getEpisodesByPodcastId(String podcastId);
  Future<Episode?> getEpisodeById(String id);
  Future<bool> isEpisodeDownloaded(String episodeId);
  Stream<double> getDownloadProgress(String episodeId);
  Future<List<Episode>> getDownloadedEpisodes();
} 