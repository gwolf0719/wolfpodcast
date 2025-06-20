import '../entities/episode.dart';
import '../repositories/episode_repository.dart';

class GetEpisodes {
  final EpisodeRepository repository;

  GetEpisodes(this.repository);

  Future<List<Episode>> call(String podcastId) async {
    return await repository.getEpisodesByPodcastId(podcastId);
  }
} 