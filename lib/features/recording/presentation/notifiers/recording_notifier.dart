import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../../story/domain/repositories/story_repository.dart';
import '../../../story/presentation/providers/story_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show currentUserIdProvider;

class RecordingNotifier extends StateNotifier<RecordingState> {
  final RecordingRepository _recordingRepository;
  final StoryRepository _storyRepository;
  final Ref _ref;

  RecordingNotifier(
    this._recordingRepository,
    this._storyRepository,
    this._ref,
  ) : super(const RecordingState()) {
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    final result = await _recordingRepository.getRecordings();
    result.fold(
      (failure) {
        state = state.copyWith(
          errorMessage: failure.message,
        );
      },
      (recordings) {
        state = state.copyWith(recordings: recordings);
      },
    );
  }

  Future<void> startRecording() async {
    state = state.copyWith(isRecording: true, errorMessage: null);
    
    final result = await _recordingRepository.startRecording();
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isRecording: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(isRecording: true);
      },
    );
  }

  Future<void> pauseRecording() async {
    final result = await _recordingRepository.pauseRecording();
    
    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (_) {
        state = state.copyWith(isPaused: true);
      },
    );
  }

  Future<void> resumeRecording() async {
    final result = await _recordingRepository.resumeRecording();
    
    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (_) {
        state = state.copyWith(isPaused: false);
      },
    );
  }

  Future<void> stopRecording() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _recordingRepository.stopRecording();
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isRecording: false,
          isPaused: false,
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (recording) async {
        // Upload to cloud
        final userId = _ref.read(currentUserIdProvider);
        if (userId != null) {
          await _ref.read(storyNotifierProvider.notifier).uploadStory(
            userId: userId,
            localFilePath: recording.filePath,
            duration: recording.duration,
          );
        }
        
        final updatedRecordings = [recording, ...state.recordings];
        state = state.copyWith(
          isRecording: false,
          isPaused: false,
          isLoading: false,
          recordings: updatedRecordings,
        );
      },
    );
  }

  Future<void> playRecording(String filePath) async {
    state = state.copyWith(isPlaying: true, errorMessage: null);
    
    final result = await _recordingRepository.playRecording(filePath);
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isPlaying: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(isPlaying: true);
      },
    );
  }

  Future<void> pausePlayback() async {
    final result = await _recordingRepository.pausePlayback();
    
    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (_) {
        state = state.copyWith(isPlaying: false, isPlaybackPaused: true);
      },
    );
  }

  Future<void> stopPlayback() async {
    final result = await _recordingRepository.stopPlayback();
    
    result.fold(
      (failure) {
        state = state.copyWith(errorMessage: failure.message);
      },
      (_) {
        state = state.copyWith(isPlaying: false, isPlaybackPaused: false);
      },
    );
  }

  Future<void> deleteRecording(String id) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _recordingRepository.deleteRecording(id);
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        final updatedRecordings = state.recordings.where((r) => r.id != id).toList();
        state = state.copyWith(
          isLoading: false,
          recordings: updatedRecordings,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _recordingRepository.dispose();
    super.dispose();
  }
}

class RecordingState {
  final List<VoiceRecording> recordings;
  final bool isRecording;
  final bool isPaused;
  final bool isPlaying;
  final bool isPlaybackPaused;
  final bool isLoading;
  final String? errorMessage;

  const RecordingState({
    this.recordings = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.isPlaying = false,
    this.isPlaybackPaused = false,
    this.isLoading = false,
    this.errorMessage,
  });

  RecordingState copyWith({
    List<VoiceRecording>? recordings,
    bool? isRecording,
    bool? isPaused,
    bool? isPlaying,
    bool? isPlaybackPaused,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RecordingState(
      recordings: recordings ?? this.recordings,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      isPlaying: isPlaying ?? this.isPlaying,
      isPlaybackPaused: isPlaybackPaused ?? this.isPlaybackPaused,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
