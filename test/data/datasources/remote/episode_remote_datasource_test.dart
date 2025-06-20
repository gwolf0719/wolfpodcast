import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:wolfpodcast/data/datasources/remote/episode_remote_datasource.dart';

import 'episode_remote_datasource_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late EpisodeRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = EpisodeRemoteDataSource(mockDio);
  });

  final testPodcastId = 'test_podcast_id';
  final testEpisodeId = 'test_episode_id';

  final testEpisodeJson = {
    'id': 'test_episode_id',
    'title': 'Test Episode',
    'description': 'Test Description',
    'publishDate': '2024-01-01T00:00:00.000Z',
    'duration': 1800,
    'audioUrl': 'https://test.com/audio.mp3',
    'podcastId': 'test_podcast_id',
    'imageUrl': 'https://test.com/image.jpg',
  };

  group('getEpisodesByPodcastId', () {
    test('should return list of episodes when request is successful', () async {
      when(mockDio.get('/podcasts/$testPodcastId/episodes')).thenAnswer(
        (_) async => Response(
          data: {
            'episodes': [testEpisodeJson],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.getEpisodesByPodcastId(testPodcastId);

      expect(result, isNotEmpty);
      expect(result.first.id, testEpisodeJson['id']);
      expect(result.first.title, testEpisodeJson['title']);
    });

    test('should throw exception when request fails', () async {
      when(mockDio.get('/podcasts/$testPodcastId/episodes')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Network error',
        ),
      );

      expect(
        () => dataSource.getEpisodesByPodcastId(testPodcastId),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('getEpisodeById', () {
    test('should return episode when request is successful', () async {
      when(mockDio.get('/episodes/$testEpisodeId')).thenAnswer(
        (_) async => Response(
          data: testEpisodeJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.getEpisodeById(testEpisodeId);

      expect(result, isNotNull);
      expect(result!.id, testEpisodeJson['id']);
      expect(result.title, testEpisodeJson['title']);
    });

    test('should throw exception when request fails', () async {
      when(mockDio.get('/episodes/$testEpisodeId')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'Network error',
        ),
      );

      expect(
        () => dataSource.getEpisodeById(testEpisodeId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle null values in response', () async {
      final incompleteJson = Map<String, dynamic>.from(testEpisodeJson);
      incompleteJson['description'] = null;
      incompleteJson['imageUrl'] = null;
      incompleteJson['duration'] = null;

      when(mockDio.get('/episodes/$testEpisodeId')).thenAnswer(
        (_) async => Response(
          data: incompleteJson,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ),
      );

      final result = await dataSource.getEpisodeById(testEpisodeId);

      expect(result, isNotNull);
      expect(result!.description, isEmpty);
      expect(result.imageUrl, isEmpty);
      expect(result.duration, const Duration());
    });
  });
} 