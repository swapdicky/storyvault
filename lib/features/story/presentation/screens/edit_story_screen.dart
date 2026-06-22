import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditStoryScreen extends ConsumerStatefulWidget {
  final String audioFilePath;
  final String defaultTitle;
  final Future<void> Function(String title, String transcript, String tags) onSave;

  const EditStoryScreen({
    super.key,
    required this.audioFilePath,
    required this.defaultTitle,
    required this.onSave,
  });

  @override
  ConsumerState<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends ConsumerState<EditStoryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _transcriptController;
  late TextEditingController _tagsController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
    _transcriptController = TextEditingController();
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _transcriptController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Story'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    setState(() => _isSaving = true);
                    try {
                      await widget.onSave(
                        _titleController.text.trim(),
                        _transcriptController.text.trim(),
                        _tagsController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      setState(() => _isSaving = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save failed: ${e.toString()}')),
                        );
                      }
                    }
                  },
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Enter story title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Transcript Field
            const Text(
              'Transcript',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _transcriptController,
              decoration: const InputDecoration(
                hintText: 'Enter transcript (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 10,
              minLines: 5,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),

            // Tags Field
            const Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: 'Enter tags separated by commas (e.g., family, beach, holiday)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            Text(
              'Tags help you organize and find your stories later.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
