import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path_provider/path_provider.dart';
import '../../../lib/data/datasources/download_manager.dart';
import '../../../lib/domain/entities/episode.dart';

import 'download_manager_test.mocks.dart';

@GenerateMocks([Dio, Directory])
void main() {
  late DownloadManager downloadManager;
  late MockDio mockDio;
  late Directory tempDir;

  setUp(() async {
    mockDio = MockDio();
    downloadManager = DownloadManager(mockDio);
    tempDir = await Directory.systemTemp.createTemp();

    // Mock path_provider
    getApplicationDocumentsDirectory = () async => tempDir;
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
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

  group('downloadEpisode', () {
    test('should download episode and return file path', () async {
      when(mockDio.download(
        any,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) async => Response(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: ''),
      ));

      final result = await downloadManager.downloadEpisode(testEpisode);

      expect(result, isNotNull);
      expect(result, contains(testEpisode.id));
      expect(result, endsWith('.mp3'));

      verify(mockDio.download(
        testEpisode.audioUrl,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).called(1);
    });

    test('should emit download progress', () async {
      final progressValues = <double>[];
      downloadManager.downloadProgress.listen((event) {
        if (event.episodeId == testEpisode.id) {
          progressValues.add(event.progress);
        }
      });

      when(mockDio.download(
        any,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((invocation) async {
        final onProgress = invocation.namedArguments[#onReceiveProgress] as void Function(int, int);
        onProgress(50, 100); // 50% progress
        onProgress(100, 100); // 100% progress
        return Response(
          data: null,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );
      });

      await downloadManager.downloadEpisode(testEpisode);

      expect(progressValues, [0.5, 1.0]);
    });

    test('should throw exception when download fails', () async {
      when(mockDio.download(
        any,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'Download failed',
      ));

      expect(
        () => downloadManager.downloadEpisode(testEpisode),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('cancelDownload', () {
    test('should cancel ongoing download', () async {
      // Start a download that never completes
      when(mockDio.download(
        any,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) => Future.delayed(const Duration(days: 1)));

      // Start download in background
      downloadManager.downloadEpisode(testEpisode);

      // Wait a bit to ensure download has started
      await Future.delayed(const Duration(milliseconds: 100));

      // Cancel the download
      downloadManager.cancelDownload(testEpisode.id);

      // Verify the download was cancelled
      verify(mockDio.download(
        testEpisode.audioUrl,
        any,
        cancelToken: anyNamed('cancelToken'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).called(1);
    });
  });

  group('deleteDownloadedFile', () {
    test('should delete file if it exists', () async {
      // Create a test file
      final file = File('${tempDir.path}/test.mp3');
      await file.writeAsString('test content');

      await downloadManager.deleteDownloadedFile(file.path);

      expect(await file.exists(), isFalse);
    });

    test('should not throw if file does not exist', () async {
      final nonExistentPath = '${tempDir.path}/non_existent.mp3';

      expect(
        () => downloadManager.deleteDownloadedFile(nonExistentPath),
        returnsNormally,
      );
    });
  });
} 