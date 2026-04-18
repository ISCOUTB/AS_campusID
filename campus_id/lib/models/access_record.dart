class AccessRecord {
  final String type;
  final DateTime time;
  final String status;
  final String studentName;
  final String studentCode;
  final String authenticatedBy;

  const AccessRecord({
    required this.type,
    required this.time,
    required this.status,
    required this.studentName,
    required this.studentCode,
    required this.authenticatedBy,
  });
}