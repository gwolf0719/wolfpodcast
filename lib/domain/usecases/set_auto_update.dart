import 'package:equatable/equatable.dart';
import '../repositories/subscription_repository.dart';

class SetAutoUpdateParams extends Equatable {
  final bool enabled;

  const SetAutoUpdateParams({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class SetAutoUpdate {
  final SubscriptionRepository _repository;

  SetAutoUpdate(this._repository);

  Future<void> call(bool enabled) async {
    await _repository.setAutoUpdate(enabled);
  }
} 