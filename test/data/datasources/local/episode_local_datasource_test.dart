import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive/hive.dart';
import 'package:wolfpodcast/core/storage/hive_storage.dart';
import 'package:wolfpodcast/data/datasources/local/episode_local_datasource.dart';
import 'package:wolfpodcast/domain/entities/episode.dart';

import 'episode_local_datasource_test.mocks.dart';

@GenerateMocks([HiveStorage, Box])
void main() {
  late EpisodeLocalDataSource dataSource;
  late MockHiveStorage mockHiveStorage;
  late MockBox mockBox;

  setUp(() {
    mockHiveStorage = MockHiveStorage();
    mockBox = MockBox();
    dataSource = EpisodeLocalDataSource(mockHiveStorage);
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

  final testEpisodeMap = {
    'id': 'test_id',
    'title': 'Test Episode',
    'description': 'Test Description',
    'publishDate': '2024-01-01T00:00:00.000',
    'duration': 1800,
    'audioUrl': 'https://test.com/audio.mp3',
    'podcastId': 'test_podcast_id',
    'imageUrl': 'https://test.com/image.jpg',
    'isPlayed': false,
    'position': 0,
  };

  group('saveEpisode', () {
    test('should save episode to Hive box', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      await dataSource.saveEpisode(testEpisode);

      verify(mockHiveStorage.openBox('episodes')).called(1);
      verify(mockBox.put(testEpisode.id, testEpisodeMap)).called(1);
    });
  });

  group('getEpisode', () {
    test('should return Episode when it exists in box', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.get('test_id')).thenReturn(testEpisodeMap);

      final result = await dataSource.getEpisode('test_id');

      expect(result, isNotNull);
      expect(result!.id, testEpisode.id);
      expect(result.title, testEpisode.title);
      expect(result.publishDate, testEpisode.publishDate);
    });

    test('should return null when episode does not exist', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.get('test_id')).thenReturn(null);

      final result = await dataSource.getEpisode('test_id');

      expect(result, isNull);
    });
  });

  group('getEpisodesByPodcastId', () {
    test('should return list of episodes for podcast', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.keys).thenReturn(['test_id']);
      when(mockBox.get('test_id')).thenReturn(testEpisodeMap);

      final result = await dataSource.getEpisodesByPodcastId('test_podcast_id');

      expect(result, isNotEmpty);
      expect(result.first.id, testEpisode.id);
      expect(result.first.podcastId, testEpisode.podcastId);
    });

    test('should return empty list when no episodes found', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.keys).thenReturn([]);

      final result = await dataSource.getEpisodesByPodcastId('test_podcast_id');

      expect(result, isEmpty);
    });
  });

  group('markAsPlayed', () {
    test('should update isPlayed status', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.get('test_id')).thenReturn(testEpisodeMap);
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      await dataSource.markAsPlayed('test_id');

      final expectedMap = Map<String, dynamic>.from(testEpisodeMap);
      expectedMap['isPlayed'] = true;
      verify(mockBox.put('test_id', expectedMap)).called(1);
    });
  });

  group('setPosition', () {
    test('should update position', () async {
      when(mockHiveStorage.openBox('episodes')).thenAnswer((_) async => mockBox);
      when(mockBox.get('test_id')).thenReturn(testEpisodeMap);
      when(mockBox.put(any, any)).thenAnswer((_) async => {});

      const testPosition = Duration(seconds: 120);
      await dataSource.setPosition('test_id', testPosition);

      final expectedMap = Map<String, dynamic>.from(testEpisodeMap);
      expectedMap['position'] = testPosition.inSeconds;
      verify(mockBox.put('test_id', expectedMap)).called(1);
    });
  });
} 