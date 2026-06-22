import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/supabase_config.dart';

class OllamaService {
  final String endpoint;
  final String model;

  OllamaService({
    this.endpoint = OllamaConfig.endpoint,
    this.model = OllamaConfig.model,
  });

  /// Generate title suggestions from transcript using Ollama
  Future<Either<Failure, List<String>>> generateTitleSuggestions(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': '''Generate 3-5 short, descriptive titles for this personal story transcript. Return only the titles, one per line, without any additional text or numbering.

Transcript:
$transcript

Titles:''',
          'stream': false,
          'options': {
            'temperature': 0.7,
            'num_predict': 150,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['response'] as String;
        final titles = content
            .split('\n')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

        return Right(titles);
      } else {
        return Left(UnknownFailure('Ollama API error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(UnknownFailure('Title generation failed: ${e.toString()}'));
    }
  }

  /// Generate tags from transcript using Ollama
  Future<Either<Failure, List<String>>> generateTags(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': model,
          'prompt': '''Extract only concrete keywords from this story transcript.

Rules:
- 3 to 6 tags maximum
- Single words or short phrases
- Use names, people, places, activities, events
- Avoid abstract concepts
- Avoid emotional labels
- Output only keywords, one per line

Transcript:
$transcript

Keywords:''',
          'stream': false,
          'options': {
            'temperature': 0.7,
            'num_predict': 100,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['response'] as String;
        final tags = content
            .split('\n')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .take(6)
            .toList();

        return Right(tags);
      } else {
        return Left(UnknownFailure('Ollama API error: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(UnknownFailure('Tag generation failed: ${e.toString()}'));
    }
  }
}
