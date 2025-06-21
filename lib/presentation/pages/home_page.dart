import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/podcast.dart';
import '../bloc/subscription/subscription_bloc.dart';
import '../widgets/bottom_navigation.dart';
import 'search_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'categories_page.dart';
import 'simple_podcast_detail_page.dart';
import 'subscriptions_page.dart';


final getIt = GetIt.instance;

class HomePage extends StatefulWidget {
  final int initialTab;
  
  const HomePage({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pages = [
      const DiscoverPage(),
      const SearchPage(),
      const SubscriptionsPage(), // 使用 BLoC 版本的頁面
      const DownloadsPage(),
      const SettingsPage(),
    ];

    // 如果初始頁面是訂閱頁，觸發一次載入事件
    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
      });
    }
  }

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
          
          // 如果切換到訂閱頁面，發送事件以刷新列表
          if (index == 2) {
            context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
          }
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

 