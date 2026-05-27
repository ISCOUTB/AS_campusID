import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/access_record.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;
  static const String avatarBucket = 'avatars';

  static Future<UserModel?> getUserByEmail(String email) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;

    return UserModel(
      name: response['full_name'] as String,
      code: response['code'] as String,
      program: response['program'] as String,
      email: response['email'] as String,
      avatarUrl: response['avatar_url'] as String?,
      role: response['role'] == 'student'
          ? UserRole.student
          : UserRole.authenticator,
    );
  }

  static Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
    required String userCode,
  }) async {
    final sanitizedName = fileName.replaceAll(' ', '_');
    final path =
        '$userCode/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';

    await client.storage.from(avatarBucket).uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    final publicUrl = client.storage.from(avatarBucket).getPublicUrl(path);
    return publicUrl;
  }

  static Future<void> registerStudent({
    required String name,
    required String code,
    required String program,
    required String email,
    String? avatarUrl,
  }) async {
    final existingByEmail = await client
        .from('profiles')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    if (existingByEmail != null) {
      throw Exception('Ya existe un usuario con ese correo');
    }

    final existingByCode = await client
        .from('profiles')
        .select('code')
        .eq('code', code)
        .maybeSingle();

    if (existingByCode != null) {
      throw Exception('Ya existe un usuario con ese código');
    }

    await client.from('profiles').insert({
      'full_name': name,
      'code': code,
      'program': program,
      'email': email,
      'avatar_url': avatarUrl,
      'role': 'student',
      'is_active': true,
    });

    await client.from('student_status').upsert({
      'student_code': code,
      'is_inside': false,
    });
  }

  static Future<void> registerAuthenticator({
    required String name,
    required String code,
    required String area,
    required String email,
    String? avatarUrl,
  }) async {
    final existingByEmail = await client
        .from('profiles')
        .select('email')
        .eq('email', email)
        .maybeSingle();

    if (existingByEmail != null) {
      throw Exception('Ya existe un usuario con ese correo');
    }

    final existingByCode = await client
        .from('profiles')
        .select('code')
        .eq('code', code)
        .maybeSingle();

    if (existingByCode != null) {
      throw Exception('Ya existe un usuario con ese código');
    }

    await client.from('profiles').insert({
      'full_name': name,
      'code': code,
      'program': area,
      'email': email,
      'avatar_url': avatarUrl,
      'role': 'authenticator',
      'is_active': true,
    });
  }

  static Future<bool> isProfileActive(String studentCode) async {
    final response = await client
        .from('profiles')
        .select('is_active')
        .eq('code', studentCode)
        .maybeSingle();

    if (response == null) return false;
    return response['is_active'] as bool? ?? false;
  }

  static Future<bool> isStudentInside(String studentCode) async {
    final response = await client
        .from('student_status')
        .select()
        .eq('student_code', studentCode)
        .maybeSingle();

    if (response == null) return false;
    return response['is_inside'] as bool? ?? false;
  }

  static Stream<bool> studentInsideStream(String studentCode) {
    return client
        .from('student_status')
        .stream(primaryKey: ['student_code'])
        .eq('student_code', studentCode)
        .map((rows) {
          if (rows.isEmpty) return false;
          return rows.first['is_inside'] as bool? ?? false;
        });
  }

  static Future<List<AccessRecord>> getAccessLogs(String studentCode) async {
    final response = await client
        .from('access_logs')
        .select()
        .eq('student_code', studentCode)
        .order('access_time', ascending: false);

    return (response as List)
        .map(
          (item) => AccessRecord(
            type: item['access_type'] as String,
            time: DateTime.parse(item['access_time'] as String).toLocal(),
            status: item['status'] as String,
            studentName: item['student_name'] as String,
            studentCode: item['student_code'] as String,
            authenticatedBy: item['authenticated_by'] as String,
          ),
        )
        .toList();
  }

  static Stream<List<AccessRecord>> accessLogsStream(String studentCode) {
    return client
        .from('access_logs')
        .stream(primaryKey: ['id'])
        .eq('student_code', studentCode)
        .map((rows) {
          final records = rows
              .map(
                (item) => AccessRecord(
                  type: item['access_type'] as String,
                  time: DateTime.parse(item['access_time'] as String).toLocal(),
                  status: item['status'] as String,
                  studentName: item['student_name'] as String,
                  studentCode: item['student_code'] as String,
                  authenticatedBy: item['authenticated_by'] as String,
                ),
              )
              .toList();

          records.sort((a, b) => b.time.compareTo(a.time));
          return records;
        });
  }

  static Stream<List<AccessRecord>> authenticatorLogsStream(
    String authenticatorName,
  ) {
    return client
        .from('access_logs')
        .stream(primaryKey: ['id'])
        .eq('authenticated_by', authenticatorName)
        .map((rows) {
          final records = rows
              .map(
                (item) => AccessRecord(
                  type: item['access_type'] as String,
                  time: DateTime.parse(item['access_time'] as String).toLocal(),
                  status: item['status'] as String,
                  studentName: item['student_name'] as String,
                  studentCode: item['student_code'] as String,
                  authenticatedBy: item['authenticated_by'] as String,
                ),
              )
              .toList();

          records.sort((a, b) => b.time.compareTo(a.time));
          return records;
        });
  }

  static Future<AccessRecord> processAccessQr({
    required String studentName,
    required String studentCode,
    required String authenticatedBy,
    required String qrToken,
    required int qrIssuedAt,
  }) async {
    try {
      final response = await client.rpc(
        'process_access_qr',
        params: {
          'p_student_name': studentName,
          'p_student_code': studentCode,
          'p_authenticated_by': authenticatedBy,
          'p_qr_token': qrToken,
          'p_qr_issued_at': qrIssuedAt,
        },
      );

      final row = (response as List).first;

      return AccessRecord(
        type: row['access_type'] as String,
        time: DateTime.parse(row['access_time'] as String).toLocal(),
        status: row['status'] as String,
        studentName: row['student_name'] as String,
        studentCode: row['student_code'] as String,
        authenticatedBy: row['authenticated_by'] as String,
      );
    } on PostgrestException catch (e) {
      throw Exception(e.message);
    } catch (_) {
      throw Exception('No fue posible procesar el QR');
    }
  }

  static Future<AccessRecord> registerScan({
    required String studentName,
    required String studentCode,
    required String authenticatedBy,
  }) async {
    final currentInside = await isStudentInside(studentCode);
    final nextType = currentInside ? 'Salida' : 'Entrada';
    final now = DateTime.now().toIso8601String();

    await client.from('access_logs').insert({
      'access_type': nextType,
      'access_time': now,
      'status': 'Permitido',
      'student_name': studentName,
      'student_code': studentCode,
      'authenticated_by': authenticatedBy,
    });

    await client.from('student_status').upsert({
      'student_code': studentCode,
      'is_inside': !currentInside,
    });

    return AccessRecord(
      type: nextType,
      time: DateTime.parse(now).toLocal(),
      status: 'Permitido',
      studentName: studentName,
      studentCode: studentCode,
      authenticatedBy: authenticatedBy,
    );
  }
}