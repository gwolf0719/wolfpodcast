import '../repositories/player_repository.dart';

class PausePlayback {
  final PlayerRepository repository;

  PausePlayback(this.repository);

  Future<void> call() async {
    await repository.pausePlayback();
  }
} 