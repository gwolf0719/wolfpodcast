import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/episode.dart';
import '../../../domain/repositories/player_repository.dart';

// Events
abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object> get props => [];
}

enum PlayerStatus {
  initial,
  loading,
  playing,
  paused,
  error,
}

class PlayerState extends Equatable {
  final PlayerStatus status;
  final Episode? currentEpisode;
  final Duration position;
  final double speed;
  final double volume;
  final bool isMuted;
  final Duration? sleepTimer;
  final String? error;
  final bool isPlaying;

  const PlayerState({
    this.status = PlayerStatus.initial,
    this.currentEpisode,
    this.position = Duration.zero,
    this.speed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.sleepTimer,
    this.error,
    this.isPlaying = false,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Episode? currentEpisode,
    Duration? position,
    double? speed,
    double? volume,
    bool? isMuted,
    Duration? sleepTimer,
    String? error,
    bool? isPlaying,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      sleepTimer: sleepTimer ?? this.sleepTimer,
      error: error,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentEpisode,
    position,
    speed,
    volume,
    isMuted,
    sleepTimer,
    error,
    isPlaying,
  ];
}

class PlayEpisodeEvent extends PlayerEvent {
  final Episode episode;

  const PlayEpisodeEvent(this.episode);

  @override
  List<Object> get props => [episode];
}

class PausePlaybackEvent extends PlayerEvent {}

class ResumePlaybackEvent extends PlayerEvent {}

class SeekToPositionEvent extends PlayerEvent {
  final Duration position;

  const SeekToPositionEvent(this.position);

  @override
  List<Object> get props => [position];
}

class SetPlaybackSpeedEvent extends PlayerEvent {
  final double speed;

  const SetPlaybackSpeedEvent(this.speed);

  @override
  List<Object> get props => [speed];
}

class SetVolumeEvent extends PlayerEvent {
  final double volume;

  const SetVolumeEvent(this.volume);

  @override
  List<Object> get props => [volume];
}

class ToggleMuteEvent extends PlayerEvent {}

class SetSleepTimerEvent extends PlayerEvent {
  final Duration duration;

  const SetSleepTimerEvent(this.duration);

  @override
  List<Object> get props => [duration];
}

class CancelSleepTimerEvent extends PlayerEvent {}

class UpdatePositionEvent extends PlayerEvent {
  final Duration position;

  const UpdatePositionEvent(this.position);

  @override
  List<Object> get props => [position];
}

// States
abstract class BasePlayerState extends Equatable {
  const BasePlayerState();

  @override
  List<Object> get props => [];
}

class PlayerInitialState extends BasePlayerState {}

class PlayerLoadingState extends BasePlayerState {}

class PlayerPlayingState extends BasePlayerState {
  final Episode episode;
  final Duration position;
  final double speed;
  final double volume;
  final bool isMuted;
  final Duration? sleepTimer;

  const PlayerPlayingState({
    required this.episode,
    required this.position,
    required this.speed,
    required this.volume,
    required this.isMuted,
    this.sleepTimer,
  });

  @override
  List<Object> get props => [
    episode,
    position,
    speed,
    volume,
    isMuted,
    if (sleepTimer != null) sleepTimer!,
  ];
}

class PlayerPausedState extends BasePlayerState {
  final Episode episode;
  final Duration position;
  final double speed;
  final double volume;
  final bool isMuted;
  final Duration? sleepTimer;

  const PlayerPausedState({
    required this.episode,
    required this.position,
    required this.speed,
    required this.volume,
    required this.isMuted,
    this.sleepTimer,
  });

  @override
  List<Object> get props => [
    episode,
    position,
    speed,
    volume,
    isMuted,
    if (sleepTimer != null) sleepTimer!,
  ];
}

class PlayerErrorState extends BasePlayerState {
  final String message;

  const PlayerErrorState(this.message);

  @override
  List<Object> get props => [message];
}

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final PlayerRepository playerRepository;
  final EpisodeRepository episodeRepository;
  Timer? _sleepTimer;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playbackStateSubscription;

  PlayerBloc({
    required this.playerRepository,
    required this.episodeRepository,
  }) : super(const PlayerState()) {
    on<PlayEpisodeEvent>(_onPlayEpisode);
    on<PausePlaybackEvent>(_onPausePlayback);
    on<ResumePlaybackEvent>(_onResumePlayback);
    on<SeekToPositionEvent>(_onSeekToPosition);
    on<SetPlaybackSpeedEvent>(_onSetPlaybackSpeed);
    on<SetVolumeEvent>(_onSetVolume);
    on<ToggleMuteEvent>(_onToggleMute);
    on<SetSleepTimerEvent>(_onSetSleepTimer);
    on<CancelSleepTimerEvent>(_onCancelSleepTimer);

    // Listen to position updates
    _positionSubscription = playerRepository.positionStream.listen((position) {
      if (state.currentEpisode != null) {
        add(UpdatePositionEvent(position));
      }
    });

    // Listen to playback state changes
    _playbackStateSubscription = playerRepository.playbackStateStream.listen((isPlaying) {
      if (isPlaying) {
        add(ResumePlaybackEvent());
      } else {
        add(PausePlaybackEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _sleepTimer?.cancel();
    return super.close();
  }

  Future<void> _onPlayEpisode(
    PlayEpisodeEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      emit(state.copyWith(
        status: PlayerStatus.loading,
        error: null,
      ));

      await playerRepository.playEpisode(event.episode);
      
      // Save last played episode
      await episodeRepository.updateEpisode(
        event.episode.copyWith(
          isPlayed: true,
          position: Duration.zero,
        ),
      );

      emit(state.copyWith(
        status: PlayerStatus.playing,
        currentEpisode: event.episode,
        isPlaying: true,
        position: Duration.zero,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onPausePlayback(
    PausePlaybackEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await playerRepository.pausePlayback();
      
      if (state.currentEpisode != null) {
        // Save current position
        await episodeRepository.updateEpisode(
          state.currentEpisode!.copyWith(
            position: state.position,
          ),
        );
      }

      emit(state.copyWith(
        status: PlayerStatus.paused,
        isPlaying: false,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onResumePlayback(
    ResumePlaybackEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      if (state.currentEpisode == null) {
        throw Exception('No episode selected');
      }

      await playerRepository.resumePlayback();
      
      emit(state.copyWith(
        status: PlayerStatus.playing,
        isPlaying: true,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PlayerStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSeekToPosition(
    SeekToPositionEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await playerRepository.seekToPosition(event.position);
      emit(state.copyWith(position: event.position));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeedEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await playerRepository.setPlaybackSpeed(event.speed);
      emit(state.copyWith(playbackSpeed: event.speed));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSetVolume(
    SetVolumeEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await playerRepository.setVolume(event.volume);
      emit(state.copyWith(volume: event.volume));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<PlayerState> emit,
  ) async {
    try {
      await playerRepository.toggleMute();
      final isMuted = await playerRepository.isMuted();
      emit(state.copyWith(isMuted: isMuted));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSetSleepTimer(
    SetSleepTimerEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _sleepTimer?.cancel();
    
    _sleepTimer = Timer(event.duration, () async {
      await playerRepository.pausePlayback();
      add(PausePlaybackEvent());
    });

    emit(state.copyWith(
      sleepTimer: event.duration,
      error: null,
    ));
  }

  Future<void> _onCancelSleepTimer(
    CancelSleepTimerEvent event,
    Emitter<PlayerState> emit,
  ) async {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    emit(state.copyWith(
      sleepTimer: null,
      error: null,
    ));
  }
} 