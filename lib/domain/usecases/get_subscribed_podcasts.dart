import '../entities/podcast.dart';
import '../repositories/podcast_repository.dart';

class GetSubscribedPodcasts {
  final PodcastRepository repository;

  GetSubscribedPodcasts(this.repository);

  Future<List<Podcast>> call() async {
    return await repository.getSubscribedPodcasts();
  }
} 