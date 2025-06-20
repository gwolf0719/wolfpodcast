import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/subscription/subscription_bloc.dart';
import '../widgets/podcast_list.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({Key? key}) : super(key: key);

  @override
  SubscriptionsPageState createState() => SubscriptionsPageState();
}

class SubscriptionsPageState extends State<SubscriptionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SubscriptionBloc>().add(LoadSubscriptionCategoriesEvent());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的訂閱'),
      ),
      body: BlocBuilder<SubscriptionBloc, SubscriptionState>(
        builder: (context, state) {
          if (state is SubscriptionLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SubscriptionErrorState) {
            return Center(child: Text(state.message));
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
            return PodcastList(
              podcasts: state.subscriptions,
              onCategoryEdit: (podcast) => _showCategoryDialog(
                context,
                podcast.id,
                podcast.categories,
              ),
            );
          } else {
            return const Center(child: Text('開始訂閱播客'));
          }
        },
      ),
    );
  }
} 