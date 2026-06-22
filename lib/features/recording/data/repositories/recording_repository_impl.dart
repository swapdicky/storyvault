import 'package:dartz/dartz.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart' as ap_interface;
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  final AudioPlayer _audioPlayer;
  final Uuid _uuid;
  final Record _audioRecorder;
  RecorderController? _recorderController;

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Function()? _onPlaybackComplete;

  RecordingRepositoryImpl({
    AudioPlayer? audioPlayer,
    Uuid? uuid,
    RecorderController? recorderController,
    Record? audioRecorder,
  })  : _audioPlayer = audioPlayer ?? AudioPlayer(),
        _uuid = uuid ?? const Uuid(),
        _recorderController = recorderController,
        _audioRecorder = audioRecorder ?? Record() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _onPlaybackComplete?.call();
    });
  }

  void setRecorderController(RecorderController controller) {
    _recorderController = controller;
  }

  @override
  Future<Either<Failure, void>> startRecording() async {
    try {
      // Request microphone permission (only on mobile platforms)
      if (Platform.isIOS || Platform.isAndroid) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          return const Left(PermissionFailure('Microphone permission denied'));
        }
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

      // Use audio_waveforms on mobile, record package on desktop
      if (Platform.isIOS || Platform.isAndroid) {
        if (_recorderController == null) {
          return const Left(UnknownFailure('Recorder controller not set'));
        }
        await _recorderController!.record(path: filePath);
      } else {
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );
      }

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
      if (Platform.isIOS || Platform.isAndroid) {
        if (_recorderController == null) {
          return const Left(UnknownFailure('Recorder controller not set'));
        }
        await _recorderController!.pause();
      } else {
        await _audioRecorder.pause();
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resumeRecording() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        if (_recorderController == null) {
          return const Left(UnknownFailure('Recorder controller not set'));
        }
        await _recorderController!.record();
      } else {
        await _audioRecorder.resume();
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoiceRecording>> stopRecording() async {
    try {
      String? path;

      if (Platform.isIOS || Platform.isAndroid) {
        if (_recorderController == null) {
          return const Left(UnknownFailure('Recorder controller not set'));
        }
        path = await _recorderController!.stop();
      } else {
        path = await _audioRecorder.stop();
      }

      if (path == null) {
        return const Left(UnknownFailure('Failed to stop recording'));
      }

      final file = File(path);
      if (!await file.exists()) {
        return const Left(UnknownFailure('Recording file not found'));
      }

      final fileSize = await file.length();
      final duration = DateTime.now().difference(_recordingStartTime ?? DateTime.now()).inSeconds;

      // Auto-generate default title using date/time
      final now = DateTime.now();
      final defaultTitle = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final recording = VoiceRecording(
        id: _uuid.v4(),
        filePath: path,
        fileName: file.path.split('/').last,
        title: defaultTitle,
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
      // Use UrlSource for remote URLs, DeviceFileSource for local files
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(filePath));
      } else {
        await _audioPlayer.play(DeviceFileSource(filePath));
      }
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  void setOnPlaybackComplete(void Function()? callback) {
    _onPlaybackComplete = callback;
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
    if (Platform.isIOS || Platform.isAndroid) {
      return _recorderController?.isRecording ?? false;
    } else {
      return await _audioRecorder.isRecording();
    }
  }

  @override
  Future<bool> isPlaying() async {
    return _audioPlayer.state == ap_interface.PlayerState.playing;
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
    if (Platform.isIOS || Platform.isAndroid) {
      _recorderController?.dispose();
    }
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
