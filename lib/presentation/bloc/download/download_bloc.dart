import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/episode.dart';
import '../../../domain/repositories/episode_repository.dart';

// Events
abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object> get props => [];
}

class StartDownloadEvent extends DownloadEvent {
  final Episode episode;

  const StartDownloadEvent(this.episode);

  @override
  List<Object> get props => [episode];
}

class CancelDownloadEvent extends DownloadEvent {
  final String episodeId;

  const CancelDownloadEvent(this.episodeId);

  @override
  List<Object> get props => [episodeId];
}

class DeleteDownloadEvent extends DownloadEvent {
  final String episodeId;

  const DeleteDownloadEvent(this.episodeId);

  @override
  List<Object> get props => [episodeId];
}

class LoadDownloadsEvent extends DownloadEvent {}

class UpdateDownloadProgressEvent extends DownloadEvent {
  final String episodeId;
  final double progress;

  const UpdateDownloadProgressEvent(this.episodeId, this.progress);

  @override
  List<Object> get props => [episodeId, progress];
}

// States
abstract class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object> get props => [];
}

class DownloadInitial extends DownloadState {}

class DownloadInProgress extends DownloadState {
  final Map<String, double> downloadProgress;
  final List<Episode> downloadedEpisodes;

  const DownloadInProgress({
    required this.downloadProgress,
    required this.downloadedEpisodes,
  });

  @override
  List<Object> get props => [downloadProgress, downloadedEpisodes];
}

class DownloadError extends DownloadState {
  final String message;

  const DownloadError(this.message);

  @override
  List<Object> get props => [message];
}

// BLoC
class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final EpisodeRepository episodeRepository;
  final Map<String, StreamSubscription<double>> _progressSubscriptions = {};

  DownloadBloc({required this.episodeRepository}) : super(DownloadInitial()) {
    on<StartDownloadEvent>(_onStartDownload);
    on<CancelDownloadEvent>(_onCancelDownload);
    on<DeleteDownloadEvent>(_onDeleteDownload);
    on<LoadDownloadsEvent>(_onLoadDownloads);
    on<UpdateDownloadProgressEvent>(_onUpdateDownloadProgress);
  }

  Future<void> _onStartDownload(
    StartDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // 開始下載
      await episodeRepository.downloadEpisode(event.episode);

      // 訂閱下載進度
      _progressSubscriptions[event.episode.id] = episodeRepository
          .getDownloadProgress(event.episode.id)
          .listen((progress) {
        add(UpdateDownloadProgressEvent(event.episode.id, progress));
      });

      // 更新狀態
      final downloadedEpisodes = await episodeRepository.getDownloadedEpisodes();
      final currentState = state;
      if (currentState is DownloadInProgress) {
        emit(DownloadInProgress(
          downloadProgress: {
            ...currentState.downloadProgress,
            event.episode.id: 0.0,
          },
          downloadedEpisodes: downloadedEpisodes,
        ));
      } else {
        emit(DownloadInProgress(
          downloadProgress: {event.episode.id: 0.0},
          downloadedEpisodes: downloadedEpisodes,
        ));
      }
    } catch (e) {
      emit(DownloadError(e.toString()));
    }
  }

  Future<void> _onCancelDownload(
    CancelDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // Cancel the download
      episodeRepository.cancelDownload(event.episodeId);

      // Cancel progress subscription
      await _progressSubscriptions[event.episodeId]?.cancel();
      _progressSubscriptions.remove(event.episodeId);

      // Update state
      final downloadedEpisodes = await episodeRepository.getDownloadedEpisodes();
      final currentState = state;
      if (currentState is DownloadInProgress) {
        final newProgress = Map<String, double>.from(currentState.downloadProgress);
        newProgress.remove(event.episodeId);
        emit(DownloadInProgress(
          downloadProgress: newProgress,
          downloadedEpisodes: downloadedEpisodes,
        ));
      }
    } catch (e) {
      emit(DownloadError(e.toString()));
    }
  }

  Future<void> _onDeleteDownload(
    DeleteDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      // 刪除下載
      await episodeRepository.deleteDownloadedEpisode(event.episodeId);

      // 更新狀態
      final downloadedEpisodes = await episodeRepository.getDownloadedEpisodes();
      final currentState = state;
      if (currentState is DownloadInProgress) {
        emit(DownloadInProgress(
          downloadProgress: currentState.downloadProgress,
          downloadedEpisodes: downloadedEpisodes,
        ));
      }
    } catch (e) {
      emit(DownloadError(e.toString()));
    }
  }

  Future<void> _onLoadDownloads(
    LoadDownloadsEvent event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final downloadedEpisodes = await episodeRepository.getDownloadedEpisodes();
      emit(DownloadInProgress(
        downloadProgress: {},
        downloadedEpisodes: downloadedEpisodes,
      ));
    } catch (e) {
      emit(DownloadError(e.toString()));
    }
  }

  void _onUpdateDownloadProgress(
    UpdateDownloadProgressEvent event,
    Emitter<DownloadState> emit,
  ) {
    final currentState = state;
    if (currentState is DownloadInProgress) {
      emit(DownloadInProgress(
        downloadProgress: {
          ...currentState.downloadProgress,
          event.episodeId: event.progress,
        },
        downloadedEpisodes: currentState.downloadedEpisodes,
      ));
    }
  }

  @override
  Future<void> close() {
    for (var subscription in _progressSubscriptions.values) {
      subscription.cancel();
    }
    _progressSubscriptions.clear();
    return super.close();
  }
} 