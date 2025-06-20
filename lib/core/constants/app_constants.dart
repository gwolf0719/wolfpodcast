class AppConstants {
  // App Info
  static const String appName = 'Wolf Podcast';
  static const String appVersion = '1.0.0';
  
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
} 