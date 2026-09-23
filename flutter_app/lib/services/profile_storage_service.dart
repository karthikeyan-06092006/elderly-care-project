import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

/// Persists the patient's profile photo in app-private storage so the picture
/// survives logout and re-login. Photos are keyed by user id.
class ProfileStorageService {
  ProfileStorageService._();

  static String _sanitize(String id) {
    return id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  static String _fileNameFor(String userId) {
    return 'profile_photo_${_sanitize(userId)}.jpg';
  }

  static Future<File> _targetFileFor(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}${_fileNameFor(userId)}');
  }

  /// Copies [source] into app documents storage and returns the durable path.
  static Future<String?> savePhotoForUser({
    required String userId,
    required File source,
  }) async {
    try {
      final target = await _targetFileFor(userId);
      await target.writeAsBytes(await source.readAsBytes(), flush: true);
      debugPrint('[ProfileStorageService] Saved photo to ${target.path}');
      return target.path;
    } catch (e) {
      debugPrint('[ProfileStorageService] Save failed: $e');
      return null;
    }
  }

  /// Returns the stored photo path for [userId] if it still exists on disk.
  static Future<String?> loadPhotoPathForUser(String userId) async {
    try {
      final file = await _targetFileFor(userId);
      return await file.exists() ? file.path : null;
    } catch (e) {
      debugPrint('[ProfileStorageService] Load failed: $e');
      return null;
    }
  }

  /// Removes the stored photo for [userId] from disk.
  static Future<void> deletePhotoForUser(String userId) async {
    try {
      final file = await _targetFileFor(userId);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[ProfileStorageService] Deleted photo for $userId');
      }
    } catch (e) {
      debugPrint('[ProfileStorageService] Delete failed: $e');
    }
  }

  /// Applies any persisted profile photo onto [profile].
  static Future<PatientProfile> hydrateProfile(PatientProfile profile) async {
    final id = profile.userId.isNotEmpty ? profile.userId : profile.email;
    final path = await loadPhotoPathForUser(id);
    if (path != null) {
      return profile.copyWith(photoPath: path);
    }
    return profile;
  }
}