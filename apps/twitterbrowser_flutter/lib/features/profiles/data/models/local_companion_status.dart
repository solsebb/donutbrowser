class LocalCompanionStatus {
  const LocalCompanionStatus({
    required this.port,
    required this.token,
    required this.baseUrl,
    required this.updatedAt,
    required this.filePath,
  });

  final int port;
  final String token;
  final String baseUrl;
  final String updatedAt;
  final String filePath;

  factory LocalCompanionStatus.fromJson(
    Map<String, dynamic> json, {
    required String filePath,
  }) {
    return LocalCompanionStatus(
      port: json['port'] as int,
      token: json['token'] as String,
      baseUrl: json['base_url'] as String,
      updatedAt: json['updated_at'] as String,
      filePath: filePath,
    );
  }
}
