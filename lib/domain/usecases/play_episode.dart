import '../entities/episode.dart';
import '../repositories/player_repository.dart';

class PlayEpisode {
  final PlayerRepository repository;

  PlayEpisode(this.repository);

  Future<void> call(Episode episode) async {
    await repository.playEpisode(episode);
  }
} 