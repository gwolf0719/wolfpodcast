import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/podcast.dart';
import '../bloc/search/search_bloc.dart';
import 'simple_podcast_detail_page.dart';

final getIt = GetIt.instance;

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchBloc _searchBloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchBloc = getIt<SearchBloc>();
    // 在下一個 frame 載入熱門播客，避免 context 問題
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchBloc.add(const LoadPopularPodcastsEvent());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋 Podcast'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: BlocProvider<SearchBloc>(
        create: (context) => _searchBloc,
        child: Column(
          children: [
            // 搜尋框
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜尋播客名稱或關鍵字...（下方顯示台灣熱門排名）',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchBloc.add(const LoadPopularPodcastsEvent());
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.isNotEmpty) {
                    _searchBloc.add(SearchPodcastsEvent(value));
                  } else {
                    _searchBloc.add(const LoadPopularPodcastsEvent());
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _searchBloc.add(SearchPodcastsEvent(value));
                  }
                },
              ),
            ),
            // 搜尋結果
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  if (state is SearchLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (state is SearchError) {
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
                            '搜尋時發生錯誤',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              if (_searchController.text.isNotEmpty) {
                                _searchBloc.add(SearchPodcastsEvent(_searchController.text));
                              } else {
                                _searchBloc.add(const LoadPopularPodcastsEvent());
                              }
                            },
                            child: const Text('重試'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is SearchResults) {
                    return _buildPodcastList(state.podcasts, '搜尋結果');
                  } else if (state is PopularPodcastsLoaded) {
                    return _buildPodcastList(state.podcasts, '🇹🇼 台灣熱門播客排行榜');
                  } else {
                    return const Center(
                      child: Text('開始搜尋您感興趣的播客！'),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodcastList(List<Podcast> podcasts, String title) {
    if (podcasts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '沒有找到相關播客',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '請嘗試其他關鍵字',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              '$title (${podcasts.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final podcast = podcasts[index];
              return _buildPodcastItem(podcast);
            },
            childCount: podcasts.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPodcastItem(Podcast podcast) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _onPodcastTap(podcast),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 播客圖片
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
              // 播客資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      podcast.author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (podcast.description.isNotEmpty)
                      Text(
                        podcast.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            podcast.category,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${podcast.episodeCount} 集',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
} 