import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive/hive.dart';
import '../../../lib/core/storage/hive_storage.dart';
import '../../../lib/data/datasources/download_manager.dart';
import '../../../lib/data/datasources/local/episode_local_datasource.dart';
import '../../../lib/data/datasources/remote/episode_remote_datasource.dart';
import '../../../lib/data/repositories/episode_repository_impl.dart';
import '../../../lib/domain/entities/episode.dart';

import 'episode_repository_impl_test.mocks.dart';

@GenerateMocks([
  EpisodeLocalDataSource,
  EpisodeRemoteDataSource,
  DownloadManager,
  HiveStorage,
  Box,
])
void main() {
  late EpisodeRepositoryImpl repository;
  late MockEpisodeLocalDataSource mockLocalDataSource;
  late MockEpisodeRemoteDataSource mockRemoteDataSource;
  late MockDownloadManager mockDownloadManager;
  late MockHiveStorage mockHiveStorage;
  late MockBox mockBox;

  setUp(() {
    mockLocalDataSource = MockEpisodeLocalDataSource();
    mockRemoteDataSource = MockEpisodeRemoteDataSource();
    mockDownloadManager = MockDownloadManager();
    mockHiveStorage = MockHiveStorage();
    mockBox = MockBox();
    repository = EpisodeRepositoryImpl(
      mockLocalDataSource,
      mockRemoteDataSource,
      mockDownloadManager,
      mockHiveStorage,
    );
  });

  final testEpisode = Episode(
    id: 'test_id',
    title: 'Test Episode',
    description: 'Test Description',
    publishDate: DateTime(2024, 1, 1),
    duration: const Duration(minutes: 30),
    audioUrl: 'https://test.com/audio.mp3',
    podcastId: 'test_podcast_id',
    imageUrl: 'https://test.com/image.jpg',
    isPlayed: false,
    position: null,
  );

  group('getEpisodesByPodcastId', () {
    test('should return local episodes when available', () async {
      when(mockLocalDataSource.getEpisodesByPodcastId(any))
          .thenAnswer((_) async => [testEpisode]);

      final result = await repository.getEpisodesByPodcastId('test_podcast_id');

      expect(result, [testEpisode]);
      verifyNever(mockRemoteDataSource.getEpisodesByPodcastId(any));
    });

    test('should fetch from remote when local is empty', () async {
      when(mockLocalDataSource.getEpisodesByPodcastId(any))
          .thenAnswer((_) async => []);
      when(mockRemoteDataSource.getEpisodesByPodcastId(any))
          .thenAnswer((_) async => [testEpisode]);

      final result = await repository.getEpisodesByPodcastId('test_podcast_id');

      expect(result, [testEpisode]);
      verify(mockLocalDataSource.saveEpisode(testEpisode)).called(1);
    });
  });

  group('getEpisodeById', () {
    test('should return local episode when available', () async {
      when(mockLocalDataSource.getEpisode(any))
          .thenAnswer((_) async => testEpisode);

      final result = await repository.getEpisodeById('test_id');

      expect(result, testEpisode);
      verifyNever(mockRemoteDataSource.getEpisodeById(any));
    });

    test('should fetch from remote when local is null', () async {
      when(mockLocalDataSource.getEpisode(any))
          .thenAnswer((_) async => null);
      when(mockRemoteDataSource.getEpisodeById(any))
          .thenAnswer((_) async => testEpisode);

      final result = await repository.getEpisodeById('test_id');

      expect(result, testEpisode);
      verify(mockLocalDataSource.saveEpisode(testEpisode)).called(1);
    });
  });

  group('downloadEpisode', () {
    test('should download episode and save path', () async {
      when(mockLocalDataSource.getEpisode(any))
          .thenAnswer((_) async => testEpisode);
      when(mockDownloadManager.downloadEpisode(any))
          .thenAnswer((_) async => '/test/path/audio.mp3');
      when(mockHiveStorage.openBox('downloads'))
          .thenAnswer((_) async => mockBox);
      when(mockBox.put(any, any))
          .thenAnswer((_) async => {});

      await repository.downloadEpisode('test_id');

      verify(mockDownloadManager.downloadEpisode(testEpisode)).called(1);
      verify(mockBox.put('test_id', any)).called(1);
    });

    test('should throw when episode not found', () async {
      when(mockLocalDataSource.getEpisode(any))
          .thenAnswer((_) async => null);
      when(mockRemoteDataSource.getEpisodeById(any))
          .thenAnswer((_) async => null);

      expect(
        () => repository.downloadEpisode('test_id'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('deleteDownloadedEpisode', () {
    test('should delete file and remove from downloads', () async {
      when(mockHiveStorage.openBox('downloads'))
          .thenAnswer((_) async => mockBox);
      when(mockBox.get('test_id'))
          .thenReturn({'path': '/test/path/audio.mp3'});

      await repository.deleteDownloadedEpisode('test_id');

      verify(mockDownloadManager.deleteDownloadedFile('/test/path/audio.mp3')).called(1);
      verify(mockBox.delete('test_id')).called(1);
    });
  });

  group('getDownloadProgress', () {
    test('should return download progress stream', () async {
      final progress = Stream.fromIterable([
        DownloadProgress(episodeId: 'test_id', progress: 0.5),
        DownloadProgress(episodeId: 'test_id', progress: 1.0),
      ]);

      when(mockDownloadManager.downloadProgress).thenAnswer((_) => progress);

      final result = repository.getDownloadProgress('test_id');
      expect(await result.toList(), [0.5, 1.0]);
    });
  });

  group('getDownloadedEpisodes', () {
    test('should return list of downloaded episodes', () async {
      when(mockHiveStorage.openBox('downloads'))
          .thenAnswer((_) async => mockBox);
      when(mockBox.keys).thenReturn(['test_id']);
      when(mockLocalDataSource.getEpisode('test_id'))
          .thenAnswer((_) async => testEpisode);

      final result = await repository.getDownloadedEpisodes();

      expect(result, [testEpisode]);
    });
  });

  group('isEpisodeDownloaded', () {
    test('should return true when episode is downloaded', () async {
      when(mockHiveStorage.openBox('downloads'))
          .thenAnswer((_) async => mockBox);
      when(mockBox.containsKey('test_id')).thenReturn(true);

      final result = await repository.isEpisodeDownloaded('test_id');

      expect(result, isTrue);
    });

    test('should return false when episode is not downloaded', () async {
      when(mockHiveStorage.openBox('downloads'))
          .thenAnswer((_) async => mockBox);
      when(mockBox.containsKey('test_id')).thenReturn(false);

      final result = await repository.isEpisodeDownloaded('test_id');

      expect(result, isFalse);
    });
  });
} 