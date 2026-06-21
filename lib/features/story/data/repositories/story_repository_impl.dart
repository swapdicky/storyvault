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

      // Get public URL
      final audioPath = _supabase.storage.from('recordings').getPublicUrl(storagePath);

      // Insert metadata into database
      final response = await _supabase.from('stories').insert({
        'user_id': userId,
        'title': title,
        'audio_path': audioPath,
        'duration': duration,
      }).select().single();

      final story = Story(
        id: response['id'],
        userId: response['user_id'],
        title: response['title'],
        audioPath: response['audio_path'],
        duration: response['duration'],
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
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
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final stories = response.map<Story>((data) {
        return Story(
          id: data['id'],
          userId: data['user_id'],
          title: data['title'],
          audioPath: data['audio_path'],
          duration: data['duration'],
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
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
      // Extract storage path from public URL
      final uri = Uri.parse(audioPath);
      final pathParts = uri.pathSegments;
      final storagePath = pathParts.skip(1).join('/');

      final signedUrl = await _supabase.storage
          .from('recordings')
          .createSignedUrl(storagePath, 3600); // 1 hour expiry

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

      // Extract storage path from public URL
      final uri = Uri.parse(audioPath);
      final pathParts = uri.pathSegments;
      final storagePath = pathParts.skip(1).join('/');

      // Delete from storage
      await _supabase.storage.from('recordings').remove([storagePath]);

      // Delete from database
      await _supabase.from('stories').delete().eq('id', storyId);

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
