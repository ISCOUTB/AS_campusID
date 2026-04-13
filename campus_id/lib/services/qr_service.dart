class QrService {
  static String generateQrData(String studentCode) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'campus_id|$studentCode|$now';
  }
}