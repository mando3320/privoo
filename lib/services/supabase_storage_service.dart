// lib/services/supabase_storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      await _supabase.storage.from(bucket).upload(path, file);
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      logger.i('✅ File uploaded: $url');
      return url;
    } catch (e) {
      logger.e('❌ Failed to upload file: $e');
      rethrow;
    }
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
      logger.i('✅ File deleted: $path');
    } catch (e) {
      logger.e('❌ Failed to delete file: $e');
      rethrow;
    }
  }

  Future<String> getPublicUrl({
    required String bucket,
    required String path,
  }) async {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }
}