import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Cloud storage manager for call recordings
class CloudStorageManager {
  static const String TAG = 'CloudStorageManager';

  late final FirebaseStorage _storage;

  // Folder structure in Firebase Storage (configurable)
  final String _projectName;
  final String _callRecordingsFolder;

  CloudStorageManager({
    required String projectName,
    String? storageBucket,
    String callRecordingsFolder = 'call_recordings',
    FirebaseStorage? storage,
  }) : _projectName = projectName,
       _callRecordingsFolder = callRecordingsFolder {
    // Use provided storage or default instance
    _storage = storage ?? FirebaseStorage.instance;
    
    // Configure storage bucket if provided
    if (storageBucket != null) {
      try {
        _storage.useStorageEmulator('localhost', 9199); // For testing
      } catch (e) {
        // Ignore emulator errors in tests
        if (kDebugMode) {
          print('$TAG: Storage emulator not available: $e');
        }
      }
    }
  }

  /// Upload call recording to Firebase Storage
  Future<CloudUploadResult> uploadCallRecording({
    required String localFilePath,
    String? orderId,
    String? customFileName,
  }) async {
    try {
      if (kDebugMode) {
        print('$TAG: Starting cloud upload...');
      }

      // Check if local file exists
      final localFile = File(localFilePath);
      if (!await localFile.exists()) {
        throw CloudStorageException('Local file not found: $localFilePath');
      }

      // Generate cloud path
      final cloudPath = _generateCloudPath(orderId ?? 'unknown', customFileName);

      // Create Firebase Storage reference
      final ref = _storage.ref().child(cloudPath);

      // Start upload with metadata
      final uploadTask = ref.putFile(
        localFile,
        SettableMetadata(
          contentType: 'audio/aac',
          customMetadata: {
            'orderId': orderId ?? 'unknown',
            'uploadTime': DateTime.now().toIso8601String(),
            'appVersion': 'voice_call_core_v1.0.0',
            'recordingType': 'voice_call',
          },
        ),
      );

      if (kDebugMode) {
        print('$TAG: Uploading to: $cloudPath');
      }

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        if (kDebugMode && progress % 25 == 0) {
          print('$TAG: Upload progress: ${progress.toStringAsFixed(1)}%');
        }
      });

      // Wait for upload completion
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Calculate upload info
      final fileSize = await localFile.length();
      final uploadResult = CloudUploadResult(
        success: true,
        cloudPath: cloudPath,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
        uploadTime: DateTime.now(),
        orderId: orderId ?? 'unknown',
      );

      if (kDebugMode) {
        print('$TAG: ✅ Recording uploaded successfully');
        print('$TAG: Path: $cloudPath');
        print('$TAG: Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }

      return uploadResult;
    } catch (e) {
      print('$TAG: ❌ Upload failed: $e');
      return CloudUploadResult(
        success: false,
        error: e.toString(),
        orderId: orderId ?? 'unknown',
      );
    }
  }

  /// Generate cloud file path
  /// Structure: projectName/call_recordings/orderId_date_time.aac
  String _generateCloudPath(String orderId, String? customFileName) {
    final now = DateTime.now();

    // Format date and time
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    // Create filename: orderId_day-month_hour-minute-second.aac
    final fileName = customFileName ?? '${orderId}_$day-${month}_$hour-$minute-$second.aac';

    // Build full path
    return '$_projectName/$_callRecordingsFolder/$fileName';
  }

  /// Delete recording from cloud
  Future<bool> deleteCloudRecording(String cloudPath) async {
    try {
      if (kDebugMode) {
        print('$TAG: Deleting cloud recording: $cloudPath');
      }

      final ref = _storage.ref().child(cloudPath);
      await ref.delete();

      if (kDebugMode) {
        print('$TAG: ✅ Cloud recording deleted');
      }

      return true;
    } catch (e) {
      print('$TAG: ❌ Failed to delete recording: $e');
      return false;
    }
  }

  /// Get recordings for specific order
  Future<List<CloudRecordingInfo>> getOrderRecordings(String orderId) async {
    try {
      final recordings = <CloudRecordingInfo>[];

      // Search in current year (can be expanded)
      final currentYear = DateTime.now().year.toString();
      final yearRef = _storage.ref().child('$_projectName/$_callRecordingsFolder/$currentYear');

      // Search in all months
      for (int month = 1; month <= 12; month++) {
        final monthStr = month.toString().padLeft(2, '0');
        final monthRef = yearRef.child(monthStr);

        try {
          final result = await monthRef.listAll();

          for (final item in result.items) {
            // Check if file contains order ID
            if (item.name.contains('${orderId}_')) {
              final metadata = await item.getMetadata();
              final downloadUrl = await item.getDownloadURL();

              recordings.add(
                CloudRecordingInfo(
                  name: item.name,
                  cloudPath: item.fullPath,
                  downloadUrl: downloadUrl,
                  fileSize: metadata.size ?? 0,
                  uploadTime: metadata.timeCreated ?? DateTime.now(),
                  orderId: orderId,
                ),
              );
            }
          }
        } catch (e) {
          // Ignore non-existent months
          continue;
        }
      }

      // Sort by upload time
      recordings.sort((a, b) => b.uploadTime.compareTo(a.uploadTime));

      return recordings;
    } catch (e) {
      print('$TAG: ❌ Failed to get order recordings: $e');
      return [];
    }
  }

  /// Get recordings by date range
  Future<List<CloudRecordingInfo>> getRecordingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final recordings = <CloudRecordingInfo>[];

      // Search in required years
      for (int year = startDate.year; year <= endDate.year; year++) {
        final yearRef = _storage.ref().child('$_projectName/$_callRecordingsFolder/$year');

        try {
          final yearResult = await yearRef.listAll();

          for (final monthRef in yearResult.prefixes) {
            final monthResult = await monthRef.listAll();

            for (final item in monthResult.items) {
              final metadata = await item.getMetadata();
              final uploadTime = metadata.timeCreated ?? DateTime.now();

              // Check if date is within range
              if (uploadTime.isAfter(startDate) && uploadTime.isBefore(endDate)) {
                final downloadUrl = await item.getDownloadURL();

                // Extract order ID from filename
                final orderId = _extractOrderIdFromFileName(item.name);

                recordings.add(
                  CloudRecordingInfo(
                    name: item.name,
                    cloudPath: item.fullPath,
                    downloadUrl: downloadUrl,
                    fileSize: metadata.size ?? 0,
                    uploadTime: uploadTime,
                    orderId: orderId ?? 'unknown',
                  ),
                );
              }
            }
          }
        } catch (e) {
          continue;
        }
      }

      return recordings;
    } catch (e) {
      print('$TAG: ❌ Failed to get recordings: $e');
      return [];
    }
  }

  /// Extract order ID from filename
  String? _extractOrderIdFromFileName(String fileName) {
    try {
      // Pattern: orderId_day-month_hour-minute-second.aac
      final regex = RegExp(r'^([^_]+)_');
      final match = regex.firstMatch(fileName);
      return match?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final rootRef = _storage.ref().child('$_projectName/$_callRecordingsFolder');

      int totalFiles = 0;
      int totalSize = 0;

      // Count files in current year
      final currentYear = DateTime.now().year.toString();
      final yearRef = rootRef.child(currentYear);

      try {
        final yearResult = await yearRef.listAll();

        for (final monthRef in yearResult.prefixes) {
          final monthResult = await monthRef.listAll();
          totalFiles += monthResult.items.length;

          for (final item in monthResult.items) {
            final metadata = await item.getMetadata();
            totalSize += metadata.size ?? 0;
          }
        }
      } catch (e) {
        // Year doesn't exist
      }

      return StorageStats(
        totalFiles: totalFiles,
        totalSize: totalSize,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('$TAG: ❌ Failed to get storage stats: $e');
      return StorageStats(
        totalFiles: 0,
        totalSize: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// Cloud upload result
class CloudUploadResult {
  final bool success;
  final String? cloudPath;
  final String? downloadUrl;
  final int? fileSize;
  final DateTime? uploadTime;
  final String? error;
  final String orderId;

  CloudUploadResult({
    required this.success,
    this.cloudPath,
    this.downloadUrl,
    this.fileSize,
    this.uploadTime,
    this.error,
    required this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'cloudPath': cloudPath,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'uploadTime': uploadTime?.toIso8601String(),
      'error': error,
      'orderId': orderId,
    };
  }
}

/// Cloud recording information
class CloudRecordingInfo {
  final String name;
  final String cloudPath;
  final String downloadUrl;
  final int fileSize;
  final DateTime uploadTime;
  final String? orderId;

  CloudRecordingInfo({
    required this.name,
    required this.cloudPath,
    required this.downloadUrl,
    required this.fileSize,
    required this.uploadTime,
    this.orderId,
  });

  /// Format file size
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Format upload time
  String get formattedUploadTime {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(uploadTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cloudPath': cloudPath,
      'downloadUrl': downloadUrl,
      'fileSize': fileSize,
      'uploadTime': uploadTime.toIso8601String(),
      'orderId': orderId,
    };
  }
}

/// Storage statistics
class StorageStats {
  final int totalFiles;
  final int totalSize;
  final DateTime lastUpdated;

  StorageStats({
    required this.totalFiles,
    required this.totalSize,
    required this.lastUpdated,
  });

  /// Format total size
  String get formattedTotalSize {
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    if (totalSize < 1024 * 1024 * 1024)
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Cloud storage exceptions
class CloudStorageException implements Exception {
  final String message;

  CloudStorageException(this.message);

  @override
  String toString() => 'CloudStorageException: $message';
}