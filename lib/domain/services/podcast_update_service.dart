import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../core/storage/hive_storage.dart';
import '../repositories/podcast_repository.dart';

class PodcastUpdateService {
  final PodcastRepository _podcastRepository;
  final HiveStorage _storage;
  final _updateController = BehaviorSubject<bool>();
  Timer? _updateTimer;

  PodcastUpdateService({
    required PodcastRepository podcastRepository,
    required HiveStorage storage,
  })  : _podcastRepository = podcastRepository,
        _storage = storage;

  Stream<bool> get updateStatusStream => _updateController.stream;

  Future<void> toggleAutoUpdate(bool enabled) async {
    await _storage.setAutoUpdateEnabled(enabled);
    _updateController.add(enabled);
    if (enabled) {
      await schedulePeriodicUpdate();
    } else {
      await cancelPeriodicUpdate();
    }
  }

  Future<bool> getAutoUpdateStatus() async {
    final enabled = await _storage.getAutoUpdateEnabled();
    _updateController.add(enabled);
    return enabled;
  }

  Future<void> schedulePeriodicUpdate() async {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _updatePodcasts();
    });
  }

  Future<void> cancelPeriodicUpdate() async {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _updatePodcasts() async {
    try {
      final podcasts = await _podcastRepository.getSubscribedPodcasts();
      for (final podcast in podcasts) {
        await _podcastRepository.refreshPodcast(podcast.id);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error updating podcasts: $e');
    }
  }

  void dispose() {
    _updateController.close();
    _updateTimer?.cancel();
  }
} 