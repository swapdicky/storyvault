import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/constants/supabase_config.dart';

class AIMetadataScreen extends ConsumerStatefulWidget {
  final String audioFilePath;
  final String defaultTitle;
  final Function(String title, List<String> tags, String transcript) onConfirm;

  const AIMetadataScreen({
    super.key,
    required this.audioFilePath,
    required this.defaultTitle,
    required this.onConfirm,
  });

  @override
  ConsumerState<AIMetadataScreen> createState() => _AIMetadataScreenState();
}

class _AIMetadataScreenState extends ConsumerState<AIMetadataScreen> {
  bool _isGenerating = false;
  String? _transcript;
  List<String> _titleSuggestions = [];
  List<String> _tags = [];
  String _selectedTitle = '';
  List<String> _selectedTags = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedTitle = widget.defaultTitle;
    _generateMetadata();
  }

  Future<void> _generateMetadata() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final aiService = AIService(apiKey: OpenAIConfig.apiKey);

      // Transcribe audio
      final transcriptResult = await aiService.transcribeAudio(widget.audioFilePath);
      transcriptResult.fold(
        (failure) => setState(() => _error = failure.message),
        (transcript) {
          setState(() => _transcript = transcript);

          // Generate title suggestions
          aiService.generateTitleSuggestions(transcript).then((result) {
            result.fold(
              (failure) => setState(() => _error = failure.message),
              (titles) => setState(() => _titleSuggestions = titles),
            );
          });

          // Generate tags
          aiService.generateTags(transcript).then((result) {
            result.fold(
              (failure) => setState(() => _error = failure.message),
              (tags) => setState(() => _tags = tags),
            );
          });
        },
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Story Metadata'),
      ),
      body: _isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating metadata...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _generateMetadata,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transcript
                      if (_transcript != null) ...[
                        const Text(
                          'Transcript',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_transcript!),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Title Suggestions
                      if (_titleSuggestions.isNotEmpty) ...[
                        const Text(
                          'Title Suggestions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._titleSuggestions.map((title) => RadioListTile<String>(
                              title: Text(title),
                              value: title,
                              groupValue: _selectedTitle,
                              onChanged: (value) {
                                setState(() => _selectedTitle = value!);
                              },
                            )),
                        const SizedBox(height: 24),
                      ],

                      // Tags
                      if (_tags.isNotEmpty) ...[
                        const Text(
                          'Suggested Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _tags.map((tag) => FilterChip(
                                label: Text(tag),
                                selected: _selectedTags.contains(tag),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                },
                              )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _transcript != null
                              ? () => widget.onConfirm(
                                    _selectedTitle,
                                    _selectedTags,
                                    _transcript!,
                                  )
                              : null,
                          child: const Text('Confirm & Save'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
