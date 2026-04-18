class QrService {
  static String generateQrData({
    required String studentCode,
    required String studentName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '$studentCode|$studentName|$now';
  }

  static Map<String, String>? parseQrData(String qrData) {
    final parts = qrData.split('|');

    if (parts.length != 3) return null;

    return {
      'studentCode': parts[0],
      'studentName': parts[1],
      'timestamp': parts[2],
    };
  }
}