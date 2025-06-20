import '../repositories/player_repository.dart';

class SeekToPosition {
  final PlayerRepository repository;

  SeekToPosition(this.repository);

  Future<void> call(Duration position) async {
    await repository.seekToPosition(position);
  }
} 