import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../domain/entities/podcast.dart';
import '../../domain/entities/episode.dart';
import '../../domain/repositories/episode_repository.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/datasources/podcast_search_service.dart';
import '../../core/theme/app_theme.dart';
import 'player_page.dart';

class SimplePodcastDetailPage extends StatefulWidget {
  final Podcast podcast;

  const SimplePodcastDetailPage({
    super.key,
    required this.podcast,
  });

  @override
  State<SimplePodcastDetailPage> createState() => _SimplePodcastDetailPageState();
}

class _SimplePodcastDetailPageState extends State<SimplePodcastDetailPage> {
  final getIt = GetIt.instance;
  
  bool _isSubscribed = false;
  List<Episode> _episodes = [];
  bool _isLoadingEpisodes = false;
  String? _episodeError;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    if (widget.podcast.feedUrl.isEmpty) return;
    
    setState(() {
      _isLoadingEpisodes = true;
      _episodeError = null;
    });

    try {
      List<Episode> episodes = [];
      
      // 首先嘗試從 RSS Feed 獲取（因為這是主要的資料來源）
      if (widget.podcast.feedUrl.isNotEmpty) {
        final searchService = PodcastSearchService.instance;
        episodes = await searchService.getPodcastEpisodes(widget.podcast.feedUrl);
      }
      
      // 如果 RSS Feed 沒有資料，嘗試從本地 Repository 獲取
      if (episodes.isEmpty) {
        final episodeRepo = getIt.get<EpisodeRepository>();
        episodes = await episodeRepo.getEpisodesByPodcastId(widget.podcast.id);
      }
      
      setState(() {
        _episodes = episodes;
        _isLoadingEpisodes = false;
      });
    } catch (e) {
      setState(() {
        _episodeError = e.toString();
        _isLoadingEpisodes = false;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.podcast.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 播客圖片和基本資訊
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.podcasts,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.podcasts,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.podcast.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.podcast.author,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.playerAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.podcast.category,
                          style: TextStyle(
                            color: AppTheme.playerAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
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
            
            const SizedBox(height: 24),
            
            // 關於此播客的描述
            if (widget.podcast.feedUrl.isNotEmpty) ...[
              Text(
                '關於此播客',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.podcast.feedUrl,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
            ],
            
            // 統計資訊 - 使用真實的集數統計
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('集數', '${_episodes.length}'),
                _buildStatItem('語言', widget.podcast.language),
                _buildStatItem('分類', widget.podcast.category),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 最新集數標題
            Row(
              children: [
                Text(
                  '最新集數',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoadingEpisodes)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 集數列表
            _buildEpisodesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
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
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesList() {
    if (_isLoadingEpisodes) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_episodeError != null) {
      return Card(
        color: Colors.red[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                '載入集數失敗',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _episodeError!,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _loadEpisodes,
                icon: const Icon(Icons.refresh),
                label: const Text('重試'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_episodes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
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

    // 顯示所有真實集數
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        return _buildEpisodeItem(_episodes[index]);
      },
    );
  }

  Widget _buildEpisodeItem(Episode episode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.playerAccent.withValues(alpha: 0.1),
          child: Text(
            (episode.episodeNumber ?? _episodes.indexOf(episode) + 1).toString(),
            style: TextStyle(
              color: AppTheme.playerAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
                  fontSize: 13,
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
                  episode.formattedDuration,
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _playEpisode(Episode episode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerPage(
          episode: episode,
          podcast: widget.podcast,
        ),
      ),
    );
  }
} 