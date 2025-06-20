import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../domain/entities/podcast.dart';
import '../widgets/bottom_navigation.dart';
import 'search_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'categories_page.dart';
import 'simple_podcast_detail_page.dart';


final getIt = GetIt.instance;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DiscoverPage(),
    const SearchPage(),
    const SubscriptionsPage(),
    const DownloadsPage(),
    const SettingsPage(),
  ];

  // ignore: unused_field
  final SubscriptionRepository _subscriptionRepo = getIt<SubscriptionRepository>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// 探索頁面
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('探索'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              // TODO: 切換車用模式
            },
            icon: const Icon(Icons.drive_eta),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 歡迎區域
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.playerAccent,
                    Color(0xFF4F378B),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.podcasts,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '歡迎使用 Wolf Podcast',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '探索全球優質 Podcast 內容',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('開始搜尋'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.playerAccent,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 功能區域
            Text(
              '功能探索',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 功能卡片
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.trending_up,
                  title: '熱門 Podcast',
                  description: '探索當前最受歡迎的頻道',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.category,
                  title: '分類瀏覽',
                  description: '按主題尋找感興趣的內容',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CategoriesPage(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.bookmark,
                  title: '我的收藏',
                  description: '查看已收藏的 Podcast',
                  onTap: () {
                    // TODO: 導航到收藏頁面
                  },
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.download,
                  title: '離線下載',
                  description: '下載內容供離線收聽',
                  onTap: () {
                    // TODO: 導航到下載頁面
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 快速操作
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.mic,
                    label: '語音搜尋',
                    onTap: () {
                      // TODO: 實現語音搜尋
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('語音搜尋功能開發中...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: '掃描 QR 碼',
                    onTap: () {
                      // TODO: 實現 QR 碼掃描
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR 碼掃描功能開發中...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// 訂閱頁面
class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final SubscriptionRepository _subscriptionRepo = getIt<SubscriptionRepository>();
  List<Podcast> _subscribedPodcasts = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _subscriptionRepo.initialize();
      final podcasts = await _subscriptionRepo.getSubscribedPodcasts();
      setState(() {
        _subscribedPodcasts = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '載入訂閱失敗：$e';
      });
    }
  }

  Future<void> _refreshSubscriptions() async {
    await _loadSubscriptions();
  }

  Future<void> _unsubscribePodcast(Podcast podcast) async {
    try {
      await _subscriptionRepo.unsubscribePodcast(podcast.id);
      await _refreshSubscriptions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已取消訂閱：${podcast.title}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('取消訂閱失敗：$e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的訂閱 (${_subscribedPodcasts.length})'),
        actions: [
          IconButton(
            onPressed: _refreshSubscriptions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshSubscriptions,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshSubscriptions,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_subscribedPodcasts.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.subscriptions,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '尚未訂閱任何頻道',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '前往探索頁面搜尋並訂閱 Podcast',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subscribedPodcasts.length,
      itemBuilder: (context, index) {
        final podcast = _subscribedPodcasts[index];
        return _buildSubscriptionItem(podcast);
      },
    );
  }

  Widget _buildSubscriptionItem(Podcast podcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onPodcastTap(podcast),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Podcast 圖片
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: podcast.imageUrl.isNotEmpty
                    ? Image.network(
                        podcast.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.podcasts, size: 40),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.podcasts, size: 40),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Podcast 資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.category,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (podcast.episodeCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${podcast.episodeCount} 集',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 操作按鈕
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'unsubscribe':
                      _showUnsubscribeDialog(podcast);
                      break;
                    case 'episodes':
                      _onViewEpisodes(podcast);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'episodes',
                    child: ListTile(
                      leading: Icon(Icons.list),
                      title: Text('查看集數'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'unsubscribe',
                    child: ListTile(
                      leading: Icon(Icons.unsubscribe),
                      title: Text('取消訂閱'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPodcastTap(Podcast podcast) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimplePodcastDetailPage(podcast: podcast),
      ),
    );
  }

  void _onViewEpisodes(Podcast podcast) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimplePodcastDetailPage(podcast: podcast),
      ),
    );
  }

  void _showUnsubscribeDialog(Podcast podcast) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消訂閱'),
        content: Text('確定要取消訂閱「${podcast.title}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unsubscribePodcast(podcast);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

// 播放清單頁面
class PlaylistsPage extends StatelessWidget {
  const PlaylistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('播放清單'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 新增播放清單
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '尚未建立任何播放清單',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '點擊右上角 + 按鈕建立新的播放清單',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 設定頁面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '播放設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('播放速度'),
            subtitle: const Text('1.0x'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置播放速度
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('睡眠計時器'),
            subtitle: const Text('關閉'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置睡眠計時器
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '應用設定',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('主題'),
            subtitle: const Text('跟隨系統'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 設置主題
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_eta),
            title: const Text('車用模式'),
            subtitle: const Text('大按鈕介面'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 切換車用模式
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '關於',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('版本'),
            subtitle: const Text(AppConstants.appVersion),
          ),
        ],
      ),
    );
  }
} 