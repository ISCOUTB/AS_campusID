import 'dart:math';

class QrService {
  static const int validitySeconds = 30;
  static final Random _random = Random.secure();

  static String generateQrData({
    required String studentCode,
    required String studentName,
  }) {
    final issuedAt = DateTime.now().millisecondsSinceEpoch;
    final token = _generateToken(studentCode, issuedAt);

    return '$studentCode|$studentName|$issuedAt|$token';
  }

  static Map<String, String>? parseQrData(String qrData) {
    final parts = qrData.split('|');

    if (parts.length != 4) return null;

    return {
      'studentCode': parts[0],
      'studentName': parts[1],
      'issuedAt': parts[2],
      'token': parts[3],
    };
  }

  static bool isQrExpired(String issuedAtString) {
    final issuedAt = int.tryParse(issuedAtString);
    if (issuedAt == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return now - issuedAt > validitySeconds * 1000;
  }

  static int remainingSeconds(String issuedAtString) {
    final issuedAt = int.tryParse(issuedAtString);
    if (issuedAt == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = (issuedAt + validitySeconds * 1000) - now;

    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  static String _generateToken(String studentCode, int issuedAt) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final randomPart = List.generate(
      10,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();

    return '$studentCode-$issuedAt-$randomPart';
  }
}