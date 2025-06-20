class AppConstants {
  // App Info
  static const String appName = 'Wolf Podcast';
  static const String appVersion = '1.0.0';
  static const String userAgent = 'Wolf Podcast/1.0.0';
  
  // Database
  static const String databaseName = 'wolf_podcast.db';
  static const int databaseVersion = 1;
  
  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String playlistsBox = 'playlists';
  static const String episodesBox = 'episodes';
  
  // API & Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Player Settings
  static const Duration seekDuration = Duration(seconds: 15);
  static const Duration maxSleepTimer = Duration(hours: 2);
  static const double minPlaybackSpeed = 0.5;
  static const double maxPlaybackSpeed = 3.0;
  
  // UI Constants
  static const double bottomPlayerHeight = 80.0;
  static const double carModeButtonSize = 60.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Storage Keys
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String lastPlayedKey = 'last_played';
  static const String autoPlayKey = 'auto_play';
  static const String playbackSpeedKey = 'playback_speed';
  static const String skipSilenceKey = 'skip_silence';
  
  // Car Mode
  static const String carModeKey = 'car_mode';
  static const double carModeMinButtonSize = 44.0;
  
  // Error Messages
  static const String noInternetError = '無網路連線';
  static const String searchError = '搜尋失敗，請重試';
  static const String playbackError = '播放失敗';
  static const String downloadError = '下載失敗';
  
  // Cache Settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // Audio Settings
  static const int defaultBufferSize = 8192;
  static const Duration seekThreshold = Duration(seconds: 5);
  
  // UI Settings
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  
  // Pagination Settings
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// Podcast Category Model
class PodcastCategory {
  final String id;
  final String name;
  final String englishName;
  final List<String> subcategories;

  const PodcastCategory({
    required this.id,
    required this.name,
    required this.englishName,
    this.subcategories = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PodcastCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PodcastCategory(id: $id, name: $name)';
} 