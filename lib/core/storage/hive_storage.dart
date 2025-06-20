import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../data/models/podcast_model.dart';
import '../../data/models/episode_model.dart';

class HiveStorage {
  static final HiveStorage _instance = HiveStorage._internal();
  static HiveStorage get instance => _instance;
  
  HiveStorage._internal();
  
  late Box _settingsBox;
  late Box _playlistsBox;
  late Box _episodesBox;
  
  /// 初始化 Hive 存儲
  Future<void> init() async {
    await Hive.initFlutter();
    
    // 打開所有需要的 Box
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _playlistsBox = await Hive.openBox(AppConstants.playlistsBox);
    _episodesBox = await Hive.openBox(AppConstants.episodesBox);
  }
  
  // =======================================
  // Settings 相關方法
  // =======================================
  
  /// 保存設定值
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  /// 獲取設定值
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }
  
  /// 刪除設定
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }
  
  /// 清空所有設定
  Future<void> clearSettings() async {
    await _settingsBox.clear();
  }
  
  // =======================================
  // Theme 相關方法
  // =======================================
  
  /// 保存主題模式
  Future<void> setThemeMode(String themeMode) async {
    await setSetting(AppConstants.themeKey, themeMode);
  }
  
  /// 獲取主題模式
  String? getThemeMode() {
    return getSetting<String>(AppConstants.themeKey, defaultValue: 'system');
  }
  
  // =======================================
  // Language 相關方法
  // =======================================
  
  /// 保存語言設定
  Future<void> setLanguage(String language) async {
    await setSetting(AppConstants.languageKey, language);
  }
  
  /// 獲取語言設定
  String? getLanguage() {
    return getSetting<String>(AppConstants.languageKey, defaultValue: 'zh_TW');
  }
  
  // =======================================
  // Player 相關方法
  // =======================================
  
  /// 保存最後播放的節目
  Future<void> setLastPlayed(Map<String, dynamic> episodeData) async {
    await setSetting(AppConstants.lastPlayedKey, episodeData);
  }
  
  /// 獲取最後播放的節目
  Map<String, dynamic>? getLastPlayed() {
    final data = getSetting<Map>(AppConstants.lastPlayedKey);
    return data?.cast<String, dynamic>();
  }
  
  /// 保存自動播放設定
  Future<void> setAutoPlay(bool autoPlay) async {
    await setSetting(AppConstants.autoPlayKey, autoPlay);
  }
  
  /// 獲取自動播放設定
  bool getAutoPlay() {
    return getSetting<bool>(AppConstants.autoPlayKey, defaultValue: false) ?? false;
  }
  
  /// 保存播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    await setSetting(AppConstants.playbackSpeedKey, speed);
  }
  
  /// 獲取播放速度
  double getPlaybackSpeed() {
    return getSetting<double>(AppConstants.playbackSpeedKey, defaultValue: 1.0) ?? 1.0;
  }
  
  /// 保存跳過靜音設定
  Future<void> setSkipSilence(bool skipSilence) async {
    await setSetting(AppConstants.skipSilenceKey, skipSilence);
  }
  
  /// 獲取跳過靜音設定
  bool getSkipSilence() {
    return getSetting<bool>(AppConstants.skipSilenceKey, defaultValue: false) ?? false;
  }
  
  // =======================================
  // Car Mode 相關方法
  // =======================================
  
  /// 保存車用模式設定
  Future<void> setCarMode(bool carMode) async {
    await setSetting(AppConstants.carModeKey, carMode);
  }
  
  /// 獲取車用模式設定
  bool getCarMode() {
    return getSetting<bool>(AppConstants.carModeKey, defaultValue: false) ?? false;
  }
  
  // =======================================
  // Playlist 相關方法
  // =======================================
  
  /// 保存播放列表快取
  Future<void> cachePlaylist(String playlistId, Map<String, dynamic> data) async {
    await _playlistsBox.put(playlistId, data);
  }
  
  /// 獲取播放列表快取
  Map<String, dynamic>? getCachedPlaylist(String playlistId) {
    final data = _playlistsBox.get(playlistId);
    return data?.cast<String, dynamic>();
  }
  
  /// 刪除播放列表快取
  Future<void> deleteCachedPlaylist(String playlistId) async {
    await _playlistsBox.delete(playlistId);
  }
  
  /// 清空播放列表快取
  Future<void> clearPlaylistCache() async {
    await _playlistsBox.clear();
  }
  
  // =======================================
  // Episode 相關方法
  // =======================================
  
  /// 保存節目播放位置
  Future<void> setEpisodePosition(String episodeId, int position) async {
    await _episodesBox.put('${episodeId}_position', position);
  }
  
  /// 獲取節目播放位置
  int getEpisodePosition(String episodeId) {
    return _episodesBox.get('${episodeId}_position', defaultValue: 0) ?? 0;
  }
  
  /// 檢查節目是否已播放
  bool isEpisodePlayed(String episodeId) {
    return _episodesBox.get('${episodeId}_played', defaultValue: false) ?? false;
  }
  
  /// 保存節目快取資料
  Future<void> cacheEpisode(String episodeId, Map<String, dynamic> data) async {
    await _episodesBox.put(episodeId, data);
  }
  
  /// 獲取節目快取資料
  Map<String, dynamic>? getCachedEpisode(String episodeId) {
    final data = _episodesBox.get(episodeId);
    return data?.cast<String, dynamic>();
  }
  
  /// 清空節目快取
  Future<void> clearEpisodeCache() async {
    await _episodesBox.clear();
  }
  
  // =======================================
  // 通用方法
  // =======================================
  
  /// 獲取所有設定
  Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_settingsBox.toMap());
  }
  
  /// 匯出所有資料
  Map<String, dynamic> exportAllData() {
    return {
      'settings': _settingsBox.toMap(),
      'playlists': _playlistsBox.toMap(),
      'episodes': _episodesBox.toMap(),
    };
  }
  
  /// 匯入資料
  Future<void> importData(Map<String, dynamic> data) async {
    if (data.containsKey('settings')) {
      await _settingsBox.clear();
      await _settingsBox.putAll(Map<String, dynamic>.from(data['settings']));
    }
    
    if (data.containsKey('playlists')) {
      await _playlistsBox.clear();
      await _playlistsBox.putAll(Map<String, dynamic>.from(data['playlists']));
    }
    
    if (data.containsKey('episodes')) {
      await _episodesBox.clear();
      await _episodesBox.putAll(Map<String, dynamic>.from(data['episodes']));
    }
  }
  
  /// 清空所有快取
  Future<void> clearAllCache() async {
    await _settingsBox.clear();
    await _playlistsBox.clear();
    await _episodesBox.clear();
  }
  
  /// 關閉所有 Box
  Future<void> close() async {
    await _settingsBox.close();
    await _playlistsBox.close();
    await _episodesBox.close();
  }
  
  /// 獲取快取大小統計
  Map<String, int> getCacheStats() {
    return {
      'settings_count': _settingsBox.length,
      'playlists_count': _playlistsBox.length,
      'episodes_count': _episodesBox.length,
    };
  }

  static const String _popularPodcastsBoxName = 'popular_podcasts';
  static const String _popularPodcastsKey = 'popular_podcasts_list';
  
  Future<void> setPopularPodcasts(List<PodcastModel> podcasts) async {
    final box = await Hive.openBox<PodcastModel>(_popularPodcastsBoxName);
    await box.clear();
    await box.addAll(podcasts);
  }

  Future<List<PodcastModel>> getPopularPodcasts() async {
    final box = await Hive.openBox<PodcastModel>(_popularPodcastsBoxName);
    return box.values.toList();
  }

  Future<void> updatePodcast(PodcastModel podcast) async {
    final box = await Hive.openBox<PodcastModel>('podcasts');
    await box.put(podcast.id, podcast);
  }

  Future<PodcastModel?> getPodcast(String id) async {
    final box = await Hive.openBox<PodcastModel>('podcasts');
    return box.get(id);
  }

  static const String _settingsBoxName = 'settings';
  static const String _autoUpdateKey = 'auto_update_enabled';

  Future<void> setAutoUpdateEnabled(bool enabled) async {
    final box = await Hive.openBox(_settingsBoxName);
    await box.put(_autoUpdateKey, enabled);
  }

  Future<bool> getAutoUpdateEnabled() async {
    final box = await Hive.openBox(_settingsBoxName);
    return box.get(_autoUpdateKey, defaultValue: false);
  }

  Future<void> saveEpisode(EpisodeModel episode) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    await box.put(episode.id, episode);
  }

  Future<EpisodeModel?> getEpisode(String id) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    return box.get(id);
  }

  Future<List<EpisodeModel>> getEpisodesByPodcast(String podcastId) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    return box.values.where((episode) => episode.podcastId == podcastId).toList();
  }

  Future<void> updateEpisodePlaybackPosition(String episodeId, Duration position) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    final episode = box.get(episodeId);
    if (episode != null) {
      final updatedEpisode = EpisodeModel(
        id: episode.id,
        title: episode.title,
        description: episode.description,
        audioUrl: episode.audioUrl,
        imageUrl: episode.imageUrl,
        duration: episode.duration,
        publishDate: episode.publishDate,
        podcastId: episode.podcastId,
        guid: episode.guid,
        isPlayed: episode.isPlayed,
        position: position,
        downloadPath: episode.downloadPath,
        isDownloaded: episode.isDownloaded,
        episodeNumber: episode.episodeNumber,
        seasonNumber: episode.seasonNumber,
      );
      await box.put(episodeId, updatedEpisode);
    }
  }

  Future<void> markEpisodeAsPlayed(String episodeId) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    final episode = box.get(episodeId);
    if (episode != null) {
      final updatedEpisode = EpisodeModel(
        id: episode.id,
        title: episode.title,
        description: episode.description,
        audioUrl: episode.audioUrl,
        imageUrl: episode.imageUrl,
        duration: episode.duration,
        publishDate: episode.publishDate,
        podcastId: episode.podcastId,
        guid: episode.guid,
        isPlayed: true,
        position: episode.position,
        downloadPath: episode.downloadPath,
        isDownloaded: episode.isDownloaded,
        episodeNumber: episode.episodeNumber,
        seasonNumber: episode.seasonNumber,
      );
      await box.put(episodeId, updatedEpisode);
    }
  }

  Future<void> updateEpisodeDownloadStatus(String episodeId, String downloadPath) async {
    final box = await Hive.openBox<EpisodeModel>('episodes');
    final episode = box.get(episodeId);
    if (episode != null) {
      final updatedEpisode = EpisodeModel(
        id: episode.id,
        title: episode.title,
        description: episode.description,
        audioUrl: episode.audioUrl,
        imageUrl: episode.imageUrl,
        duration: episode.duration,
        publishDate: episode.publishDate,
        podcastId: episode.podcastId,
        guid: episode.guid,
        isPlayed: episode.isPlayed,
        position: episode.position,
        downloadPath: downloadPath,
        isDownloaded: true,
        episodeNumber: episode.episodeNumber,
        seasonNumber: episode.seasonNumber,
      );
      await box.put(episodeId, updatedEpisode);
    }
  }
} 