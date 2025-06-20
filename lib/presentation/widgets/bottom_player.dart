import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/audio_player_service.dart';
import '../../bloc/player_bloc.dart';

class BottomPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const BottomPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return StreamBuilder<MediaItem?>(
          stream: AudioPlayerService.instance.currentMediaItem,
          builder: (context, mediaItemSnapshot) {
            final mediaItem = mediaItemSnapshot.data;
            
            if (mediaItem == null) {
              return const SizedBox.shrink();
            }

            return Container(
              height: AppConstants.bottomPlayerHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // 封面圖片
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: CachedNetworkImage(
                              imageUrl: mediaItem.artUri?.toString() ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.grey,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // 標題和藝術家
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mediaItem.title,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mediaItem.album ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // 播放控制按鈕
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 播放/暫停按鈕
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  // 簡化版本，暫時不需要完整的播放控制
                                },
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                iconSize: 24,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.speed),
                              onPressed: () => _showSpeedDialog(context, state.playbackSpeed),
                            ),
                            IconButton(
                              icon: Icon(state.isMuted ? Icons.volume_off : Icons.volume_up),
                              onPressed: () => context.read<PlayerBloc>().add(ToggleMuteEvent()),
                            ),
                            IconButton(
                              icon: const Icon(Icons.bedtime),
                              onPressed: () => _showSleepTimerDialog(context, state.sleepTimerRemaining),
                            ),
                            if (state.sleepTimerRemaining != null)
                              Text(
                                '${state.sleepTimerRemaining!.inMinutes}:${(state.sleepTimerRemaining!.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: state.volume,
                            min: 0.0,
                            max: 1.0,
                            onChanged: (value) => context.read<PlayerBloc>().add(SetVolumeEvent(value)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context, double currentSpeed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放速度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var speed in [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0])
              ListTile(
                title: Text('${speed}x'),
                selected: speed == currentSpeed,
                onTap: () {
                  context.read<PlayerBloc>().add(SetPlaybackSpeedEvent(speed));
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context, Duration? currentTimer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('睡眠定時器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentTimer != null)
              ListTile(
                title: const Text('取消定時器'),
                onTap: () {
                  context.read<PlayerBloc>().add(CancelSleepTimerEvent());
                  Navigator.pop(context);
                },
              ),
            for (var minutes in [15, 30, 45, 60, 90])
              ListTile(
                title: Text('$minutes 分鐘'),
                selected: currentTimer?.inMinutes == minutes,
                onTap: () {
                  context.read<PlayerBloc>().add(
                    SetSleepTimerEvent(Duration(minutes: minutes)),
                  );
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// 車用模式底部播放器
class CarModeBottomPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const CarModeBottomPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: AudioPlayerService.instance.currentMediaItem,
      builder: (context, mediaItemSnapshot) {
        final mediaItem = mediaItemSnapshot.data;
        
        if (mediaItem == null) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 120, // 車用模式更高的播放器
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: StreamBuilder<PlaybackState>(
            stream: AudioPlayerService.instance.playbackState,
            builder: (context, playbackSnapshot) {
              final playbackState = playbackSnapshot.data;
              final isPlaying = playbackState?.playing ?? false;
              
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 封面圖片（車用模式更大）
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: CachedNetworkImage(
                              imageUrl: mediaItem.artUri?.toString() ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.error,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 標題和藝術家（車用模式更大字體）
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mediaItem.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mediaItem.album ?? '',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // 播放控制按鈕（車用模式更大）
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 上一首按鈕
                            Container(
                              width: AppConstants.carModeButtonSize,
                              height: AppConstants.carModeButtonSize,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => AudioPlayerService.instance.skipToPrevious(),
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 32,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // 播放/暫停按鈕
                            Container(
                              width: AppConstants.carModeButtonSize + 8,
                              height: AppConstants.carModeButtonSize + 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: isPlaying
                                    ? () => AudioPlayerService.instance.pause()
                                    : () => AudioPlayerService.instance.play(),
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                iconSize: 36,
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // 下一首按鈕
                            Container(
                              width: AppConstants.carModeButtonSize,
                              height: AppConstants.carModeButtonSize,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => AudioPlayerService.instance.skipToNext(),
                                icon: const Icon(Icons.skip_next),
                                iconSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
} 