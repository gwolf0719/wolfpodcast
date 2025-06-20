import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/podcast.dart';
import '../../../domain/usecases/get_popular_podcasts.dart';
import '../../../domain/usecases/search_podcasts.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class LoadPopularPodcastsEvent extends SearchEvent {
  final String category;

  const LoadPopularPodcastsEvent({this.category = ''});

  @override
  List<Object> get props => [category];
}

class SearchPodcastsEvent extends SearchEvent {
  final String query;

  const SearchPodcastsEvent(this.query);

  @override
  List<Object> get props => [query];
}

// States
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}

class SearchResults extends SearchState {
  final List<Podcast> podcasts;

  const SearchResults(this.podcasts);

  @override
  List<Object> get props => [podcasts];
}

class PopularPodcastsLoaded extends SearchState {
  final List<Podcast> podcasts;

  const PopularPodcastsLoaded(this.podcasts);

  @override
  List<Object> get props => [podcasts];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final GetPopularPodcasts getPopularPodcasts;
  final SearchPodcasts searchPodcasts;

  SearchBloc({
    required this.getPopularPodcasts,
    required this.searchPodcasts,
  }) : super(SearchInitial()) {
    on<LoadPopularPodcastsEvent>(_onLoadPopularPodcasts);
    on<SearchPodcastsEvent>(_onSearchPodcasts);
  }

  Future<void> _onLoadPopularPodcasts(
    LoadPopularPodcastsEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(SearchLoading());
      final podcasts = await getPopularPodcasts(GetPopularPodcastsParams(category: event.category));
      emit(PopularPodcastsLoaded(podcasts));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onSearchPodcasts(
    SearchPodcastsEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      emit(SearchLoading());
      final podcasts = await searchPodcasts(SearchPodcastsParams(query: event.query));
      emit(SearchResults(podcasts));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
} 