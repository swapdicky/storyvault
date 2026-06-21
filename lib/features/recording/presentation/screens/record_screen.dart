import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/presentation/widgets/bottom_navigation.dart';
import '../providers/recording_providers.dart';

class RecordScreen extends ConsumerWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(isRecordingProvider);
    final isPaused = ref.watch(isPausedProvider);
    final recordings = ref.watch(recordingsProvider);
    final errorMessage = ref.watch(recordingErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record'),
      ),
      body: Column(
        children: [
          // Recording Controls Section
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRecording ? Icons.fiber_manual_record : Icons.mic,
                    size: 80,
                    color: isRecording 
                        ? Colors.red 
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isRecording 
                        ? (isPaused ? 'Recording Paused' : 'Recording...')
                        : 'Record Your Story',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isRecording)
                        IconButton(
                          onPressed: () {
                            if (isPaused) {
                              ref.read(recordingNotifierProvider.notifier).resumeRecording();
                            } else {
                              ref.read(recordingNotifierProvider.notifier).pauseRecording();
                            }
                          },
                          icon: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 48,
                          ),
                        ),
                      const SizedBox(width: 16),
                      FloatingActionButton(
                        onPressed: () {
                          if (isRecording) {
                            ref.read(recordingNotifierProvider.notifier).stopRecording();
                          } else {
                            ref.read(recordingNotifierProvider.notifier).startRecording();
                          }
                        },
                        child: Icon(
                          isRecording ? Icons.stop : Icons.mic,
                        ),
                        mini: false,
                        backgroundColor: isRecording ? Colors.red : null,
                      ),
                      const SizedBox(width: 16),
                      if (isRecording)
                        IconButton(
                          onPressed: () {
                            ref.read(recordingNotifierProvider.notifier).stopRecording();
                          },
                          icon: const Icon(
                            Icons.stop,
                            size: 48,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Recordings List Section
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Recordings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: recordings.isEmpty
                        ? Center(
                            child: Text(
                              'No recordings yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: recordings.length,
                            itemBuilder: (context, index) {
                              final recording = recordings[index];
                              return RecordingListItem(
                                recording: recording,
                                onPlay: () {
                                  ref.read(recordingNotifierProvider.notifier).playRecording(recording.filePath);
                                },
                                onDelete: () {
                                  ref.read(recordingNotifierProvider.notifier).deleteRecording(recording.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(),
    );
  }
}

class RecordingListItem extends ConsumerWidget {
  final dynamic recording;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.audio_file),
        ),
        title: Text(
          recording.fileName,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${recording.duration}s • ${_formatDate(recording.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onPlay,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
