import 'package:flutter/material.dart';
import '../../domain/entities/podcast.dart';

class PodcastList extends StatelessWidget {
  final List<Podcast> podcasts;
  final Function(Podcast)? onPodcastTap;
  final Function(Podcast)? onSubscribeTap;
  final Function(Podcast)? onCategoryEdit;

  const PodcastList({
    Key? key,
    required this.podcasts,
    this.onPodcastTap,
    this.onSubscribeTap,
    this.onCategoryEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) {
      return const Center(
        child: Text('沒有找到播客'),
      );
    }

    return ListView.builder(
      itemCount: podcasts.length,
      itemBuilder: (context, index) {
        final podcast = podcasts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                podcast.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: const Icon(Icons.podcasts),
                  );
                },
              ),
            ),
            title: Text(
              podcast.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast.author,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  podcast.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                podcast.isSubscribed ? Icons.favorite : Icons.favorite_border,
                color: podcast.isSubscribed ? Colors.red : null,
              ),
              onPressed: () => onSubscribeTap?.call(podcast),
            ),
            onTap: () => onPodcastTap?.call(podcast),
          ),
        );
      },
    );
  }
} 