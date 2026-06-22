import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../data/repositories/recording_repository_impl.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/entities/recording.dart';
import '../notifiers/recording_notifier.dart';
import '../../../story/data/repositories/story_repository_impl.dart';
import '../../../story/domain/repositories/story_repository.dart';

// Recorder Controller Provider
final recorderControllerProvider = Provider<RecorderController>((ref) {
  final controller = RecorderController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Recording Repository Provider
final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepositoryImpl(
    recorderController: ref.watch(recorderControllerProvider),
  );
});

// Story Repository Provider
final storyRepositoryForRecordingProvider = Provider<StoryRepository>((ref) {
  return StoryRepositoryImpl();
});

// Recording Notifier Provider
final recordingNotifierProvider = StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(
    ref.watch(recordingRepositoryProvider),
    ref.watch(storyRepositoryForRecordingProvider),
    ref,
  );
});

// Convenience providers
final recordingsProvider = Provider<List<VoiceRecording>>((ref) {
  return ref.watch(recordingNotifierProvider).recordings;
});

final isRecordingProvider = Provider<bool>((ref) {
  return ref.watch(recordingNotifierProvider).isRecording;
});

final isPausedProvider = Provider<bool>((ref) {
  return ref.watch(recordingNotifierProvider).isPaused;
});

final currentPlayingPathProvider = Provider<String?>((ref) {
  return ref.watch(recordingNotifierProvider).currentPlayingPath;
});

final isPlaybackPausedProvider = Provider<bool>((ref) {
  return ref.watch(recordingNotifierProvider).isPlaybackPaused;
});

final recordingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(recordingNotifierProvider).isLoading;
});

final recordingErrorProvider = Provider<String?>((ref) {
  return ref.watch(recordingNotifierProvider).errorMessage;
});

final uploadingRecordingIdsProvider = Provider<Set<String>>((ref) {
  return ref.watch(recordingNotifierProvider).uploadingRecordingIds;
});
