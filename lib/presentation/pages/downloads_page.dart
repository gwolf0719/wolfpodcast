import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../domain/entities/episode.dart';
import '../bloc/download/download_bloc.dart';
import 'downloading_page.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('下載管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '已下載'),
              Tab(text: '下載中'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _DownloadedEpisodesTab(),
            _DownloadingEpisodesTab(),
          ],
        ),
      ),
    );
  }
}

class _DownloadedEpisodesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        // Load downloads when the tab is opened
        if (state is DownloadInitial) {
          context.read<DownloadBloc>().add(LoadDownloadsEvent());
          return const Center(child: CircularProgressIndicator());
        }

        if (state is DownloadInProgress) {
          final downloadedEpisodes = state.downloadedEpisodes
              .where((episode) => episode.isDownloaded)
              .toList();

          if (downloadedEpisodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download_done,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '沒有已下載的節目',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: downloadedEpisodes.length,
            itemBuilder: (context, index) {
              final episode = downloadedEpisodes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: episode.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.podcasts, size: 32),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.error, size: 32),
                      ),
                    ),
                  ),
                  title: Text(
                    episode.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '已下載 • ${episode.duration.inMinutes} 分鐘',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<DownloadBloc>().add(
                        DeleteDownloadEvent(episode.id),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }

        if (state is DownloadError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64),
                const SizedBox(height: 16),
                Text(state.message),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _DownloadingEpisodesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        if (state is DownloadInProgress) {
          if (state.downloadProgress.isEmpty) {
            return const Center(
              child: Text('沒有正在下載的內容'),
            );
          }

          return ListView.builder(
            itemCount: state.downloadProgress.length,
            itemBuilder: (context, index) {
              final episodeId = state.downloadProgress.keys.elementAt(index);
              final progress = state.downloadProgress[episodeId] ?? 0.0;
              return _DownloadingEpisodeItem(
                episodeId: episodeId,
                progress: progress,
              );
            },
          );
        }

        return const Center(
          child: Text('沒有正在下載的內容'),
        );
      },
    );
  }
}

class _DownloadingEpisodeItem extends StatelessWidget {
  final String episodeId;
  final double progress;

  const _DownloadingEpisodeItem({
    required this.episodeId,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Episode $episodeId'),
      subtitle: LinearProgressIndicator(value: progress),
      trailing: IconButton(
        icon: const Icon(Icons.cancel),
        onPressed: () {
          context.read<DownloadBloc>().add(
                CancelDownloadEvent(episodeId),
              );
        },
      ),
    );
  }
} 