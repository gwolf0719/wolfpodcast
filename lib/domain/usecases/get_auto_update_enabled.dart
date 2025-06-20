import '../repositories/podcast_repository.dart';

class GetAutoUpdateEnabled {
  final PodcastRepository _repository;

  GetAutoUpdateEnabled(this._repository);

  Future<bool> call() async {
    return await _repository.getAutoUpdateEnabled();
  }
} 