import '../entities/podcast.dart';
import '../repositories/podcast_repository.dart';

class SubscribeToPodcast {
  final PodcastRepository repository;

  SubscribeToPodcast(this.repository);

  Future<void> call(Podcast podcast) async {
    await repository.subscribeToPodcast(podcast);
  }
} 