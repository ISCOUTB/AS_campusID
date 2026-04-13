import '../models/access_record.dart';

class AccessService {
  static final List<AccessRecord> _records = [];
  static bool _insideCampus = false;

  static List<AccessRecord> get records => List.unmodifiable(_records);

  static AccessRecord registerScan() {
    final now = DateTime.now();

    if (!_insideCampus) {
      final entry = AccessRecord(
        type: 'Entrada',
        time: now,
        status: 'Permitido',
      );
      _records.insert(0, entry);
      _insideCampus = true;
      return entry;
    } else {
      final exit = AccessRecord(
        type: 'Salida',
        time: now,
        status: 'Permitido',
      );
      _records.insert(0, exit);
      _insideCampus = false;
      return exit;
    }
  }

  static bool get insideCampus => _insideCampus;
}