import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/presentation/widgets/bottom_navigation.dart';
import '../providers/recording_providers.dart';
import '../../../story/presentation/providers/story_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  @override
  void initState() {
    super.initState();
    // Load user stories from cloud
    final userId = ref.read(currentUserIdProvider);
    if (userId != null) {
      ref.read(storyNotifierProvider.notifier).loadUserStories(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final isPaused = ref.watch(isPausedProvider);
    final stories = ref.watch(storiesProvider);
    final isUploading = ref.watch(storyUploadingProvider);
    final errorMessage = ref.watch(recordingErrorProvider) ?? ref.watch(storyErrorProvider);

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
                  if (isUploading)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Uploading to cloud...'),
                      ],
                    )
                  else
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
                          onPressed: isUploading ? null : () {
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
                    child: stories.isEmpty
                        ? Center(
                            child: Text(
                              'No stories yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: stories.length,
                            itemBuilder: (context, index) {
                              final story = stories[index];
                              return StoryListItem(
                                story: story,
                                onPlay: () {
                                  ref.read(recordingNotifierProvider.notifier).playRecording(story.audioPath);
                                },
                                onDelete: () {
                                  ref.read(storyNotifierProvider.notifier).deleteStory(story.id);
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

class StoryListItem extends ConsumerWidget {
  final dynamic story;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  const StoryListItem({
    super.key,
    required this.story,
    required this.onPlay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final isDeleting = ref.watch(storyDeletingProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.audio_file),
        ),
        title: Text(
          story.title ?? 'Untitled Story',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${story.duration}s • ${_formatDate(story.createdAt)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onPlay,
            ),
            IconButton(
              icon: isDeleting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete),
              onPressed: isDeleting ? null : onDelete,
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
