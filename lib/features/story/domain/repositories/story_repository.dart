import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../entities/story.dart';

abstract class StoryRepository {
  Future<Either<Failure, Story>> uploadStory({
    required String userId,
    required String localFilePath,
    required int duration,
    String? title,
    String? transcript,
  });

  Future<Either<Failure, List<Story>>> getUserStories(String userId);

  Future<Either<Failure, String>> getSignedUrl(String audioPath);

  Future<Either<Failure, void>> deleteStory(String storyId);
}
