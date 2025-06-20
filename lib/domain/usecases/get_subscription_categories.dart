import '../repositories/subscription_repository.dart';

class GetSubscriptionCategories {
  final SubscriptionRepository _repository;

  GetSubscriptionCategories(this._repository);

  Future<List<String>> call() async {
    return await _repository.getSubscriptionCategories();
  }
} 