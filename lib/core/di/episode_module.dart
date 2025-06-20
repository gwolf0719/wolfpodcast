import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/download_manager.dart';
import '../../data/datasources/local/episode_local_datasource.dart';
import '../../data/datasources/remote/episode_remote_datasource.dart';
import '../../data/repositories/episode_repository_impl.dart';
import '../../domain/repositories/episode_repository.dart';
import '../storage/hive_storage.dart';

void initEpisodeModule(GetIt getIt) {
  // DataSources
  getIt.registerLazySingleton<EpisodeLocalDataSource>(
    () => EpisodeLocalDataSource(getIt<HiveStorage>()),
  );

  getIt.registerLazySingleton<EpisodeRemoteDataSource>(
    () => EpisodeRemoteDataSource(getIt<Dio>()),
  );

  getIt.registerLazySingleton<DownloadManager>(
    () => DownloadManager(getIt<Dio>()),
  );

  // Repository
  getIt.registerLazySingleton<EpisodeRepository>(
    () => EpisodeRepositoryImpl(
      getIt<EpisodeLocalDataSource>(),
      getIt<EpisodeRemoteDataSource>(),
      getIt<DownloadManager>(),
      getIt<HiveStorage>(),
    ),
  );
} 