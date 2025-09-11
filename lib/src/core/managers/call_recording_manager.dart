import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../config/sensitive_config.dart';
import 'cloud_storage_manager.dart';

/// Call recording manager with cloud storage integration
class CallRecordingManager {
  static const String TAG = 'CallRecordingManager';

  final AudioRecorder _audioRecorder = AudioRecorder();
  final StreamController<CallRecordingState> _stateController =
      StreamController<CallRecordingState>.broadcast();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  CallRecordingState _currentState = CallRecordingState.idle;

  // WebRTC streams for recording
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isWebRTCRecording = false;

  // Recording configuration
  final CallRecordingConfig _config;

  // Cloud storage manager
  final CloudStorageManager _cloudStorage;

  CallRecordingManager({
    required SensitiveConfig sensitiveConfig,
    CallRecordingConfig? config,
  }) : _config = config ?? CallRecordingConfig.defaultConfig(),
       _cloudStorage = CloudStorageManager(
         projectName: sensitiveConfig.firebaseProjectId,
         storageBucket: sensitiveConfig.firebaseStorageBucket,
       );

  /// Stream to monitor recording state
  Stream<CallRecordingState> get stateStream => _stateController.stream;

  /// Current recording state
  CallRecordingState get currentState => _currentState;

  /// Whether recording is currently active
  bool get isRecording => _currentState == CallRecordingState.recording;

  /// Current recording file path
  String? get currentRecordingPath => _currentRecordingPath;

  /// Current recording duration
  Duration get recordingDuration =>
      _recordingStartTime != null 
        ? DateTime.now().difference(_recordingStartTime!) 
        : Duration.zero;

  /// Set local audio stream
  void setLocalStream(MediaStream stream) {
    _localStream = stream;
  }

  /// Set remote audio stream
  void setRemoteStream(MediaStream stream) {
    _remoteStream = stream;
  }

  /// Start call recording
  Future<bool> startRecording({
    String? orderId,
    String? customFileName,
  }) async {
    try {
      if (kDebugMode) {
        print('$TAG: Starting recording...');
      }

      // Check permissions
      if (!await _checkPermissions()) {
        if (kDebugMode) {
          print('$TAG: Recording permission denied');
        }
        _updateState(CallRecordingState.permissionDenied);
        return false;
      }

      // Generate file path
      final filePath = await _generateFilePath(orderId, customFileName);
      if (filePath == null) {
        if (kDebugMode) {
          print('$TAG: Failed to generate file path');
        }
        _updateState(CallRecordingState.error);
        return false;
      }

      // Start recording with optimized settings
      await _audioRecorder.start(
        RecordConfig(
          encoder: _config.audioEncoder,
          bitRate: _config.bitRate,
          sampleRate: _config.sampleRate,
          numChannels: _config.numChannels,
          autoGain: true,
          echoCancel: false, // Disable to record both sides
          noiseSuppress: false, // Disable for clearer recording
        ),
        path: filePath,
      );

      _isWebRTCRecording = (_localStream != null && _remoteStream != null);

      _currentRecordingPath = filePath;
      _recordingStartTime = DateTime.now();
      _updateState(CallRecordingState.recording);

      // Start duration monitoring
      _startDurationMonitoring();

      if (kDebugMode) {
        final recordingType = _isWebRTCRecording ? 'Enhanced WebRTC' : 'Standard';
        print('$TAG: ✅ $recordingType recording started: $filePath');
      }
      return true;
    } catch (e) {
      print('$TAG: ❌ Error starting recording: $e');
      _updateState(CallRecordingState.error);
      return false;
    }
  }

  /// Stop recording and upload to cloud
  Future<CloudUploadResult?> stopRecording() async {
    try {
      if (!isRecording) {
        print('$TAG: ⚠️ No active recording to stop');
        return null;
      }

      print('$TAG: Stopping recording...');
      _updateState(CallRecordingState.stopping);

      // Stop recording
      final path = await _audioRecorder.stop();
      final localFilePath = path ?? _currentRecordingPath!;

      // Stop duration monitoring
      _recordingTimer?.cancel();
      _recordingTimer = null;

      final duration = recordingDuration;

      if (kDebugMode) {
        print('$TAG: ✅ Recording saved locally: $localFilePath');
        print('$TAG: Duration: ${_formatDuration(duration)}');
      }

      // Upload to cloud automatically
      CloudUploadResult? uploadResult;
      try {
        _updateState(CallRecordingState.uploading);

        final orderId = _extractOrderIdFromPath(localFilePath);
        uploadResult = await _cloudStorage.uploadCallRecording(
          localFilePath: localFilePath,
          orderId: orderId ?? 'unknown',
        );

        if (uploadResult.success) {
          if (kDebugMode) {
            print('$TAG: ☁️ Recording uploaded successfully');
            print('$TAG: Cloud path: ${uploadResult.cloudPath}');
          }

          // Delete local file after successful upload
          await _deleteLocalFileAfterUpload(localFilePath);

          _updateState(CallRecordingState.completed);
        } else {
          if (kDebugMode) {
            print('$TAG: ⚠️ Failed to upload recording: ${uploadResult.error}');
          }
          _updateState(CallRecordingState.uploadFailed);
        }
      } catch (e) {
        if (kDebugMode) {
          print('$TAG: ❌ Error uploading recording: $e');
        }
        _updateState(CallRecordingState.uploadFailed);
        uploadResult = CloudUploadResult(
          success: false,
          error: e.toString(),
          orderId: _extractOrderIdFromPath(localFilePath) ?? 'unknown',
        );
      }

      // Create recording info
      final recordingInfo = CallRecordingInfo(
        filePath: localFilePath,
        duration: duration,
        startTime: _recordingStartTime!,
        endTime: DateTime.now(),
        fileSize: await _getFileSize(localFilePath),
        cloudPath: uploadResult.cloudPath,
        downloadUrl: uploadResult.downloadUrl,
      );

      // Save recording info
      await _saveRecordingInfo(recordingInfo);

      return uploadResult;
    } catch (e) {
      print('$TAG: ❌ Error stopping recording: $e');
      _updateState(CallRecordingState.error);
      return null;
    } finally {
      _currentRecordingPath = null;
      _recordingStartTime = null;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (!isRecording) return;

      print('$TAG: Cancelling recording...');

      // Stop recording
      await _audioRecorder.stop();
      _recordingTimer?.cancel();

      // Delete recorded file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('$TAG: Deleted cancelled recording file');
        }
      }

      _updateState(CallRecordingState.cancelled);
    } catch (e) {
      print('$TAG: ❌ Error cancelling recording: $e');
      _updateState(CallRecordingState.error);
    } finally {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingTimer = null;
    }
  }

  /// Check recording permissions
  Future<bool> _checkPermissions() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      print('$TAG: Error checking permissions: $e');
      return false;
    }
  }

  /// Generate recording file path
  Future<String?> _generateFilePath(String? orderId, String? customFileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/call_recordings');

      // Create recordings directory if it doesn't exist
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Generate file name
      final fileName = customFileName ?? _generateFileName(orderId);
      final filePath = '${recordingsDir.path}/$fileName';

      return filePath;
    } catch (e) {
      print('$TAG: Error generating file path: $e');
      return null;
    }
  }

  /// Generate unique file name
  String _generateFileName(String? orderId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final orderPrefix = orderId != null ? 'order_${orderId}_' : 'order_unknown_';
    return '${orderPrefix}call_$timestamp.${_config.fileExtension}';
  }

  /// Start duration monitoring
  void _startDurationMonitoring() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isRecording) {
        timer.cancel();
        return;
      }

      final duration = recordingDuration;

      // Check maximum duration
      if (_config.maxDuration != null && duration >= _config.maxDuration!) {
        if (kDebugMode) {
          print('$TAG: Recording reached maximum duration: ${_formatDuration(_config.maxDuration!)}');
        }
        stopRecording();
        return;
      }

      // Update state
      if (!_stateController.isClosed) {
        _stateController.add(CallRecordingState.recording);
      }
    });
  }

  /// Save recording information
  Future<void> _saveRecordingInfo(CallRecordingInfo info) async {
    try {
      // Can save to local database or JSON file
      print('$TAG: Saving recording info: ${info.toJson()}');
    } catch (e) {
      print('$TAG: Error saving recording info: $e');
    }
  }

  /// Get file size
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Update recording state
  void _updateState(CallRecordingState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get all saved recordings
  Future<List<FileSystemEntity>> getSavedRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/call_recordings');

      if (await recordingsDir.exists()) {
        return recordingsDir
            .listSync()
            .where((entity) => entity is File && entity.path.endsWith('.${_config.fileExtension}'))
            .toList();
      }
      return [];
    } catch (e) {
      print('$TAG: Error getting recordings: $e');
      return [];
    }
  }

  /// Delete specific recording
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('$TAG: Deleted recording: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('$TAG: Error deleting recording: $e');
      return false;
    }
  }

  /// Extract order ID from file path
  String? _extractOrderIdFromPath(String filePath) {
    try {
      final fileName = filePath.split('/').last;
      final regex = RegExp(r'order_(\d+)_');
      final match = regex.firstMatch(fileName);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// Delete local file after successful upload
  Future<void> _deleteLocalFileAfterUpload(String localFilePath) async {
    try {
      final file = File(localFilePath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('$TAG: 🗑️ Deleted local file after upload: $localFilePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('$TAG: ⚠️ Failed to delete local file: $e');
      }
    }
  }

  /// Upload existing recording to cloud
  Future<CloudUploadResult?> uploadExistingRecording(String localFilePath) async {
    try {
      final orderId = _extractOrderIdFromPath(localFilePath) ?? 'unknown';

      final result = await _cloudStorage.uploadCallRecording(
        localFilePath: localFilePath,
        orderId: orderId,
      );

      if (result.success) {
        await _deleteLocalFileAfterUpload(localFilePath);
      }

      return result;
    } catch (e) {
      print('$TAG: ❌ Failed to upload existing recording: $e');
      return null;
    }
  }

  /// Get cloud recordings for specific order
  Future<List<CloudRecordingInfo>> getCloudRecordings(String orderId) async {
    try {
      return await _cloudStorage.getOrderRecordings(orderId);
    } catch (e) {
      print('$TAG: ❌ Failed to get cloud recordings: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _stateController.close();
  }
}

/// Call recording states
enum CallRecordingState {
  idle,
  preparing,
  recording,
  stopping,
  uploading,
  completed,
  cancelled,
  error,
  permissionDenied,
  uploadFailed,
}

/// Call recording configuration
class CallRecordingConfig {
  final AudioEncoder audioEncoder;
  final int bitRate;
  final int sampleRate;
  final int numChannels;
  final Duration? maxDuration;
  final String fileExtension;
  final bool autoStart;
  final bool requirePermission;

  const CallRecordingConfig({
    this.audioEncoder = AudioEncoder.aacLc,
    this.bitRate = 128000,
    this.sampleRate = 44100,
    this.numChannels = 1,
    this.maxDuration,
    this.fileExtension = 'aac',
    this.autoStart = false,
    this.requirePermission = true,
  });

  /// Default configuration
  static CallRecordingConfig defaultConfig() {
    return const CallRecordingConfig(
      audioEncoder: AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 16000,
      numChannels: 1,
      maxDuration: Duration(minutes: 10), // Default 10 minutes
      fileExtension: 'aac',
      autoStart: false,
      requirePermission: true,
    );
  }

  /// High quality configuration
  static CallRecordingConfig highQualityConfig() {
    return const CallRecordingConfig(
      audioEncoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 2,
      maxDuration: Duration(minutes: 10),
      fileExtension: 'aac',
      autoStart: false,
      requirePermission: true,
    );
  }

  /// Compact configuration
  static CallRecordingConfig compactConfig() {
    return const CallRecordingConfig(
      audioEncoder: AudioEncoder.opus,
      bitRate: 32000,
      sampleRate: 16000,
      numChannels: 1,
      maxDuration: Duration(minutes: 10),
      fileExtension: 'opus',
      autoStart: false,
      requirePermission: true,
    );
  }
}

/// Recording information
class CallRecordingInfo {
  final String filePath;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final int fileSize;
  final String? cloudPath;
  final String? downloadUrl;

  CallRecordingInfo({
    required this.filePath,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.fileSize,
    this.cloudPath,
    this.downloadUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'fileSize': fileSize,
      'cloudPath': cloudPath,
      'downloadUrl': downloadUrl,
    };
  }

  factory CallRecordingInfo.fromJson(Map<String, dynamic> json) {
    return CallRecordingInfo(
      filePath: json['filePath'],
      duration: Duration(milliseconds: json['duration']),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      fileSize: json['fileSize'],
      cloudPath: json['cloudPath'],
      downloadUrl: json['downloadUrl'],
    );
  }

  /// Format file size for display
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format duration for display
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}