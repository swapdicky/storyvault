import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../../../../shared/presentation/widgets/bottom_navigation.dart';
import '../providers/recording_providers.dart';
import '../../../story/presentation/providers/story_providers.dart';
import '../../../story/presentation/screens/ai_metadata_screen.dart';
import '../../../auth/presentation/providers/auth_providers.dart' show currentUserIdProvider;

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  late final RecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = RecorderController();

    // Load recordings and stories after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(storyNotifierProvider.notifier).loadUserStories(userId);
      }
    });
  }

  @override
  void dispose() {
    _recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final isPaused = ref.watch(isPausedProvider);
    final stories = ref.watch(storiesProvider);
    final recordings = ref.watch(recordingsProvider);
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRecording ? Icons.fiber_manual_record : Icons.mic,
                    size: 64,
                    color: isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  if (isRecording)
                    SizedBox(
                      height: 50,
                      child: AudioWaveforms(
                        size: Size(MediaQuery.of(context).size.width - 100, 50),
                        recorderController: _recorderController,
                        waveStyle: const WaveStyle(
                          waveColor: Colors.red,
                          extendWaveform: true,
                          showMiddleLine: false,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    isRecording
                        ? (isPaused ? 'Recording Paused' : 'Recording...')
                        : 'Record Your Story',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
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
                              size: 36,
                            ),
                          ),
                        const SizedBox(width: 12),
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
                            size: 28,
                          ),
                          mini: true,
                          backgroundColor: isRecording ? Colors.red : null,
                        ),
                        const SizedBox(width: 12),
                        if (isRecording)
                          IconButton(
                            onPressed: () {
                              ref.read(recordingNotifierProvider.notifier).stopRecording();
                            },
                            icon: const Icon(
                              Icons.stop,
                              size: 36,
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
                    child: recordings.isEmpty && stories.isEmpty
                        ? Center(
                            child: Text(
                              'No stories yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          )
                        : _buildGroupedList(context, recordings, stories, ref),
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

  void _showTitleDialog(BuildContext context, String recordingId) {
    final recording = ref.read(recordingNotifierProvider).recordings.firstWhere((r) => r.id == recordingId);
    final now = DateTime.now();
    final defaultTitle = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIMetadataScreen(
          audioFilePath: recording.filePath,
          defaultTitle: defaultTitle,
          onConfirm: (title, tags, transcript) {
            ref.read(recordingNotifierProvider.notifier).uploadRecording(
              recordingId,
              title,
              transcript: transcript,
              tags: tags,
            );
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildGroupedList(BuildContext context, List recordings, List stories, WidgetRef ref) {
    // Combine and sort all items by date (newest first)
    final allItems = <Map<String, dynamic>>[];

    for (var recording in recordings) {
      allItems.add({
        'type': 'recording',
        'data': recording,
        'date': recording.createdAt,
      });
    }

    for (var story in stories) {
      allItems.add({
        'type': 'story',
        'data': story,
        'date': story.createdAt,
      });
    }

    allItems.sort((a, b) => b['date'].compareTo(a['date']));

    // Group by date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <Map<String, dynamic>>[];
    final yesterdayItems = <Map<String, dynamic>>[];
    final earlierItems = <Map<String, dynamic>>[];

    for (var item in allItems) {
      final itemDate = DateTime(item['date'].year, item['date'].month, item['date'].day);
      if (itemDate == today) {
        todayItems.add(item);
      } else if (itemDate == yesterday) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    return ListView(
      children: [
        if (todayItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Today'),
          ...todayItems.map((item) => _buildListItem(context, item, ref)),
        ],
        if (yesterdayItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Yesterday'),
          ...yesterdayItems.map((item) => _buildListItem(context, item, ref)),
        ],
        if (earlierItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'Earlier'),
          ...earlierItems.map((item) => _buildListItem(context, item, ref)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> item, WidgetRef ref) {
    if (item['type'] == 'recording') {
      final recording = item['data'];
      return RecordingListItem(
        recording: recording,
        onPlay: () {
          final currentPlayingPath = ref.read(currentPlayingPathProvider);
          if (currentPlayingPath == recording.filePath) {
            ref.read(recordingNotifierProvider.notifier).stopPlayback();
          } else {
            ref.read(recordingNotifierProvider.notifier).playRecording(recording.filePath);
          }
        },
        onUpload: () {
          _showTitleDialog(context, recording.id);
        },
        onDelete: () {
          ref.read(recordingNotifierProvider.notifier).deleteRecording(recording.id);
        },
        isUploading: ref.watch(storyUploadingProvider),
      );
    } else {
      final story = item['data'];
      return StoryListItem(
        story: story,
        onPlay: () async {
          final currentPlayingPath = ref.read(currentPlayingPathProvider);
          if (currentPlayingPath == story.audioPath) {
            ref.read(recordingNotifierProvider.notifier).stopPlayback();
          } else {
            final signedUrl = await ref.read(storyNotifierProvider.notifier).getSignedUrl(story.audioPath);
            if (signedUrl != null) {
              ref.read(recordingNotifierProvider.notifier).playRecording(signedUrl, identifier: story.audioPath);
            }
          }
        },
        onDelete: () {
          ref.read(storyNotifierProvider.notifier).deleteStory(story.id);
        },
      );
    }
  }
}

class RecordingListItem extends ConsumerWidget {
  final dynamic recording;
  final VoidCallback onPlay;
  final VoidCallback onUpload;
  final VoidCallback onDelete;
  final bool isUploading;

  const RecordingListItem({
    super.key,
    required this.recording,
    required this.onPlay,
    required this.onUpload,
    required this.onDelete,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlayingPath = ref.watch(currentPlayingPathProvider);
    final isPlaying = currentPlayingPath == recording.filePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recording.title ?? 'New Recording',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.graphic_eq, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatSecondsToDuration(recording.duration),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(recording.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUploading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      onPressed: onUpload,
                      tooltip: 'Upload to cloud',
                      visualDensity: VisualDensity.compact,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSecondsToDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordingDate = DateTime(date.year, date.month, date.day);

    if (recordingDate == today) {
      return 'Today';
    } else if (recordingDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
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
    final isDeleting = ref.watch(storyDeletingProvider);
    final currentPlayingPath = ref.watch(currentPlayingPathProvider);
    final isPlaying = currentPlayingPath == story.audioPath;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title ?? 'Untitled Story',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.graphic_eq, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(story.duration),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(story.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: isDeleting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                onPressed: isDeleting ? null : onDelete,
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
