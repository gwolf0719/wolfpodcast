import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import '../../data/datasources/download_manager.dart';
import '../../data/datasources/local/episode_local_datasource.dart';
import '../../data/datasources/remote/episode_remote_datasource.dart';
import '../../data/repositories/episode_repository_impl.dart';
import '../../domain/repositories/episode_repository.dart';
import '../storage/hive_storage.dart';

void initEpisodeModule(GetIt getIt) {
  // DataSources
  getIt.registerLazySingleton<EpisodeLocalDataSource>(
    () => EpisodeLocalDataSourceImpl(getIt<HiveStorage>().episodeBox as Box<Map>),
  );

  getIt.registerLazySingleton<EpisodeRemoteDataSource>(
    () => EpisodeRemoteDataSourceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<DownloadManager>(
    () => DownloadManager(dio: getIt<Dio>()),
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