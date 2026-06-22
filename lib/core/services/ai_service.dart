import 'package:openai/openai.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

class AIService {
  final OpenAI _openAI;

  AIService({required String apiKey})
      : _openAI = OpenAI(
          apiKey: apiKey,
          baseUrl: 'https://api.openai.com/v1',
        );

  /// Transcribe audio file using Whisper
  Future<Either<Failure, String>> transcribeAudio(String audioFilePath) async {
    try {
      final transcription = await _openAI.audio.transcriptions.create(
        file: audioFilePath,
        model: Model(id: 'whisper-1'),
        responseFormat: TranscriptionResponseFormat.json,
      );

      return Right(transcription.text);
    } catch (e) {
      return Left(UnknownFailure('Transcription failed: ${e.toString()}'));
    }
  }

  /// Generate title suggestions from transcript
  Future<Either<Failure, List<String>>> generateTitleSuggestions(String transcript) async {
    try {
      final completion = await _openAI.chat.completions.create(
        model: Model(id: 'gpt-3.5-turbo'),
        messages: [
          ChatMessage.system(
            content: 'You are a helpful assistant that generates engaging titles for personal stories. Generate 3-5 short, descriptive titles based on the transcript. Return only the titles, one per line.',
          ),
          ChatMessage.user(content: transcript),
        ],
        temperature: 0.7,
        maxTokens: 150,
      );

      final content = completion.choices.first.message.content ?? '';
      final titles = content.split('\n').where((t) => t.trim().isNotEmpty).toList();

      return Right(titles);
    } catch (e) {
      return Left(UnknownFailure('Title generation failed: ${e.toString()}'));
    }
  }

  /// Generate tags from transcript
  Future<Either<Failure, List<String>>> generateTags(String transcript) async {
    try {
      final completion = await _openAI.chat.completions.create(
        model: Model(id: 'gpt-3.5-turbo'),
        messages: [
          ChatMessage.system(
            content: 'You are a helpful assistant that generates relevant tags for personal stories. Generate 3-8 tags based on the transcript. Tags should be short, descriptive, and start with #. Return only the tags, one per line.',
          ),
          ChatMessage.user(content: transcript),
        ],
        temperature: 0.7,
        maxTokens: 100,
      );

      final content = completion.choices.first.message.content ?? '';
      final tags = content.split('\n').where((t) => t.trim().isNotEmpty).toList();

      return Right(tags);
    } catch (e) {
      return Left(UnknownFailure('Tag generation failed: ${e.toString()}'));
    }
  }
}
