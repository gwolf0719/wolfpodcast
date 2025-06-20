import 'package:equatable/equatable.dart';
import '../entities/podcast.dart';
import '../repositories/podcast_repository.dart';

class GetPopularPodcastsParams extends Equatable {
  final int limit;
  final String? category;

  const GetPopularPodcastsParams({
    this.limit = 20,
    this.category,
  });

  @override
  List<Object?> get props => [limit, category];
}

class GetPopularPodcasts {
  final PodcastRepository _repository;

  GetPopularPodcasts(this._repository);

  Future<List<Podcast>> call(GetPopularPodcastsParams params) async {
    return await _repository.getPopularPodcasts(
      limit: params.limit,
      category: params.category,
    );
  }
} 