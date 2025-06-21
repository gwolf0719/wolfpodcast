import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/subscription/subscription_bloc.dart';
import '../widgets/podcast_list.dart';
import 'simple_podcast_detail_page.dart';
import '../../domain/entities/podcast.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({Key? key}) : super(key: key);

  @override
  SubscriptionsPageState createState() => SubscriptionsPageState();
}

class SubscriptionsPageState extends State<SubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    // 載入所有訂閱的播客
    context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
  }

  void _showCategoryDialog(BuildContext context, String podcastId, List<String> currentCategories) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('編輯分類'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: '新增分類',
                hintText: '輸入分類名稱',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: currentCategories.map((category) {
                return Chip(
                  label: Text(category),
                  onDeleted: () {
                    final updatedCategories = List<String>.from(currentCategories)
                      ..remove(category);
                    context.read<SubscriptionBloc>().add(
                      UpdatePodcastCategoriesEvent(
                        podcastId: podcastId,
                        categories: updatedCategories,
                      ),
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final updatedCategories = List<String>.from(currentCategories)
                  ..add(textController.text);
                context.read<SubscriptionBloc>().add(
                  UpdatePodcastCategoriesEvent(
                    podcastId: podcastId,
                    categories: updatedCategories,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _onPodcastTap(Podcast podcast) {
    print('🎯 訂閱頁面：點擊播客 ${podcast.title}');
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            print('🎯 正在導航到 SimplePodcastDetailPage');
            return SimplePodcastDetailPage(podcast: podcast);
          },
        ),
      ).then((_) {
        print('🎯 從播客詳情頁面返回');
      }).catchError((error) {
        print('🔥 導航錯誤: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('導航失敗: $error')),
        );
      });
    } catch (e) {
      print('🔥 點擊處理錯誤: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('處理點擊失敗: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的訂閱'),
      ),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          print('🎯 訂閱狀態: ${state.runtimeType}');
          
          if (state is SubscriptionLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SubscriptionErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('錯誤: ${state.message}'),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          } else if (state is SubscriptionCategoriesLoaded) {
            return ListView(
              children: [
                // 全部訂閱
                ListTile(
                  title: const Text('全部'),
                  leading: const Icon(Icons.podcasts),
                  onTap: () {
                    context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
                  },
                ),
                const Divider(),
                // 分類列表
                for (final category in state.categories)
                  ListTile(
                    title: Text(category),
                    leading: const Icon(Icons.folder),
                    onTap: () {
                      context.read<SubscriptionBloc>().add(
                        LoadSubscriptionsByCategoryEvent(category),
                      );
                    },
                  ),
              ],
            );
          } else if (state is SubscriptionsByCategoryLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '分類：${state.category}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: PodcastList(
                    podcasts: state.podcasts,
                    onPodcastTap: _onPodcastTap,
                    onCategoryEdit: (podcast) => _showCategoryDialog(
                      context,
                      podcast.id,
                      podcast.categories,
                    ),
                  ),
                ),
              ],
            );
          } else if (state is SubscriptionLoadedState) {
            print('🎯 載入了 ${state.subscriptions.length} 個訂閱');
            if (state.subscriptions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.podcasts, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('還沒有訂閱任何播客'),
                    SizedBox(height: 8),
                    Text('前往探索或搜尋頁面來訂閱播客'),
                  ],
                ),
              );
            }
            return PodcastList(
              podcasts: state.subscriptions,
              onPodcastTap: _onPodcastTap,
              onCategoryEdit: (podcast) => _showCategoryDialog(
                context,
                podcast.id,
                podcast.categories,
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('開始訂閱播客'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(LoadSubscriptionsEvent());
                    },
                    child: const Text('重新載入'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
} 