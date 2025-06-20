import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/podcast.dart';

import '../../../domain/usecases/get_subscription_categories.dart';
import '../../../domain/usecases/get_subscriptions_by_category.dart';
import '../../../domain/usecases/update_podcast_categories.dart';
import '../../../domain/usecases/set_auto_update.dart';
import '../../../domain/usecases/get_auto_update_enabled.dart';
import '../../../domain/usecases/get_subscribed_podcasts.dart';
import '../../../domain/services/podcast_update_service.dart';

// Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object> get props => [];
}

class LoadSubscriptionsEvent extends SubscriptionEvent {}

class SubscribeEvent extends SubscriptionEvent {
  final Podcast podcast;

  const SubscribeEvent(this.podcast);

  @override
  List<Object> get props => [podcast];
}

class LoadSubscriptionCategoriesEvent extends SubscriptionEvent {
  @override
  List<Object> get props => [];
}

class LoadSubscriptionsByCategoryEvent extends SubscriptionEvent {
  final String category;

  const LoadSubscriptionsByCategoryEvent(this.category);

  @override
  List<Object> get props => [category];
}

class UpdatePodcastCategoriesEvent extends SubscriptionEvent {
  final String podcastId;
  final List<String> categories;

  const UpdatePodcastCategoriesEvent({
    required this.podcastId,
    required this.categories,
  });

  @override
  List<Object> get props => [podcastId, categories];
}

class ToggleAutoUpdateEvent extends SubscriptionEvent {
  final bool enabled;

  const ToggleAutoUpdateEvent(this.enabled);

  @override
  List<Object> get props => [enabled];
}

class LoadAutoUpdateStatusEvent extends SubscriptionEvent {
  @override
  List<Object> get props => [];
}

// States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object> get props => [];
}

class SubscriptionInitialState extends SubscriptionState {}

class SubscriptionLoadingState extends SubscriptionState {}

class SubscriptionLoadedState extends SubscriptionState {
  final List<Podcast> subscriptions;

  const SubscriptionLoadedState(this.subscriptions);

  @override
  List<Object> get props => [subscriptions];
}

class SubscriptionErrorState extends SubscriptionState {
  final String message;

  const SubscriptionErrorState(this.message);

  @override
  List<Object> get props => [message];
}

class SubscriptionCategoriesLoaded extends SubscriptionState {
  final List<String> categories;

  const SubscriptionCategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class SubscriptionsByCategoryLoaded extends SubscriptionState {
  final String category;
  final List<Podcast> podcasts;

  const SubscriptionsByCategoryLoaded({
    required this.category,
    required this.podcasts,
  });

  @override
  List<Object> get props => [category, podcasts];
}

class AutoUpdateStatusLoaded extends SubscriptionState {
  final bool enabled;

  const AutoUpdateStatusLoaded(this.enabled);

  @override
  List<Object> get props => [enabled];
}

// BLoC
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetSubscribedPodcasts getSubscribedPodcasts;
  final GetSubscriptionCategories getSubscriptionCategories;
  final GetSubscriptionsByCategory getSubscriptionsByCategory;
  final UpdatePodcastCategories updatePodcastCategories;
  final GetAutoUpdateEnabled getAutoUpdateEnabled;
  final SetAutoUpdate setAutoUpdate;
  final PodcastUpdateService updateService;

  SubscriptionBloc({
    required this.getSubscribedPodcasts,
    required this.getSubscriptionCategories,
    required this.getSubscriptionsByCategory,
    required this.updatePodcastCategories,
    required this.getAutoUpdateEnabled,
    required this.setAutoUpdate,
    required this.updateService,
  }) : super(SubscriptionInitialState()) {
    on<LoadSubscriptionsEvent>(_onLoadSubscriptions);
    on<LoadSubscriptionCategoriesEvent>(_onLoadSubscriptionCategories);
    on<LoadSubscriptionsByCategoryEvent>(_onLoadSubscriptionsByCategory);
    on<UpdatePodcastCategoriesEvent>(_onUpdatePodcastCategories);
    on<ToggleAutoUpdateEvent>(_onToggleAutoUpdate);
  }

  Future<void> _onLoadSubscriptions(
    LoadSubscriptionsEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoadingState());
      final subscriptions = await getSubscribedPodcasts();
      emit(SubscriptionLoadedState(subscriptions));
    } catch (e) {
      emit(SubscriptionErrorState(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionCategories(
    LoadSubscriptionCategoriesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoadingState());
      final categories = await getSubscriptionCategories();
      emit(SubscriptionCategoriesLoaded(categories));
    } catch (e) {
      emit(SubscriptionErrorState(e.toString()));
    }
  }

  Future<void> _onLoadSubscriptionsByCategory(
    LoadSubscriptionsByCategoryEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoadingState());
      final podcasts = await getSubscriptionsByCategory(event.category);
      emit(SubscriptionsByCategoryLoaded(
        category: event.category,
        podcasts: podcasts,
      ));
    } catch (e) {
      emit(SubscriptionErrorState(e.toString()));
    }
  }

  Future<void> _onUpdatePodcastCategories(
    UpdatePodcastCategoriesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoadingState());
      await updatePodcastCategories(event.podcastId, event.categories);
      add(LoadSubscriptionCategoriesEvent());
    } catch (e) {
      emit(SubscriptionErrorState(e.toString()));
    }
  }

  Future<void> _onToggleAutoUpdate(
    ToggleAutoUpdateEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      emit(SubscriptionLoadingState());
      await setAutoUpdate(event.enabled);
      final isEnabled = await getAutoUpdateEnabled();
      emit(AutoUpdateStatusLoaded(isEnabled));
    } catch (e) {
      emit(SubscriptionErrorState(e.toString()));
    }
  }
} 