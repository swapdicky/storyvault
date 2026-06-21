import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../../domain/repositories/story_repository.dart';
import '../../domain/entities/story.dart';
import '../notifiers/story_notifier.dart';

// Story Repository Provider
final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl();
});

// Story Notifier Provider
final storyNotifierProvider = StateNotifierProvider<StoryNotifier, StoryState>((ref) {
  return StoryNotifier(ref.watch(storyRepositoryProvider));
});

// Convenience providers
final storiesProvider = Provider<List<Story>>((ref) {
  return ref.watch(storyNotifierProvider).stories;
});

final storyLoadingProvider = Provider<bool>((ref) {
  return ref.watch(storyNotifierProvider).isLoading;
});

final storyUploadingProvider = Provider<bool>((ref) {
  return ref.watch(storyNotifierProvider).isUploading;
});

final storyDeletingProvider = Provider<bool>((ref) {
  return ref.watch(storyNotifierProvider).isDeleting;
});

final storyErrorProvider = Provider<String?>((ref) {
  return ref.watch(storyNotifierProvider).errorMessage;
});
