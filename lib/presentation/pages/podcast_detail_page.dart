import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/podcast.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/episode_repository.dart';
import '../../domain/repositories/player_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/datasources/podcast_search_service.dart';
import '../../core/theme/app_theme.dart';

class PodcastDetailPage extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailPage({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastDetailPage> createState() => _PodcastDetailPageState();
}

class _PodcastDetailPageState extends State<PodcastDetailPage> {
  final getIt = GetIt.instance;
  
  List<Episode> _episodes = [];
  bool _isLoading = false;
  bool _isSubscribed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _checkSubscriptionStatus();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 首先嘗試從 Episode Repository 獲取
      final episodeRepo = getIt.get<EpisodeRepository>();
      var episodes = await episodeRepo.getEpisodesByPodcastId(widget.podcast.id);
      
      // 如果沒有集數，嘗試從 RSS Feed 獲取
      if (episodes.isEmpty && widget.podcast.feedUrl.isNotEmpty) {
        final searchService = PodcastSearchService.instance;
        episodes = await searchService.getPodcastEpisodes(widget.podcast.feedUrl);
        
        // 儲存集數到本地（暫時跳過以避免錯誤）
        // for (var episode in episodes) {
        //   await episodeRepo.updateEpisode(episode);
        // }
      }
      
      setState(() {
        _episodes = episodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final subscriptionRepo = getIt.get<SubscriptionRepository>();
      final isSubscribed = await subscriptionRepo.isSubscribed(widget.podcast.id);
      setState(() {
        _isSubscribed = isSubscribed;
      });
    } catch (e) {
      // 忽略錯誤
    }
  }

  Future<void> _toggleSubscription() async {
    try {
      final subscriptionRepo = getIt.get<SubscriptionRepository>();
      
      if (_isSubscribed) {
        await subscriptionRepo.unsubscribePodcast(widget.podcast.id);
        setState(() {
          _isSubscribed = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消訂閱')),
        );
      } else {
        await subscriptionRepo.subscribePodcast(widget.podcast);
        setState(() {
          _isSubscribed = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('訂閱成功！')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失敗: ${e.toString()}')),
      );
    }
  }

  Future<void> _playEpisode(Episode episode) async {
    try {
      final playerRepo = getIt.get<PlayerRepository>();
      await playerRepo.playEpisode(episode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('開始播放：${episode.title}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('播放失敗: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 播客資訊頭部
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.playerAccent.withValues(alpha: 0.8),
                      AppTheme.playerAccent.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60), // Space for AppBar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 播客圖片
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: widget.podcast.imageUrl.isNotEmpty
                                  ? Image.network(
                                      widget.podcast.imageUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.white.withValues(alpha: 0.2),
                                          child: const Icon(
                                            Icons.podcasts,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.white.withValues(alpha: 0.2),
                                      child: const Icon(
                                        Icons.podcasts,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            // 播客資訊
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.podcast.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.podcast.author,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.podcast.category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 播客描述和訂閱按鈕
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 訂閱按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleSubscription,
                      icon: Icon(_isSubscribed ? Icons.check : Icons.add),
                      label: Text(_isSubscribed ? '已訂閱' : '訂閱'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSubscribed 
                            ? Colors.grey[400] 
                            : AppTheme.playerAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 播客描述
                  if (widget.podcast.description.isNotEmpty) ...[
                    Text(
                      '關於此播客',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.podcast.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 統計資訊
                  Row(
                    children: [
                      _buildStatItem('集數', '${_episodes.length}'),
                      const SizedBox(width: 32),
                      _buildStatItem('語言', widget.podcast.language),
                      const SizedBox(width: 32),
                      _buildStatItem('分類', widget.podcast.category),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // 集數列表標題
          SliverToBoxAdapter(
            child: Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '集數',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!_isLoading && _episodes.isNotEmpty)
                    Text(
                      '${_episodes.length} 集',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ),
          
          // 集數列表
          _buildEpisodesList(),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '載入集數失敗',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadEpisodes,
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
              ),
            ],
          ),
        ),
      );
    }

    if (_episodes.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.podcasts,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '暫無集數',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '此播客暫時沒有可用的集數',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final episode = _episodes[index];
          return _buildEpisodeItem(episode, index + 1);
        },
        childCount: _episodes.length,
      ),
    );
  }

  Widget _buildEpisodeItem(Episode episode, int episodeNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.playerAccent.withValues(alpha: 0.1),
          child: Text(
            episodeNumber.toString(),
            style: TextStyle(
              color: AppTheme.playerAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          episode.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (episode.description.isNotEmpty)
              Text(
                episode.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(episode.duration),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(episode.publishDate),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _playEpisode(episode),
          icon: Icon(
            Icons.play_circle_filled,
            color: AppTheme.playerAccent,
            size: 40,
          ),
        ),
        onTap: () => _playEpisode(episode),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
} 