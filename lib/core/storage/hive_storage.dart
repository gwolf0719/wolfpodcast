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
    
    // 註冊 Adapters（避免重複註冊）
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PodcastModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(EpisodeModelAdapter());
    }
    
    // 檢查並打開所有需要的 Box，避免重複開啟
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    } else {
      _settingsBox = Hive.box(AppConstants.settingsBox);
    }
    
    if (!Hive.isBoxOpen(AppConstants.playlistsBox)) {
      _playlistsBox = await Hive.openBox(AppConstants.playlistsBox);
    } else {
      _playlistsBox = Hive.box(AppConstants.playlistsBox);
    }
    
    if (!Hive.isBoxOpen(AppConstants.episodesBox)) {
      _episodesBox = await Hive.openBox(AppConstants.episodesBox);
    } else {
      _episodesBox = Hive.box(AppConstants.episodesBox);
    }
  }

  /// 開啟指定的 Box
  Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
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
  // Subscription 相關方法  
  // =======================================

  /// 獲取訂閱分類
  Future<List<String>> getSubscriptionCategories() async {
    final categories = getSetting<List>('subscription_categories', defaultValue: <String>[]);
    return categories?.cast<String>() ?? <String>[];
  }

  /// 獲取指定分類的訂閱
  Future<List<dynamic>> getSubscriptionsByCategory(String category) async {
    final subscriptions = getSetting<List>('subscriptions_$category', defaultValue: <dynamic>[]);
    return subscriptions ?? <dynamic>[];
  }
  
  // =======================================
  // 通用方法
  // =======================================
  
  /// 關閉所有 Box
  Future<void> close() async {
    await _settingsBox.close();
    await _playlistsBox.close();
    await _episodesBox.close();
  }
  
  /// 清空所有快取
  Future<void> clearAllCache() async {
    await clearSettings();
    await clearPlaylistCache();
    await clearEpisodeCache();
  }
  
  /// 獲取儲存大小
  int getStorageSize() {
    return _settingsBox.length + _playlistsBox.length + _episodesBox.length;
  }

  // 熱門播客快取鍵
  static const String _popularPodcastsKey = 'popular_podcasts';

  /// 緩存熱門播客
  Future<void> cachePopularPodcasts(List<PodcastModel> podcasts) async {
    final data = podcasts.map((p) => p.toJson()).toList();
    await setSetting(_popularPodcastsKey, data);
  }

  /// 獲取快取的熱門播客
  Future<List<PodcastModel>> getCachedPopularPodcasts() async {
    final data = getSetting<List>(_popularPodcastsKey, defaultValue: <dynamic>[]);
    if (data == null) return <PodcastModel>[];
    
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      return PodcastModel.fromJson(map);
    }).toList();
  }

  /// 保存 Episode 到快取，帶 guid 支援
  Future<void> saveEpisodeWithGuid(EpisodeModel episode) async {
    final episodeData = {
      'id': episode.id,
      'podcastId': episode.podcastId,
      'title': episode.title,
      'description': episode.description,
      'imageUrl': episode.imageUrl,
      'audioUrl': episode.audioUrl,
      'duration': episode.duration.inSeconds,
      'publishDate': episode.publishDate.toIso8601String(),
      'downloadPath': episode.downloadPath,
      'isDownloaded': episode.isDownloaded,
      'isDownloading': episode.isDownloading,
      'downloadProgress': episode.downloadProgress,
      'isPlayed': episode.isPlayed,
      'position': episode.position?.inSeconds,
      'episodeNumber': episode.episodeNumber,
      'seasonNumber': episode.seasonNumber,
      'guid': episode.guid,
    };
    
    await cacheEpisode(episode.id, episodeData);
  }

  /// 從快取獲取 Episode，帶 guid 支援
  EpisodeModel? getCachedEpisodeWithGuid(String episodeId) {
    final data = getCachedEpisode(episodeId);
    if (data == null) return null;

    return EpisodeModel(
      id: data['id'] as String,
      podcastId: data['podcastId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      imageUrl: data['imageUrl'] as String,
      audioUrl: data['audioUrl'] as String,
      duration: Duration(seconds: data['duration'] as int),
      publishDate: DateTime.parse(data['publishDate'] as String),
      downloadPath: data['downloadPath'] as String?,
      isDownloaded: data['isDownloaded'] as bool? ?? false,
      isDownloading: data['isDownloading'] as bool? ?? false,
      downloadProgress: data['downloadProgress'] as double? ?? 0.0,
      isPlayed: data['isPlayed'] as bool? ?? false,
      position: data['position'] != null
          ? Duration(seconds: data['position'] as int)
          : null,
      episodeNumber: data['episodeNumber'] as int?,
      seasonNumber: data['seasonNumber'] as int?,
      guid: data['guid'] as String?,
    );
  }

  // =======================================
  // Podcast 相關方法
  // =======================================

  /// 更新播客信息
  Future<void> updatePodcast(PodcastModel podcast) async {
    final podcastData = podcast.toJson();
    await setSetting('podcast_${podcast.id}', podcastData);
  }

  /// 獲取熱門播客（簡化版本，返回快取的列表）
  Future<List<PodcastModel>> getPopularPodcasts() async {
    return await getCachedPopularPodcasts();
  }

  /// 設置自動更新啟用狀態
  Future<void> setAutoUpdateEnabled(bool enabled) async {
    await setSetting('auto_update_enabled', enabled);
  }

  /// 獲取自動更新啟用狀態
  Future<bool> getAutoUpdateEnabled() async {
    return getSetting<bool>('auto_update_enabled', defaultValue: false) ?? false;
  }

  /// 獲取 episodes box 的訪問器
  Box get episodeBox => _episodesBox;
} 