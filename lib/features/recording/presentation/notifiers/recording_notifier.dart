import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../data/repositories/recording_repository_impl.dart';
import '../../../story/domain/repositories/story_repository.dart';
import '../../../story/presentation/providers/story_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show currentUserIdProvider, currentUserEmailProvider;

class RecordingNotifier extends StateNotifier<RecordingState> {
  final RecordingRepository _recordingRepository;
  final StoryRepository _storyRepository;
  final Ref _ref;

  RecordingNotifier(
    this._recordingRepository,
    this._storyRepository,
    this._ref,
  ) : super(const RecordingState()) {
    // Set up playback completion callback
    if (_recordingRepository is RecordingRepositoryImpl) {
      (_recordingRepository as RecordingRepositoryImpl).setOnPlaybackComplete(() {
        state = state.copyWith(currentPlayingPath: null);
      });
    }
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
      (recording) {
        // Don't auto-upload, let user provide title first
        // Hide recordings shorter than 1 second
        if (recording.duration >= 1) {
          // Prevent duplicate recordings by checking file path
          final isDuplicate = state.recordings.any((r) => r.filePath == recording.filePath);
          if (!isDuplicate) {
            final updatedRecordings = [recording, ...state.recordings];
            state = state.copyWith(
              isRecording: false,
              isPaused: false,
              isLoading: false,
              recordings: updatedRecordings,
            );
          } else {
            state = state.copyWith(
              isRecording: false,
              isPaused: false,
              isLoading: false,
            );
          }
        } else {
          state = state.copyWith(
            isRecording: false,
            isPaused: false,
            isLoading: false,
          );
        }
      },
    );
  }

  Future<void> playRecording(String filePath, {String? identifier}) async {
    // Stop any current playback before starting new one
    await stopPlayback();

    // Use identifier if provided, otherwise use filePath
    final playingIdentifier = identifier ?? filePath;

    state = state.copyWith(currentPlayingPath: playingIdentifier, errorMessage: null);

    final result = await _recordingRepository.playRecording(filePath);

    result.fold(
      (failure) {
        state = state.copyWith(
          currentPlayingPath: null,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = state.copyWith(currentPlayingPath: playingIdentifier);
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
        state = state.copyWith(currentPlayingPath: null, isPlaybackPaused: true);
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
        state = state.copyWith(currentPlayingPath: null, isPlaybackPaused: false);
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

  Future<void> uploadRecording(String recordingId, String title, {String? transcript, List<String>? tags}) async {
    final recording = state.recordings.firstWhere((r) => r.id == recordingId);

    // Mark recording as uploading
    state = state.copyWith(uploadingRecordingIds: {...state.uploadingRecordingIds, recordingId});

    // Update the recording with the title before uploading
    final updatedRecording = VoiceRecording(
      id: recording.id,
      filePath: recording.filePath,
      fileName: recording.fileName,
      title: title,
      duration: recording.duration,
      createdAt: recording.createdAt,
      fileSize: recording.fileSize,
    );

    final updatedRecordings = state.recordings.map((r) =>
      r.id == recordingId ? updatedRecording : r
    ).toList();
    state = state.copyWith(recordings: updatedRecordings);

    final userId = _ref.read(currentUserIdProvider);
    if (userId != null) {
      await _ref.read(storyNotifierProvider.notifier).uploadStory(
        userId: userId,
        localFilePath: recording.filePath,
        duration: recording.duration,
        title: title,
        transcript: transcript,
        tags: tags,
      );

      // Remove from local recordings after upload attempt
      final finalRecordings = state.recordings.where((r) => r.id != recordingId).toList();
      final finalUploadingIds = state.uploadingRecordingIds.where((id) => id != recordingId).toSet();
      state = state.copyWith(recordings: finalRecordings, uploadingRecordingIds: finalUploadingIds);
    } else {
      // Remove from uploading set if no user
      final finalUploadingIds = state.uploadingRecordingIds.where((id) => id != recordingId).toSet();
      state = state.copyWith(uploadingRecordingIds: finalUploadingIds);
    }
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
  final String? currentPlayingPath;
  final bool isPlaybackPaused;
  final bool isLoading;
  final String? errorMessage;
  final Set<String> uploadingRecordingIds;

  const RecordingState({
    this.recordings = const [],
    this.isRecording = false,
    this.isPaused = false,
    this.currentPlayingPath,
    this.isPlaybackPaused = false,
    this.isLoading = false,
    this.errorMessage,
    this.uploadingRecordingIds = const {},
  });

  RecordingState copyWith({
    List<VoiceRecording>? recordings,
    bool? isRecording,
    bool? isPaused,
    String? currentPlayingPath,
    bool? isPlaybackPaused,
    bool? isLoading,
    String? errorMessage,
    Set<String>? uploadingRecordingIds,
  }) {
    return RecordingState(
      recordings: recordings ?? this.recordings,
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      currentPlayingPath: currentPlayingPath ?? this.currentPlayingPath,
      isPlaybackPaused: isPlaybackPaused ?? this.isPlaybackPaused,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      uploadingRecordingIds: uploadingRecordingIds ?? this.uploadingRecordingIds,
    );
  }
}
