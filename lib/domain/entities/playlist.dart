import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PlayMode {
  sequential, // 順序播放
  shuffle,    // 隨機播放
  repeat,     // 重複播放
  repeatOne,  // 單曲重複
}

class Playlist extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<String> episodeIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlayMode playMode;
  final bool isDefault;
  final int currentIndex;
  final Color? color;

  const Playlist({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl,
    this.episodeIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.playMode = PlayMode.sequential,
    this.isDefault = false,
    this.currentIndex = 0,
    this.color,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        episodeIds,
        createdAt,
        updatedAt,
        playMode,
        isDefault,
        currentIndex,
        color,
      ];

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? episodeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    PlayMode? playMode,
    bool? isDefault,
    int? currentIndex,
    Color? color,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      episodeIds: episodeIds ?? this.episodeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playMode: playMode ?? this.playMode,
      isDefault: isDefault ?? this.isDefault,
      currentIndex: currentIndex ?? this.currentIndex,
      color: color ?? this.color,
    );
  }

  // 播放清單總長度
  int get episodeCount => episodeIds.length;

  // 是否為空
  bool get isEmpty => episodeIds.isEmpty;

  // 是否不為空
  bool get isNotEmpty => episodeIds.isNotEmpty;

  // 添加集數
  Playlist addEpisode(String episodeId) {
    if (episodeIds.contains(episodeId)) return this;
    
    return copyWith(
      episodeIds: [...episodeIds, episodeId],
      updatedAt: DateTime.now(),
    );
  }

  // 移除集數
  Playlist removeEpisode(String episodeId) {
    final newEpisodeIds = episodeIds.where((id) => id != episodeId).toList();
    int newCurrentIndex = currentIndex;
    
    // 調整當前索引
    if (currentIndex >= newEpisodeIds.length && newEpisodeIds.isNotEmpty) {
      newCurrentIndex = newEpisodeIds.length - 1;
    } else if (newEpisodeIds.isEmpty) {
      newCurrentIndex = 0;
    }
    
    return copyWith(
      episodeIds: newEpisodeIds,
      currentIndex: newCurrentIndex,
      updatedAt: DateTime.now(),
    );
  }

  // 重新排序集數
  Playlist reorderEpisodes(List<String> newEpisodeIds) {
    return copyWith(
      episodeIds: newEpisodeIds,
      updatedAt: DateTime.now(),
    );
  }

  // 獲取下一個集數索引
  int? getNextIndex() {
    if (isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.sequential:
        return currentIndex < episodeIds.length - 1 ? currentIndex + 1 : null;
      case PlayMode.shuffle:
        // 隨機選擇一個不同的索引
        if (episodeIds.length <= 1) return null;
        int nextIndex;
        do {
          nextIndex = DateTime.now().millisecondsSinceEpoch % episodeIds.length;
        } while (nextIndex == currentIndex);
        return nextIndex;
      case PlayMode.repeat:
        return currentIndex < episodeIds.length - 1 ? currentIndex + 1 : 0;
      case PlayMode.repeatOne:
        return currentIndex;
    }
  }

  // 獲取上一個集數索引
  int? getPreviousIndex() {
    if (isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.sequential:
        return currentIndex > 0 ? currentIndex - 1 : null;
      case PlayMode.shuffle:
        // 隨機選擇一個不同的索引
        if (episodeIds.length <= 1) return null;
        int prevIndex;
        do {
          prevIndex = DateTime.now().millisecondsSinceEpoch % episodeIds.length;
        } while (prevIndex == currentIndex);
        return prevIndex;
      case PlayMode.repeat:
        return currentIndex > 0 ? currentIndex - 1 : episodeIds.length - 1;
      case PlayMode.repeatOne:
        return currentIndex;
    }
  }

  // 播放模式描述
  String get playModeDescription {
    switch (playMode) {
      case PlayMode.sequential:
        return '順序播放';
      case PlayMode.shuffle:
        return '隨機播放';
      case PlayMode.repeat:
        return '重複播放';
      case PlayMode.repeatOne:
        return '單曲重複';
    }
  }
} 