import '../entities/episode.dart';

abstract class PlayerRepository {
  Future<void> playEpisode(Episode episode);
  Future<void> pausePlayback();
  Future<void> resumePlayback();
  Future<void> seekToPosition(Duration position);
  Future<void> setPlaybackSpeed(double speed);
  Future<double> getPlaybackSpeed();
  Stream<Duration> get position;
  Stream<bool> get isPlaying;
  Stream<Duration> get positionStream;
  Stream<dynamic> get playbackStateStream;
  
  /// 設置音量
  /// [volume] 音量大小，範圍 0.0 到 1.0
  Future<void> setVolume(double volume);
  
  /// 獲取當前音量
  Future<double> getVolume();
  
  /// 靜音切換
  Future<void> toggleMute();
  
  /// 獲取靜音狀態
  Future<bool> isMuted();
  
  /// 設置睡眠定時器
  /// [duration] 定時器時長，null 表示取消定時器
  Future<void> setSleepTimer(Duration? duration);
  
  /// 獲取剩餘睡眠時間
  Future<Duration?> getRemainingTime();
  
  /// 取消睡眠定時器
  Future<void> cancelSleepTimer();
  
  /// 睡眠定時器狀態流
  Stream<Duration?> get sleepTimerStream;
  
  void dispose();
} 