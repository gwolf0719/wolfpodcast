import '../repositories/subscription_repository.dart';

class GetAutoUpdateEnabled {
  final SubscriptionRepository _repository;

  GetAutoUpdateEnabled(this._repository);

  Future<bool> call() async {
    return await _repository.getAutoUpdateEnabled();
  }
} 