import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../repositories/podcast_repository.dart';
import '../repositories/subscription_repository.dart';
import '../../domain/entities/podcast.dart';

const podcastUpdateTask = 'podcast_update_task';

class PodcastUpdateService {
  final PodcastRepository _podcastRepository;
  final SubscriptionRepository _subscriptionRepository;
  
  PodcastUpdateService(this._podcastRepository, this._subscriptionRepository);

  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> schedulePeriodicUpdate() async {
    await Workmanager().registerPeriodicTask(
      podcastUpdateTask,
      podcastUpdateTask,
      frequency: const Duration(hours: 6),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  Future<void> cancelPeriodicUpdate() async {
    await Workmanager().cancelByUniqueName(podcastUpdateTask);
  }

  static Future<void> checkForUpdates(
    PodcastRepository podcastRepository,
    SubscriptionRepository subscriptionRepository,
  ) async {
    final subscriptions = await subscriptionRepository.getSubscribedPodcasts();
    
    for (final podcast in subscriptions) {
      try {
        final updatedPodcast = await podcastRepository.refreshPodcast(podcast.id);
        if (updatedPodcast != null && 
            updatedPodcast.lastUpdate.isAfter(podcast.lastUpdate)) {
          // 有新的更新，發送通知
          await _sendUpdateNotification(updatedPodcast);
        }
      } catch (e) {
        print('更新播客失敗：${podcast.title} - $e');
      }
    }
  }

  static Future<void> _sendUpdateNotification(Podcast podcast) async {
    // TODO: 實現通知功能
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case podcastUpdateTask:
        // 在這裡實現實際的更新邏輯
        return true;
      default:
        return false;
    }
  });
} 