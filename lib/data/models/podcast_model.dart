import 'package:hive/hive.dart';
import '../../domain/entities/podcast.dart';

part 'podcast_model.g.dart';

@HiveType(typeId: 0)
class PodcastModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  final String feedUrl;

  @HiveField(6)
  final List<String> categories;

  @HiveField(7)
  final DateTime lastUpdated;

  @HiveField(8)
  final String category;

  @HiveField(9)
  final String language;

  @HiveField(10)
  final bool isSubscribed;

  @HiveField(11)
  final DateTime? createdAt;

  @HiveField(12)
  final int episodeCount;

  PodcastModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.feedUrl,
    required this.categories,
    required this.lastUpdated,
    required this.category,
    required this.language,
    this.isSubscribed = false,
    this.createdAt,
    this.episodeCount = 0,
  });

  Podcast toEntity() {
    return Podcast(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      feedUrl: feedUrl,
      author: author,
      category: category,
      language: language,
      isSubscribed: isSubscribed,
      createdAt: createdAt,
      lastUpdate: lastUpdated,
      episodeCount: episodeCount,
      categories: categories,
    );
  }

  factory PodcastModel.fromEntity(Podcast podcast) {
    return PodcastModel(
      id: podcast.id,
      title: podcast.title,
      author: podcast.author,
      description: podcast.description,
      imageUrl: podcast.imageUrl,
      feedUrl: podcast.feedUrl,
      categories: podcast.categories,
      lastUpdated: podcast.lastUpdate,
      category: podcast.category,
      language: podcast.language,
      isSubscribed: podcast.isSubscribed,
      createdAt: podcast.createdAt,
      episodeCount: podcast.episodeCount,
    );
  }

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      feedUrl: json['feedUrl'],
      categories: List<String>.from(json['categories'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
      category: json['category'] ?? '',
      language: json['language'] ?? '',
      isSubscribed: json['isSubscribed'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      episodeCount: json['episodeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'imageUrl': imageUrl,
      'feedUrl': feedUrl,
      'categories': categories,
      'lastUpdated': lastUpdated.toIso8601String(),
      'category': category,
      'language': language,
      'isSubscribed': isSubscribed,
      'createdAt': createdAt?.toIso8601String(),
      'episodeCount': episodeCount,
    };
  }
} 