import 'package:just_audio/just_audio.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/audio_player_service.dart';
import '../../core/storage/hive_storage.dart';
import 'dart:async';

class PlayerRepositoryImpl implements PlayerRepository {
  final AudioPlayerService _audioPlayerService;
  final HiveStorage hiveStorage;
  double _lastVolume = 1.0;
  bool _isMuted = false;
  Timer? _sleepTimer;
  final _sleepTimerController = StreamController<Duration?>.broadcast();
  Duration? _remainingTime;

  PlayerRepositoryImpl({
    required AudioPlayerService audioPlayerService,
    required this.hiveStorage,
  }) : _audioPlayerService = audioPlayerService {
    _startSleepTimerUpdates();
  }

  void _startSleepTimerUpdates() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime != null && _remainingTime! > Duration.zero) {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);
        _sleepTimerController.add(_remainingTime);
      }
    });
  }

  @override
  Future<void> playEpisode(Episode episode) async {
    try {
      final audioSource = episode.downloadPath != null
          ? AudioSource.uri(Uri.file(episode.downloadPath!))
          : AudioSource.uri(Uri.parse(episode.audioUrl));
      await _audioPlayerService.setAudioSource(audioSource);
      await _audioPlayerService.play();
      
      // 保存最後播放的節目
      await hiveStorage.setLastPlayed({
        'id': episode.id,
        'title': episode.title,
        'audioUrl': episode.audioUrl,
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> pausePlayback() async {
    try {
      await _audioPlayerService.pause();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> resumePlayback() async {
    try {
      await _audioPlayerService.play();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> seekToPosition(Duration position) async {
    try {
      await _audioPlayerService.seek(position);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayerService.setSpeed(speed);
      await hiveStorage.setPlaybackSpeed(speed);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double> getPlaybackSpeed() async {
    return await _audioPlayerService.getSpeed();
  }

  @override
  Stream<Duration> get position => _audioPlayerService.positionStream;

  @override
  Stream<bool> get isPlaying => _audioPlayerService.playingStream;

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayerService.setVolume(volume);
      _lastVolume = volume;
      _isMuted = volume == 0.0;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double> getVolume() async {
    return await _audioPlayerService.getVolume();
  }

  @override
  Future<void> toggleMute() async {
    if (_isMuted) {
      await setVolume(_lastVolume);
      _isMuted = false;
    } else {
      _lastVolume = await getVolume();
      await setVolume(0.0);
      _isMuted = true;
    }
  }

  @override
  Future<bool> isMuted() async {
    return _isMuted;
  }

  @override
  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _remainingTime = duration;
    
    if (duration != null) {
      _sleepTimer = Timer(duration, () async {
        await pausePlayback();
        _remainingTime = null;
        _sleepTimerController.add(null);
      });
      _sleepTimerController.add(duration);
    } else {
      _sleepTimerController.add(null);
    }
  }

  @override
  Future<Duration?> getRemainingTime() async {
    return _remainingTime;
  }

  @override
  Future<void> cancelSleepTimer() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _remainingTime = null;
    _sleepTimerController.add(null);
  }

  @override
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerController.close();
  }
} 