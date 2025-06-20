import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Core
import '../core/database/database_helper.dart';
import '../core/storage/hive_storage.dart';
import '../core/constants/app_constants.dart';

// Models & Adapters
import '../data/models/podcast_model.dart';
import '../data/models/episode_model.dart';

// Data Sources
import '../data/datasources/audio_player_service.dart';
import '../data/datasources/podcast_search_service.dart';
import '../data/datasources/local/podcast_local_datasource.dart';
import '../data/datasources/local/episode_local_datasource.dart';
import '../data/datasources/remote/podcast_remote_datasource.dart';
import '../data/datasources/remote/episode_remote_datasource.dart';
import '../data/datasources/download_manager.dart';
import '../domain/services/podcast_update_service.dart' as domain_update_service;
import '../data/datasources/podcast_update_service.dart' as data_update_service;

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
  // Core & External Dependencies
  // =======================================
  
  // Hive Storage Wrapper - 統一管理 Hive 初始化
  getIt.registerLazySingleton<HiveStorage>(() => HiveStorage.instance);
  await getIt<HiveStorage>().init(); // 初始化 HiveStorage，它會處理所有的 Hive 設定和 Adapter 註冊
  
  // 從 HiveStorage 獲取已經開啟的 Boxes
  final settingsBox = Hive.box(AppConstants.settingsBox);
  final playlistsBox = Hive.box(AppConstants.playlistsBox);
  final episodesBox = Hive.box(AppConstants.episodesBox);
  
  getIt.registerLazySingleton<Box<dynamic>>(() => settingsBox, instanceName: AppConstants.settingsBox);
  getIt.registerLazySingleton<Box<dynamic>>(() => playlistsBox, instanceName: AppConstants.playlistsBox);
  getIt.registerLazySingleton<Box<dynamic>>(() => episodesBox, instanceName: AppConstants.episodesBox);
  
  // Database (SQLite)
  final database = await DatabaseHelper.instance.database;
  getIt.registerLazySingleton<Database>(() => database);
  
  // HTTP Clients
  getIt.registerLazySingleton(() => http.Client());
  final dio = Dio(BaseOptions(
    connectTimeout: AppConstants.networkTimeout,
    receiveTimeout: AppConstants.networkTimeout,
  ));
  getIt.registerLazySingleton<Dio>(() => dio);
  
  // =======================================
  // Data Sources
  // =======================================
  
  getIt.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService.instance);
  getIt.registerLazySingleton<PodcastSearchService>(() => PodcastSearchService.instance);
  getIt.registerLazySingleton<DownloadManager>(() => DownloadManager(dio: getIt()));
  
  // Local Data Sources
  getIt.registerLazySingleton<PodcastLocalDataSource>(() => PodcastLocalDataSourceImpl(getIt(), getIt()));
  getIt.registerLazySingleton<EpisodeLocalDataSource>(
      () => EpisodeLocalDataSourceImpl(getIt<Box<dynamic>>(instanceName: AppConstants.episodesBox)));

  // Remote Data Sources
  getIt.registerLazySingleton<PodcastRemoteDataSource>(() => PodcastRemoteDataSourceImpl(getIt()));
  getIt.registerLazySingleton<EpisodeRemoteDataSource>(() => EpisodeRemoteDataSourceImpl(getIt()));
  
  // Update Service
  getIt.registerLazySingleton<data_update_service.PodcastUpdateService>(
    () => data_update_service.PodcastUpdateService(getIt(), getIt()),
  );
  
  // =======================================
  // Repositories
  // =======================================
  
  getIt.registerLazySingleton<PodcastRepository>(
    () => PodcastRepositoryImpl(localDataSource: getIt(), remoteDataSource: getIt(), storage: getIt()),
  );
  
  getIt.registerLazySingleton<EpisodeRepository>(
    () => EpisodeRepositoryImpl(getIt(), getIt(), getIt(), getIt()),
  );
  
  getIt.registerLazySingleton<PlayerRepository>(
    () => PlayerRepositoryImpl(audioPlayerService: getIt(), hiveStorage: getIt()),
  );
  
  getIt.registerLazySingleton<SubscriptionRepository>(() {
    final repo = SubscriptionRepositoryImpl(getIt());
    repo.initialize(); // 確保初始化
    return repo;
  });
  
  // =======================================
  // Services
  // =======================================
  
  // 檢查是否有 domain 層的 PodcastUpdateService
  try {
    getIt.registerLazySingleton<domain_update_service.PodcastUpdateService>(
        () => domain_update_service.PodcastUpdateService(podcastRepository: getIt(), storage: getIt()));
  } catch (e) {
    // 如果 domain 層的服務不存在，使用 data 層的
    print('使用 data 層的 PodcastUpdateService');
  }

  // =======================================
  // Use Cases
  // =======================================
  
  getIt.registerLazySingleton(() => SearchPodcasts(getIt()));
  getIt.registerLazySingleton(() => SubscribeToPodcast(getIt()));
  getIt.registerLazySingleton(() => GetSubscribedPodcasts(getIt<SubscriptionRepository>()));
  getIt.registerLazySingleton(() => GetPopularPodcasts(getIt()));
  getIt.registerLazySingleton(() => GetSubscriptionCategories(getIt()));
  getIt.registerLazySingleton(() => GetSubscriptionsByCategory(getIt()));
  getIt.registerLazySingleton(() => GetAutoUpdateEnabled(getIt()));
  getIt.registerLazySingleton(() => SetAutoUpdate(getIt()));
  getIt.registerLazySingleton(() => UpdatePodcastCategories(getIt()));
  getIt.registerLazySingleton(() => GetEpisodes(getIt()));
  getIt.registerLazySingleton(() => PlayEpisode(getIt()));
  getIt.registerLazySingleton(() => PausePlayback(getIt()));
  getIt.registerLazySingleton(() => SeekToPosition(getIt()));
  
  // =======================================
  // BLoCs
  // =======================================
  
  getIt.registerFactory(() => SearchBloc(getPopularPodcasts: getIt(), searchPodcasts: getIt()));
  
  getIt.registerFactory(() => SubscriptionBloc(
        getSubscribedPodcasts: getIt(),
        getSubscriptionCategories: getIt(),
        getSubscriptionsByCategory: getIt(),
        updatePodcastCategories: getIt(),
        getAutoUpdateEnabled: getIt(),
        setAutoUpdate: getIt(),
        updateService: getIt(),
      ));
      
  getIt.registerFactory(() => PlayerBloc(playerRepository: getIt(), episodeRepository: getIt()));
  getIt.registerFactory(() => DownloadBloc(episodeRepository: getIt()));
}

Future<void> dispose() async {
  await DatabaseHelper.instance.close();
  await getIt<AudioPlayerService>().dispose();
  await getIt<DownloadManager>().dispose();
  await getIt.reset();
} 