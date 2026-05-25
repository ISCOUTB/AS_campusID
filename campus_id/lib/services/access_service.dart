import '../models/access_record.dart';
import 'supabase_service.dart';

class AccessService {
  static Future<List<AccessRecord>> getRecords(String studentCode) async {
    return await SupabaseService.getAccessLogs(studentCode);
  }

  static Stream<List<AccessRecord>> recordsStream(String studentCode) {
    return SupabaseService.accessLogsStream(studentCode);
  }

  static Future<bool> isStudentInside(String studentCode) async {
    return await SupabaseService.isStudentInside(studentCode);
  }

  static Stream<bool> studentInsideStream(String studentCode) {
    return SupabaseService.studentInsideStream(studentCode);
  }

  static Future<String> nextActionLabel(String studentCode) async {
    final isInside = await isStudentInside(studentCode);
    return isInside ? 'Salida' : 'Entrada';
  }

  static Stream<String> nextActionLabelStream(String studentCode) {
    return studentInsideStream(studentCode)
        .map((isInside) => isInside ? 'Salida' : 'Entrada');
  }

  static Future<AccessRecord> registerScan({
    required String studentName,
    required String studentCode,
    required String authenticatedBy,
  }) async {
    return await SupabaseService.registerScan(
      studentName: studentName,
      studentCode: studentCode,
      authenticatedBy: authenticatedBy,
    );
  }
}