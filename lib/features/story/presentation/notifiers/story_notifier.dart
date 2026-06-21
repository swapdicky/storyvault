import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';

class StoryNotifier extends StateNotifier<StoryState> {
  final StoryRepository _storyRepository;

  StoryNotifier(this._storyRepository) : super(const StoryState());

  Future<void> uploadStory({
    required String userId,
    required String localFilePath,
    required int duration,
    String? title,
  }) async {
    state = state.copyWith(isUploading: true, errorMessage: null);

    final result = await _storyRepository.uploadStory(
      userId: userId,
      localFilePath: localFilePath,
      duration: duration,
      title: title,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isUploading: false,
          errorMessage: failure.message,
        );
      },
      (story) {
        final updatedStories = [story, ...state.stories];
        state = state.copyWith(
          isUploading: false,
          stories: updatedStories,
        );
      },
    );
  }

  Future<void> loadUserStories(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _storyRepository.getUserStories(userId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (stories) {
        state = state.copyWith(
          isLoading: false,
          stories: stories,
        );
      },
    );
  }

  Future<void> deleteStory(String storyId) async {
    state = state.copyWith(isDeleting: true, errorMessage: null);

    final result = await _storyRepository.deleteStory(storyId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isDeleting: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        final updatedStories = state.stories.where((s) => s.id != storyId).toList();
        state = state.copyWith(
          isDeleting: false,
          stories: updatedStories,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

class StoryState {
  final List<Story> stories;
  final bool isLoading;
  final bool isUploading;
  final bool isDeleting;
  final String? errorMessage;

  const StoryState({
    this.stories = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.isDeleting = false,
    this.errorMessage,
  });

  StoryState copyWith({
    List<Story>? stories,
    bool? isLoading,
    bool? isUploading,
    bool? isDeleting,
    String? errorMessage,
  }) {
    return StoryState(
      stories: stories ?? this.stories,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage,
    );
  }
}
