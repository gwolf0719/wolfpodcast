import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_session/audio_session.dart';

import '../../domain/entities/episode.dart';


class AudioPlayerService extends BaseAudioHandler {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }

  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final BehaviorSubject<List<MediaItem>> _queueSubject = BehaviorSubject.seeded(<MediaItem>[]);
  final BehaviorSubject<MediaItem?> _currentMediaItemSubject = BehaviorSubject<MediaItem?>();
  final BehaviorSubject<PlayMode> _playModeSubject = BehaviorSubject.seeded(PlayMode.sequential);
  bool _isInitialized = false;

  // 播放狀態流
  final BehaviorSubject<PlaybackState> _playbackStateSubject = 
      BehaviorSubject<PlaybackState>.seeded(PlaybackState());

  @override
  BehaviorSubject<PlaybackState> get playbackState => _playbackStateSubject;

  // 音頻播放器狀態流
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  
  // 播放進度流
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  // 正在播放狀態流
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  // 當前播放項目
  Stream<MediaItem?> get currentMediaItem => _currentMediaItemSubject.stream;

  // 播放模式
  Stream<PlayMode> get playMode => _playModeSubject.stream;

  // 播放進度
  Stream<Duration> get position => _audioPlayer.positionStream;

  // 播放總長度
  Stream<Duration?> get duration => _audioPlayer.durationStream;

  // 播放速度
  Stream<double> get speed => _audioPlayer.speedStream;

  // 緩衝進度
  Stream<Duration> get bufferedPosition => _audioPlayer.bufferedPositionStream;

  @override
  Future<void> prepare() async {
    if (_isInitialized) return;
    
    // 初始化音頻會話
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
    
    // 監聽播放完成事件
    _audioPlayer.playerStateStream.listen((state) {
      _updatePlaybackState();
      if (state.processingState == ProcessingState.completed) {
        _onEpisodeCompleted();
      }
    });

    // 監聽位置變化
    _audioPlayer.positionStream.listen((position) {
      _updatePlaybackState();
    });

    _isInitialized = true;
  }

  @override
  Future<void> play() async {
    await prepare();
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentMediaItemSubject.add(null);
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    final currentIndex = _audioPlayer.currentIndex;
    if (currentIndex != null) {
      final nextIndex = _getNextIndex(currentIndex);
      if (nextIndex != null) {
        await _audioPlayer.seek(Duration.zero, index: nextIndex);
        await _audioPlayer.play();
        _updateCurrentMediaItem(nextIndex);
      }
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = _audioPlayer.currentIndex;
    if (currentIndex != null) {
      final prevIndex = _getPreviousIndex(currentIndex);
      if (prevIndex != null) {
        await _audioPlayer.seek(Duration.zero, index: prevIndex);
        await _audioPlayer.play();
        _updateCurrentMediaItem(prevIndex);
      }
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  /// 獲取當前播放速度
  Future<double> getSpeed() async {
    return _audioPlayer.speed;
  }

  /// 設置音量
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// 獲取音量
  Future<double> getVolume() async {
    return _audioPlayer.volume;
  }

  // 播放單個集數
  Future<void> playEpisode(Episode episode) async {
    await prepare();
    final mediaItem = _episodeToMediaItem(episode);
    await updateQueue([mediaItem]);
    await skipToQueueItem(0);
    await play();
  }

  // 播放播放清單
  Future<void> playPlaylist(List<Episode> episodes, {int startIndex = 0}) async {
    await prepare();
    final mediaItems = episodes.map(_episodeToMediaItem).toList();
    await updateQueue(mediaItems);
    await skipToQueueItem(startIndex);
    await play();
  }

  // 添加到佇列
  Future<void> addToQueue(Episode episode) async {
    final mediaItem = _episodeToMediaItem(episode);
    final currentQueue = _queueSubject.value;
    await updateQueue([...currentQueue, mediaItem]);
  }

  // 設置播放模式
  Future<void> setPlayMode(PlayMode mode) async {
    _playModeSubject.add(mode);
    await _updateShuffleMode();
  }

  // 設置睡眠計時器
  Timer? _sleepTimer;
  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimer = Timer(duration, () async {
      await pause();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    _queueSubject.add(queue);
    
    // 轉換為音訊源
    final audioSources = queue.map((item) => 
        AudioSource.uri(Uri.parse(item.id))).toList();
    
    await _audioPlayer.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
    );
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < _queueSubject.value.length) {
      await _audioPlayer.seek(Duration.zero, index: index);
      _updateCurrentMediaItem(index);
    }
  }

  // 私有方法
  MediaItem _episodeToMediaItem(Episode episode) {
    return MediaItem(
      id: episode.audioUrl,
      album: episode.podcastId,
      title: episode.title,
      artist: episode.description,
      duration: episode.duration,
      artUri: Uri.parse(episode.imageUrl),
      extras: {
        'episodeId': episode.id,
        'podcastId': episode.podcastId,
      },
    );
  }

  void _updatePlaybackState() {
    final playerState = _audioPlayer.playerState;
    final playing = playerState.playing;
    final processingState = playerState.processingState;
    
    PlaybackState state;
    
    switch (processingState) {
      case ProcessingState.idle:
        state = PlaybackState(
          controls: [MediaControl.play],
          playing: false,
          processingState: AudioProcessingState.idle,
        );
        break;
      case ProcessingState.loading:
        state = PlaybackState(
          controls: [MediaControl.pause, MediaControl.stop],
          playing: false,
          processingState: AudioProcessingState.loading,
        );
        break;
      case ProcessingState.buffering:
        state = PlaybackState(
          controls: [MediaControl.pause, MediaControl.stop],
          playing: false,
          processingState: AudioProcessingState.buffering,
        );
        break;
      case ProcessingState.ready:
        state = PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          playing: playing,
          processingState: AudioProcessingState.ready,
          updatePosition: _audioPlayer.position,
        );
        break;
      case ProcessingState.completed:
        state = PlaybackState(
          controls: [MediaControl.play],
          playing: false,
          processingState: AudioProcessingState.completed,
        );
        break;
    }
    
    _playbackStateSubject.add(state);
  }

  void _updateCurrentMediaItem(int index) {
    final queue = _queueSubject.value;
    if (index < queue.length) {
      _currentMediaItemSubject.add(queue[index]);
    }
  }

  int? _getNextIndex(int currentIndex) {
    final queue = _queueSubject.value;
    final playMode = _playModeSubject.value;
    
    switch (playMode) {
      case PlayMode.sequential:
        return currentIndex + 1 < queue.length ? currentIndex + 1 : null;
      case PlayMode.repeatAll:
        return currentIndex + 1 < queue.length ? currentIndex + 1 : 0;
      case PlayMode.repeatOne:
        return currentIndex;
      case PlayMode.shuffle:
        // 實現隨機播放邏輯
        final nextIndex = (currentIndex + 1) % queue.length;
        return nextIndex;
    }
  }

  int? _getPreviousIndex(int currentIndex) {
    final queue = _queueSubject.value;
    final playMode = _playModeSubject.value;
    
    switch (playMode) {
      case PlayMode.sequential:
        return currentIndex > 0 ? currentIndex - 1 : null;
      case PlayMode.repeatAll:
        return currentIndex > 0 ? currentIndex - 1 : queue.length - 1;
      case PlayMode.repeatOne:
        return currentIndex;
      case PlayMode.shuffle:
        // 實現隨機播放邏輯
        final prevIndex = currentIndex > 0 ? currentIndex - 1 : queue.length - 1;
        return prevIndex;
    }
  }

  Future<void> _updateShuffleMode() async {
    final playMode = _playModeSubject.value;
    await _audioPlayer.setShuffleModeEnabled(playMode == PlayMode.shuffle);
  }

  void _onEpisodeCompleted() {
    final playMode = _playModeSubject.value;
    
    if (playMode == PlayMode.repeatOne) {
      // 重複播放當前集數
      seek(Duration.zero);
      play();
    } else {
      // 播放下一集
      skipToNext();
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    await _playbackStateSubject.close();
    await _queueSubject.close();
    await _currentMediaItemSubject.close();
    await _playModeSubject.close();
    _sleepTimer?.cancel();
  }
}

enum PlayMode {
  sequential,  // 順序播放
  repeatAll,   // 重複播放列表
  repeatOne,   // 重複播放單曲
  shuffle,     // 隨機播放
} 