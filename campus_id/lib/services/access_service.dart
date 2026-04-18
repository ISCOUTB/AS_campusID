import 'package:flutter/foundation.dart';
import '../models/access_record.dart';

class AccessService {
  static final ValueNotifier<List<AccessRecord>> recordsNotifier =
      ValueNotifier<List<AccessRecord>>([]);

  static final Map<String, bool> _insideCampusByStudent = {};

  static List<AccessRecord> get records => List.unmodifiable(recordsNotifier.value);

  static bool isStudentInside(String studentCode) {
    return _insideCampusByStudent[studentCode] ?? false;
  }

  static String nextActionLabel(String studentCode) {
    return isStudentInside(studentCode) ? 'Salida' : 'Entrada';
  }

  static AccessRecord registerScan({
    required String studentName,
    required String studentCode,
    required String authenticatedBy,
  }) {
    final now = DateTime.now();
    final isInside = _insideCampusByStudent[studentCode] ?? false;

    late AccessRecord record;

    if (!isInside) {
      record = AccessRecord(
        type: 'Entrada',
        time: now,
        status: 'Permitido',
        studentName: studentName,
        studentCode: studentCode,
        authenticatedBy: authenticatedBy,
      );
      _insideCampusByStudent[studentCode] = true;
    } else {
      record = AccessRecord(
        type: 'Salida',
        time: now,
        status: 'Permitido',
        studentName: studentName,
        studentCode: studentCode,
        authenticatedBy: authenticatedBy,
      );
      _insideCampusByStudent[studentCode] = false;
    }

    recordsNotifier.value = [record, ...recordsNotifier.value];
    return record;
  }

  static void clearRecords() {
    recordsNotifier.value = [];
    _insideCampusByStudent.clear();
  }
}