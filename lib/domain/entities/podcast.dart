import 'package:equatable/equatable.dart';

class Podcast extends Equatable {
  final String id;
  final String title;
  final String description;
  final String author;
  final String imageUrl;
  final String feedUrl;
  final List<String> categories;
  final bool isSubscribed;
  final String category;
  final String language;
  final DateTime lastUpdate;
  final int episodeCount;
  final DateTime? createdAt;

  const Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.imageUrl,
    required this.feedUrl,
    this.categories = const [],
    this.isSubscribed = false,
    required this.category,
    required this.language,
    required this.lastUpdate,
    this.episodeCount = 0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    author,
    imageUrl,
    feedUrl,
    categories,
    isSubscribed,
    category,
    language,
    lastUpdate,
    episodeCount,
    createdAt,
  ];

  Podcast copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    String? imageUrl,
    String? feedUrl,
    List<String>? categories,
    bool? isSubscribed,
    String? category,
    String? language,
    DateTime? lastUpdate,
    int? episodeCount,
    DateTime? createdAt,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      imageUrl: imageUrl ?? this.imageUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      categories: categories ?? this.categories,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      category: category ?? this.category,
      language: language ?? this.language,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      episodeCount: episodeCount ?? this.episodeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'imageUrl': imageUrl,
      'feedUrl': feedUrl,
      'categories': categories,
      'isSubscribed': isSubscribed,
      'category': category,
      'language': language,
      'lastUpdate': lastUpdate.toIso8601String(),
      'episodeCount': episodeCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      imageUrl: json['imageUrl'] as String,
      feedUrl: json['feedUrl'] as String,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      category: json['category'] as String,
      language: json['language'] as String,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
      episodeCount: json['episodeCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }
} 