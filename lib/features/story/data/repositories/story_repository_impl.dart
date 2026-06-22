import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../../core/error/failures.dart';
import '../../domain/entities/story.dart';
import '../../domain/repositories/story_repository.dart';

class StoryRepositoryImpl implements StoryRepository {
  final SupabaseClient _supabase;
  final Uuid _uuid;

  StoryRepositoryImpl({
    SupabaseClient? supabase,
    Uuid? uuid,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, Story>> uploadStory({
    required String userId,
    required String localFilePath,
    required int duration,
    String? title,
    String? transcript,
    List<String>? tags,
  }) async {
    try {
      final file = File(localFilePath);
      if (!await file.exists()) {
        return const Left(UnknownFailure('File not found'));
      }

      // Generate unique filename
      final fileName = '${_uuid.v4()}.m4a';
      final storagePath = '$userId/$fileName';

      // Upload to Supabase Storage
      final fileBytes = await file.readAsBytes();
      await _supabase.storage.from('recordings').uploadBinary(
        storagePath,
        fileBytes,
      );

      // Insert metadata into database with storage path
      final response = await _supabase.from('stories').insert({
        'user_id': userId,
        'title': title,
        'audio_path': storagePath,
        'duration': duration,
        'transcript': transcript,
      }).select().single();

      // Handle tags if provided
      if (tags != null && tags.isNotEmpty) {
        await _addTagsToStory(response['id'], tags);
      }

      final story = Story(
        id: response['id'],
        userId: response['user_id'],
        title: response['title'],
        audioPath: response['audio_path'],
        duration: response['duration'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        transcript: response['transcript'],
        tags: tags ?? [],
      );

      return Right(story);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Story>>> getUserStories(String userId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select('*, story_tags(tags(name))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final stories = response.map<Story>((data) {
        final tagNames = (data['story_tags'] as List<dynamic>?)
            ?.map((st) => st['tags'] as Map<String, dynamic>)
            .map((tag) => tag['name'] as String)
            .toList() ?? [];

        return Story(
          id: data['id'],
          userId: data['user_id'],
          title: data['title'],
          audioPath: data['audio_path'],
          duration: data['duration'],
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
          transcript: data['transcript'],
          tags: tagNames,
        );
      }).toList();

      return Right(stories);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getSignedUrl(String audioPath) async {
    try {
      // audioPath is now the storage path directly (e.g., "userId/filename.m4a")
      final signedUrl = await _supabase.storage
          .from('recordings')
          .createSignedUrl(audioPath, 3600); // 1 hour expiry

      return Right(signedUrl);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteStory(String storyId) async {
    try {
      // Get story details
      final response = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      final audioPath = response['audio_path'];

      // audioPath is now the storage path directly
      // Delete from storage
      await _supabase.storage.from('recordings').remove([audioPath]);

      // Delete from database
      await _supabase.from('stories').delete().eq('id', storyId);

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  Future<void> _addTagsToStory(String storyId, List<String> tagNames) async {
    for (final tagName in tagNames) {
      // Check if tag already exists
      final existingTag = await _supabase
          .from('tags')
          .select()
          .eq('name', tagName)
          .maybeSingle();

      String tagId;

      if (existingTag == null) {
        // Create new tag
        final newTag = await _supabase
            .from('tags')
            .insert({'name': tagName})
            .select()
            .single();
        tagId = newTag['id'];
      } else {
        tagId = existingTag['id'];
      }

      // Link tag to story
      await _supabase.from('story_tags').insert({
        'story_id': storyId,
        'tag_id': tagId,
      });
    }
  }
}
