import 'package:equatable/equatable.dart';
import '../repositories/subscription_repository.dart';

class UpdatePodcastCategoriesParams extends Equatable {
  final String podcastId;
  final List<String> categories;

  const UpdatePodcastCategoriesParams({
    required this.podcastId,
    required this.categories,
  });

  @override
  List<Object?> get props => [podcastId, categories];
}

class UpdatePodcastCategories {
  final SubscriptionRepository _repository;

  UpdatePodcastCategories(this._repository);

  Future<void> call(String podcastId, List<String> categories) async {
    await _repository.updatePodcastCategories(podcastId, categories);
  }
} 