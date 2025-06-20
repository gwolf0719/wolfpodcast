import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_session/audio_session.dart';

import '../../domain/entities/episode.dart';
import '../../domain/entities/playlist.dart';

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
  @override
  BehaviorSubject<PlaybackState> get playbackState => 
      BehaviorSubject<PlaybackState>.seeded(PlaybackState());

  // 播放狀態流
  Stream<PlaybackState> get playerState => _audioPlayer.playbackEventStream
      .map((event) => _transformPlaybackEvent(event));

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
    await _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: []));
    
    // 監聽播放完成事件
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onEpisodeCompleted();
      }
    });
  }

  @override
  Future<void> play() async {
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

  // 播放單個集數
  Future<void> playEpisode(Episode episode) async {
    final mediaItem = _episodeToMediaItem(episode);
    await updateQueue([mediaItem]);
    await skipToQueueItem(0);
    await play();
  }

  // 播放播放清單
  Future<void> playPlaylist(List<Episode> episodes, {int startIndex = 0}) async {
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
      _currentMediaItemSubject.add(_queueSubject.value[index]);
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

  PlaybackState _transformPlaybackEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_audioPlayer.processingState]!,
      playing: _audioPlayer.playing,
      updatePosition: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
      queueIndex: _audioPlayer.currentIndex,
    );
  }

  void _onEpisodeCompleted() {
    // 根據播放模式決定下一步行動
    final currentIndex = _audioPlayer.currentIndex;
    if (currentIndex != null) {
      final nextIndex = _getNextIndex(currentIndex);
      if (nextIndex != null) {
        skipToNext();
      } else {
        // 播放清單結束
        stop();
      }
    }
  }

  int? _getNextIndex(int currentIndex) {
    final queue = _queueSubject.value;
    final mode = _playModeSubject.value;
    
    switch (mode) {
      case PlayMode.sequential:
        return currentIndex < queue.length - 1 ? currentIndex + 1 : null;
      case PlayMode.shuffle:
        if (queue.length <= 1) return null;
        int nextIndex;
        do {
          nextIndex = DateTime.now().millisecondsSinceEpoch % queue.length;
        } while (nextIndex == currentIndex);
        return nextIndex;
      case PlayMode.repeat:
        return currentIndex < queue.length - 1 ? currentIndex + 1 : 0;
      case PlayMode.repeatOne:
        return currentIndex;
    }
  }

  int? _getPreviousIndex(int currentIndex) {
    final queue = _queueSubject.value;
    final mode = _playModeSubject.value;
    
    switch (mode) {
      case PlayMode.sequential:
        return currentIndex > 0 ? currentIndex - 1 : null;
      case PlayMode.shuffle:
        if (queue.length <= 1) return null;
        int prevIndex;
        do {
          prevIndex = DateTime.now().millisecondsSinceEpoch % queue.length;
        } while (prevIndex == currentIndex);
        return prevIndex;
      case PlayMode.repeat:
        return currentIndex > 0 ? currentIndex - 1 : queue.length - 1;
      case PlayMode.repeatOne:
        return currentIndex;
    }
  }

  Future<void> _updateShuffleMode() async {
    final mode = _playModeSubject.value;
    await _audioPlayer.setShuffleModeEnabled(mode == PlayMode.shuffle);
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }

  void dispose() {
    _audioPlayer.dispose();
    _queueSubject.close();
    _currentMediaItemSubject.close();
    _playModeSubject.close();
    _sleepTimer?.cancel();
  }

  /// 設置音量
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  /// 獲取當前音量
  Future<double> getVolume() async {
    return _audioPlayer.volume;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _isInitialized = true;
  }

  Future<void> setAudioSource(AudioSource source) async {
    await initialize();
    await _audioPlayer.setAudioSource(source);
  }

  @override
  BehaviorSubject<List<MediaItem>> get queue => _queueSubject;
  
  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  
  @override
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  
  @override
  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;
} 