import 'dart:async';
// import 'package:workmanager/workmanager.dart'; // 暫時移除
import '../../domain/repositories/podcast_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/podcast.dart';

const podcastUpdateTask = 'podcast_update_task';

/// 背景更新服務，負責處理播客的背景更新和通知
/// 與 domain 層的 PodcastUpdateService 不同，這個專門處理背景任務
class PodcastBackgroundUpdateService {
  // ignore: unused_field
  final PodcastRepository _podcastRepository;
  // ignore: unused_field
  final SubscriptionRepository _subscriptionRepository;
  
  PodcastBackgroundUpdateService(this._podcastRepository, this._subscriptionRepository);

  Future<void> initialize() async {
    // 暫時移除 Workmanager 初始化
    // await Workmanager().initialize(
    //   callbackDispatcher,
    //   isInDebugMode: false,
    // );
    print('PodcastBackgroundUpdateService 初始化完成（Workmanager 暫時停用）');
  }

  Future<void> schedulePeriodicUpdate() async {
    // 暫時移除 Workmanager 週期性任務
    // await Workmanager().registerPeriodicTask(
    //   podcastUpdateTask,
    //   podcastUpdateTask,
    //   frequency: const Duration(hours: 6),
    //   constraints: Constraints(
    //     networkType: NetworkType.connected,
    //     requiresBatteryNotLow: true,
    //   ),
    // );
    print('週期性更新已排程（Workmanager 暫時停用）');
  }

  Future<void> cancelPeriodicUpdate() async {
    // 暫時移除 Workmanager 取消任務
    // await Workmanager().cancelByUniqueName(podcastUpdateTask);
    print('週期性更新已取消（Workmanager 暫時停用）');
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
        // ignore: avoid_print
        print('更新播客失敗：${podcast.title} - $e');
      }
    }
  }

  static Future<void> _sendUpdateNotification(Podcast podcast) async {
    // TODO: 實現通知功能
    print('播客有新更新：${podcast.title}');
  }
}

// 暫時註解掉 Workmanager 回調
// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     switch (task) {
//       case podcastUpdateTask:
//         // 在這裡實現實際的更新邏輯
//         return true;
//       default:
//         return false;
//     }
//   });
// } 