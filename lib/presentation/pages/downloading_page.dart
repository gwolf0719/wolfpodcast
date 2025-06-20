import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/download/download_bloc.dart';
import '../../domain/entities/episode.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadingPage extends StatelessWidget {
  const DownloadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadBloc, DownloadState>(
      builder: (context, state) {
        if (state is DownloadInProgress) {
          if (state.downloadProgress.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.download,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '沒有正在下載的內容',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.downloadProgress.length,
            itemBuilder: (context, index) {
              final episodeId = state.downloadProgress.keys.elementAt(index);
              final progress = state.downloadProgress[episodeId] ?? 0.0;
              final episode = state.downloadedEpisodes.firstWhere(
                (e) => e.id == episodeId,
                orElse: () => Episode.empty(),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: episode.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.podcasts, size: 32),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.error, size: 32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  episode.title,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(progress * 100).toInt()}% 已下載',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () {
                              context.read<DownloadBloc>().add(
                                    CancelDownloadEvent(episodeId),
                                  );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                '沒有正在下載的內容',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 