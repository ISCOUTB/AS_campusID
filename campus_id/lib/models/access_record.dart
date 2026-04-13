class AccessRecord {
  final String type;
  final DateTime time;
  final String status;

  const AccessRecord({
    required this.type,
    required this.time,
    required this.status,
  });
}