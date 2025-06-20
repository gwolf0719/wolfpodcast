import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audio_service/audio_service.dart';

import '../../core/theme/app_theme.dart';
import '../../data/datasources/audio_player_service.dart';
import '../../domain/entities/episode.dart';
import '../../domain/entities/podcast.dart';

class PlayerPage extends StatefulWidget {
  final Episode episode;
  final Podcast podcast;

  const PlayerPage({
    super.key,
    required this.episode,
    required this.podcast,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 移除自動顯示的 SnackBar，因為它可能造成錯誤
    // 用戶點擊播放按鈕時會有其他反饋
  }

  void _initializePlayer() async {
    try {
      // 開始播放集數
      await AudioPlayerService.instance.playEpisode(widget.episode);
    } catch (e) {
      print('播放初始化失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.playerAccent.withValues(alpha: 0.3),
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildAlbumArt(),
                      const SizedBox(height: 32),
                      _buildTrackInfo(),
                      const SizedBox(height: 32),
                      _buildProgressBar(),
                      const SizedBox(height: 32),
                      _buildControls(),
                      const SizedBox(height: 24),
                      _buildSecondaryControls(),
                      if (_isExpanded) ...[
                        const SizedBox(height: 32),
                        _buildEpisodeDescription(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 32,
            ),
          ),
          Column(
            children: [
              Text(
                '正在播放',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                widget.podcast.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareEpisode();
                  break;
                case 'download':
                  _downloadEpisode();
                  break;
                case 'add_to_playlist':
                  _addToPlaylist();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('分享'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'download',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('下載'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'add_to_playlist',
                child: ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text('加入播放清單'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.episode.imageUrl.isNotEmpty 
              ? widget.episode.imageUrl 
              : widget.podcast.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.podcasts,
              size: 100,
              color: Colors.white30,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Icon(
              Icons.error,
              size: 100,
              color: Colors.white30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          widget.episode.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          widget.podcast.author,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(widget.episode.duration),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(widget.episode.publishDate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        StreamBuilder<Duration?>(
          stream: AudioPlayerService.instance.position,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = widget.episode.duration ?? Duration.zero;
            final progress = duration.inMilliseconds > 0 
                ? position.inMilliseconds / duration.inMilliseconds 
                : 0.0;

            return SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.2),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final newPosition = Duration(
                    milliseconds: (value * duration.inMilliseconds).round(),
                  );
                  AudioPlayerService.instance.seek(newPosition);
                },
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<Duration?>(
                stream: AudioPlayerService.instance.position,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  return Text(
                    _formatDuration(position),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  );
                },
              ),
              Text(
                _formatDuration(widget.episode.duration ?? Duration.zero),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 快退15秒
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _seekRelative(-15),
            icon: const Icon(
              Icons.replay,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        
        // 上一首
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => AudioPlayerService.instance.skipToPrevious(),
            icon: const Icon(
              Icons.skip_previous,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // 播放/暫停
        StreamBuilder<PlaybackState>(
          stream: AudioPlayerService.instance.playbackState,
          builder: (context, snapshot) {
            final playbackState = snapshot.data;
            final isPlaying = playbackState?.playing ?? false;
            final isLoading = playbackState?.processingState == AudioProcessingState.loading;
            
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.playerAccent,
                        strokeWidth: 3,
                      ),
                    )
                  : IconButton(
                      onPressed: isPlaying
                          ? () => AudioPlayerService.instance.pause()
                          : () => AudioPlayerService.instance.play(),
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.playerAccent,
                        size: 40,
                      ),
                    ),
            );
          },
        ),
        
        // 下一首
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => AudioPlayerService.instance.skipToNext(),
            icon: const Icon(
              Icons.skip_next,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // 快進30秒
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _seekRelative(30),
            icon: const Icon(
              Icons.forward,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => _showSpeedDialog(),
          icon: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speed, color: Colors.white70),
              Text(
                '1.0x',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _showSleepTimerDialog(),
          icon: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bedtime, color: Colors.white70),
              Text(
                '定時',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          icon: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
              ),
              Text(
                '詳情',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _toggleFavorite(),
          icon: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, color: Colors.white70),
              Text(
                '收藏',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeDescription() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '集數簡介',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.episode.description.isNotEmpty 
                ? widget.episode.description 
                : '暫無集數簡介',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _seekRelative(int seconds) async {
    try {
      final audioPlayer = AudioPlayerService.instance;
      final currentPosition = await audioPlayer.position.first;
      final newPosition = currentPosition + Duration(seconds: seconds);
      
      // 確保新位置不會超出範圍
      final duration = await audioPlayer.duration.first;
      if (duration != null) {
        final clampedPosition = Duration(
          milliseconds: newPosition.inMilliseconds.clamp(0, duration.inMilliseconds),
        );
        await audioPlayer.seek(clampedPosition);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${seconds > 0 ? '快進' : '快退'} ${seconds.abs()} 秒')),
      );
    } catch (e) {
      print('相對定位失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('定位失敗')),
      );
    }
  }

  void _showSpeedDialog() {
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
                selected: speed == 1.0, // 這裡應該從狀態獲取實際速度
                onTap: () {
                  // TODO: 實現播放速度設置
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('播放速度設置為 ${speed}x')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('睡眠定時器'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var minutes in [15, 30, 45, 60, 90])
              ListTile(
                title: Text('$minutes 分鐘'),
                onTap: () {
                  // TODO: 實現睡眠定時器設置
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('定時器設置為 $minutes 分鐘')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _shareEpisode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能開發中...')),
    );
  }

  void _downloadEpisode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('下載功能開發中...')),
    );
  }

  void _addToPlaylist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('播放清單功能開發中...')),
    );
  }

  void _toggleFavorite() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('收藏功能開發中...')),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}