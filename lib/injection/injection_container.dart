import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/storage/hive_storage.dart';

// Data Sources
import '../data/datasources/audio_player_service.dart';
import '../data/datasources/podcast_search_service.dart';
import '../data/datasources/local/podcast_local_datasource.dart';
import '../data/datasources/local/episode_local_datasource.dart';
import '../data/datasources/remote/podcast_remote_datasource.dart';
import '../data/datasources/remote/episode_remote_datasource.dart';
import '../data/datasources/download_manager.dart';
import '../data/datasources/podcast_update_service.dart';

// Repositories
import '../data/repositories/subscription_repository.dart';
import '../data/repositories/podcast_repository_impl.dart';
import '../data/repositories/episode_repository_impl.dart';
import '../data/repositories/player_repository_impl.dart';

// Domain Repositories
import '../domain/repositories/podcast_repository.dart';
import '../domain/repositories/episode_repository.dart';
import '../domain/repositories/player_repository.dart';
import '../domain/repositories/subscription_repository.dart';

// Use Cases
import '../domain/usecases/search_podcasts.dart';
import '../domain/usecases/subscribe_to_podcast.dart';
import '../domain/usecases/get_subscribed_podcasts.dart';
import '../domain/usecases/get_episodes.dart';
import '../domain/usecases/play_episode.dart';
import '../domain/usecases/pause_playback.dart';
import '../domain/usecases/seek_to_position.dart';
import '../domain/usecases/get_popular_podcasts.dart';
import '../domain/usecases/get_subscription_categories.dart';
import '../domain/usecases/get_subscriptions_by_category.dart';
import '../domain/usecases/get_auto_update_enabled.dart';
import '../domain/usecases/set_auto_update.dart';
import '../domain/usecases/update_podcast_categories.dart';

// BLoCs
import '../presentation/bloc/search/search_bloc.dart';
import '../presentation/bloc/subscription/subscription_bloc.dart';
import '../presentation/bloc/player/player_bloc.dart';
import '../presentation/bloc/download/download_bloc.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // =======================================
  // Core
  // =======================================
  
  // Database
  final database = await DatabaseHelper.instance.database;
  getIt.registerLazySingleton<Database>(() => database);
  
  // Hive Storage
  final hiveStorage = HiveStorage.instance;
  await hiveStorage.init();
  getIt.registerLazySingleton<HiveStorage>(() => hiveStorage);
  
  // HTTP Client
  getIt.registerLazySingleton(() => http.Client());
  
  // Dio Client
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 30);
  dio.options.receiveTimeout = const Duration(seconds: 30);
  getIt.registerLazySingleton<Dio>(() => dio);
  
  // =======================================
  // Data Sources
  // =======================================
  
  // Audio Player Service
  getIt.registerLazySingleton<AudioPlayerService>(
    () => AudioPlayerService.instance,
  );
  
  // Podcast Search Service
  getIt.registerLazySingleton<PodcastSearchService>(
    () => PodcastSearchService.instance,
  );
  
  // Download Manager
  getIt.registerLazySingleton<DownloadManager>(
    () => DownloadManager(dio: getIt()),
  );
  
  // Podcast Update Service
  getIt.registerLazySingleton<PodcastUpdateService>(
    () => PodcastUpdateService(getIt(), getIt()),
  );
  
  // Local Data Sources
  getIt.registerLazySingleton<PodcastLocalDataSource>(
    () => PodcastLocalDataSourceImpl(getIt(), getIt()),
  );
  
  getIt.registerLazySingleton<EpisodeLocalDataSource>(
    () => EpisodeLocalDataSourceImpl(getIt()),
  );
  
  // Remote Data Sources
  getIt.registerLazySingleton<PodcastRemoteDataSource>(
    () => PodcastRemoteDataSourceImpl(getIt()),
  );

  getIt.registerLazySingleton<EpisodeRemoteDataSource>(
    () => EpisodeRemoteDataSourceImpl(getIt()),
  );
  
  // =======================================
  // Repositories
  // =======================================
  
  getIt.registerLazySingleton<PodcastRepository>(
    () => PodcastRepositoryImpl(
      localDataSource: getIt(),
      remoteDataSource: getIt(),
      storage: getIt(),
    ),
  );
  
  getIt.registerLazySingleton<EpisodeRepository>(
    () => EpisodeRepositoryImpl(
      getIt<EpisodeLocalDataSource>(),
      getIt<EpisodeRemoteDataSource>(),
      getIt<DownloadManager>(),
      getIt<HiveStorage>(),
    ),
  );
  
  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(
      audioPlayerService: getIt(),
      hiveStorage: getIt(),
    ),
  );
  
  // Subscription Repository
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(getIt()),
  );
  
  // =======================================
  // Use Cases
  // =======================================
  
  // Podcast Use Cases
  getIt.registerLazySingleton(() => SearchPodcasts(getIt()));
  getIt.registerLazySingleton(() => SubscribeToPodcast(getIt()));
  getIt.registerLazySingleton(() => GetSubscribedPodcasts(getIt()));
  getIt.registerLazySingleton(() => GetPopularPodcasts(getIt()));
  getIt.registerLazySingleton(() => GetSubscriptionCategories(getIt()));
  getIt.registerLazySingleton(() => GetSubscriptionsByCategory(getIt()));
  getIt.registerLazySingleton(() => GetAutoUpdateEnabled(getIt()));
  getIt.registerLazySingleton(() => SetAutoUpdate(getIt()));
  getIt.registerLazySingleton(() => UpdatePodcastCategories(getIt()));
  
  // Episode Use Cases
  getIt.registerLazySingleton(() => GetEpisodes(getIt()));
  
  // Player Use Cases
  getIt.registerLazySingleton(() => PlayEpisode(getIt()));
  getIt.registerLazySingleton(() => PausePlayback(getIt()));
  getIt.registerLazySingleton(() => SeekToPosition(getIt()));
  
  // =======================================
  // BLoCs
  // =======================================
  
  // Search BLoC
  getIt.registerFactory(
    () => SearchBloc(
      getPopularPodcasts: getIt(),
      searchPodcasts: getIt(),
    ),
  );
  
  // Subscription BLoC
  getIt.registerFactory(
    () => SubscriptionBloc(
      getSubscriptionCategories: getIt(),
      getSubscriptionsByCategory: getIt(),
      updatePodcastCategories: getIt(),
      getAutoUpdateEnabled: getIt(),
      setAutoUpdate: getIt(),
      updateService: getIt(),
    ),
  );
  
  // Player BLoC
  getIt.registerFactory(
    () => PlayerBloc(
      playerRepository: getIt(),
      episodeRepository: getIt(),
    ),
  );

  // Download BLoC
  getIt.registerFactory(
    () => DownloadBloc(episodeRepository: getIt()),
  );

  // External
  final episodeBox = await Hive.openBox<Map>('episodes');
  getIt.registerLazySingleton(() => episodeBox);
}

/// 清理所有注册的依赖项
Future<void> dispose() async {
  // 关闭数据库连接
  await DatabaseHelper.instance.close();
  
  // 释放音频播放器资源
  await getIt<AudioPlayerService>().dispose();
  
  // 释放下载管理器资源
  await getIt<DownloadManager>().dispose();
  
  // 重置 GetIt
  await getIt.reset();
} 