import 'package:equatable/equatable.dart';
import '../repositories/podcast_repository.dart';

class SetAutoUpdateParams extends Equatable {
  final bool enabled;

  const SetAutoUpdateParams({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class SetAutoUpdate {
  final PodcastRepository _repository;

  SetAutoUpdate(this._repository);

  Future<void> call(SetAutoUpdateParams params) async {
    await _repository.setAutoUpdate(params.enabled);
  }
} 