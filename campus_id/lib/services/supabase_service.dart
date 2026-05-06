import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/access_record.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<UserModel?> getUserByEmail(String email) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) return null;

    return UserModel(
      name: response['full_name'],
      code: response['code'],
      program: response['program'],
      email: response['email'],
      role: response['role'] == 'student'
          ? UserRole.student
          : UserRole.authenticator,
    );
  }

  static Future<bool> isStudentInside(String studentCode) async {
    final response = await client
        .from('student_status')
        .select()
        .eq('student_code', studentCode)
        .maybeSingle();

    if (response == null) return false;
    return response['is_inside'] ?? false;
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
            type: item['access_type'],
            time: DateTime.parse(item['access_time']),
            status: item['status'],
            studentName: item['student_name'],
            studentCode: item['student_code'],
            authenticatedBy: item['authenticated_by'],
          ),
        )
        .toList();
  }

  static Future<AccessRecord> registerScan({
    required String studentName,
    required String studentCode,
    required String authenticatedBy,
  }) async {
    final currentInside = await isStudentInside(studentCode);
    final nextType = currentInside ? 'Salida' : 'Entrada';

    await client.from('access_logs').insert({
      'access_type': nextType,
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
      time: DateTime.now(),
      status: 'Permitido',
      studentName: studentName,
      studentCode: studentCode,
      authenticatedBy: authenticatedBy,
    );
  }
}