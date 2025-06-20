import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/app_constants.dart';
import '../../data/datasources/podcast_search_service.dart';
import '../../domain/entities/podcast.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../widgets/podcast_list.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final PodcastSearchService _searchService = PodcastSearchService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播客分類'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: PodcastSearchService.categories.length,
        itemBuilder: (context, index) {
          final category = PodcastSearchService.categories[index];
          return _buildCategoryCard(context, category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, PodcastCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(
            _getCategoryIcon(category.id),
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${category.subcategories.length} 個子分類',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CategoryPodcastsPage(category: category),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'arts':
        return Icons.palette;
      case 'business':
        return Icons.business;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'education':
        return Icons.school;
      case 'fiction':
        return Icons.auto_stories;
      case 'government':
        return Icons.account_balance;
      case 'history':
        return Icons.history_edu;
      case 'health-fitness':
        return Icons.fitness_center;
      case 'kids-family':
        return Icons.family_restroom;
      case 'leisure':
        return Icons.sports_esports;
      case 'music':
        return Icons.music_note;
      case 'news':
        return Icons.newspaper;
      case 'religion-spirituality':
        return Icons.self_improvement;
      case 'science':
        return Icons.science;
      case 'society-culture':
        return Icons.people;
      case 'sports':
        return Icons.sports_soccer;
      case 'technology':
        return Icons.computer;
      case 'true-crime':
        return Icons.gavel;
      case 'tv-film':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }
}

class CategoryPodcastsPage extends StatefulWidget {
  final PodcastCategory category;

  const CategoryPodcastsPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryPodcastsPage> createState() => _CategoryPodcastsPageState();
}

class _CategoryPodcastsPageState extends State<CategoryPodcastsPage> {
  final PodcastSearchService _searchService = PodcastSearchService.instance;
  List<Podcast> _podcasts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final podcasts = await _searchService.searchPodcastsByCategory(
        widget.category.id,
        limit: 50,
      );
      
      setState(() {
        _podcasts = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
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
              '載入失敗',
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
              onPressed: _loadPodcasts,
              icon: const Icon(Icons.refresh),
              label: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_podcasts.isEmpty) {
      return Center(
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
              '此分類暫無播客',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '試試其他分類吧！',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return PodcastList(
      podcasts: _podcasts,
      onPodcastTap: (podcast) {
        // 導航到播客詳情頁面
        _showPodcastDetails(context, podcast);
      },
    );
  }

  void _showPodcastDetails(BuildContext context, Podcast podcast) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PodcastDetailSheet(podcast: podcast),
    );
  }
}

class PodcastDetailSheet extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailSheet({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastDetailSheet> createState() => _PodcastDetailSheetState();
}

class _PodcastDetailSheetState extends State<PodcastDetailSheet> {
  final getIt = GetIt.instance;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
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
    setState(() {
      _isLoading = true;
    });

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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 頂部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 內容區域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
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
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.podcasts, size: 40),
                                  );
                                },
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Icon(Icons.podcasts, size: 40),
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
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.podcast.author,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(
                                widget.podcast.category,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                      onPressed: _isLoading ? null : _toggleSubscription,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(_isSubscribed ? Icons.check : Icons.add),
                      label: Text(_isSubscribed ? '已訂閱' : '訂閱'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSubscribed 
                            ? Colors.grey[400] 
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 描述
                  if (widget.podcast.description.isNotEmpty) ...[
                    Text(
                      '簡介',
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
                    const SizedBox(height: 24),
                  ],
                  
                  // 統計資訊
                  Row(
                    children: [
                      _buildStatItem('集數', '${widget.podcast.episodeCount}'),
                      const SizedBox(width: 32),
                      _buildStatItem('語言', widget.podcast.language),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            fontSize: 16,
          ),
        ),
      ],
    );
  }
} 