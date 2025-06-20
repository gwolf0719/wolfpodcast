import '../entities/podcast.dart';
import '../repositories/subscription_repository.dart';

class GetSubscribedPodcasts {
  final SubscriptionRepository repository;

  GetSubscribedPodcasts(this.repository);

  Future<List<Podcast>> call() async {
    return await repository.getSubscribedPodcasts();
  }
} 