import 'package:dartz/dartz.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  final Record _audioRecorder;
  final AudioPlayer _audioPlayer;
  final Uuid _uuid;

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  RecordingRepositoryImpl({
    Record? audioRecorder,
    AudioPlayer? audioPlayer,
    Uuid? uuid,
  })  : _audioRecorder = audioRecorder ?? Record(),
        _audioPlayer = audioPlayer ?? AudioPlayer(),
        _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, void>> startRecording() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return const Left(PermissionFailure('Microphone permission denied'));
      }

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Generate unique filename
      final fileName = 'recording_${_uuid.v4()}.m4a';
      final filePath = '${recordingsDir.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      _currentRecordingPath = filePath;
      _recordingStartTime = DateTime.now();

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pauseRecording() async {
    try {
      await _audioRecorder.pause();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resumeRecording() async {
    try {
      await _audioRecorder.resume();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoiceRecording>> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path == null) {
        return const Left(UnknownFailure('Failed to stop recording'));
      }

      final file = File(path);
      if (!await file.exists()) {
        return const Left(UnknownFailure('Recording file not found'));
      }

      final fileSize = await file.length();
      final duration = DateTime.now().difference(_recordingStartTime ?? DateTime.now()).inSeconds;

      final recording = VoiceRecording(
        id: _uuid.v4(),
        filePath: path,
        fileName: file.path.split('/').last,
        duration: duration,
        createdAt: DateTime.now(),
        fileSize: fileSize,
      );

      _currentRecordingPath = null;
      _recordingStartTime = null;

      return Right(recording);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VoiceRecording>>> getRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      
      if (!await recordingsDir.exists()) {
        return const Right([]);
      }

      final files = await recordingsDir.list().toList();
      final recordings = <VoiceRecording>[];

      for (var file in files) {
        if (file is File && file.path.endsWith('.m4a')) {
          final stat = await file.stat();
          final fileSize = await file.length();
          
          // Extract duration from filename or use file stats
          final duration = 0; // Will be updated when we implement duration tracking
          
          recordings.add(VoiceRecording(
            id: _uuid.v4(),
            filePath: file.path,
            fileName: file.path.split('/').last,
            duration: duration,
            createdAt: stat.modified,
            fileSize: fileSize,
          ));
        }
      }

      // Sort by creation date, newest first
      recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(recordings);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecording(String id) async {
    try {
      final result = await getRecordings();
      
      return result.fold(
        (failure) => Left(failure),
        (recordings) async {
          final recording = recordings.firstWhere(
            (r) => r.id == id,
            orElse: () => throw Exception('Recording not found'),
          );
          
          final file = File(recording.filePath);
          if (await file.exists()) {
            await file.delete();
          }
          
          return const Right(null);
        },
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> playRecording(String filePath) async {
    try {
      await _audioPlayer.play(DeviceFileSource(filePath));
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  @override
  Future<bool> isPlaying() async {
    return _audioPlayer.state == PlayerState.playing;
  }

  @override
  Stream<Duration>? get recordingDuration {
    // TODO: Implement recording duration tracking
    return null;
  }

  @override
  Stream<Duration>? get playbackPosition {
    return _audioPlayer.onPositionChanged;
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
