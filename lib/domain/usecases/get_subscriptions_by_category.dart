import '../entities/podcast.dart';
import '../repositories/subscription_repository.dart';

class GetSubscriptionsByCategory {
  final SubscriptionRepository repository;

  GetSubscriptionsByCategory(this.repository);

  Future<List<Podcast>> call(String category) async {
    return await repository.getSubscriptionsByCategory(category);
  }
} 