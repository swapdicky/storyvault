import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recording_repository_impl.dart';
import '../../domain/repositories/recording_repository.dart';
import '../../domain/entities/recording.dart';
import '../notifiers/recording_notifier.dart';

// Recording Repository Provider
final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepositoryImpl();
});

// Recording Notifier Provider
final recordingNotifierProvider = StateNotifierProvider<RecordingNotifier, RecordingState>((ref) {
  return RecordingNotifier(ref.watch(recordingRepositoryProvider));
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

final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(recordingNotifierProvider).isPlaying;
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
