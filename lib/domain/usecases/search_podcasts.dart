import '../entities/podcast.dart';
import '../repositories/podcast_repository.dart';

class SearchPodcasts {
  final PodcastRepository repository;

  SearchPodcasts(this.repository);

  Future<List<Podcast>> call(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return await repository.searchPodcasts(query);
  }
} 