enum ProfileDataSource { local, hosted }

class BrowserProfileSummary {
  const BrowserProfileSummary({
    required this.id,
    required this.name,
    required this.browser,
    required this.version,
    required this.releaseType,
    required this.tags,
    required this.source,
    this.proxyId,
    this.vpnId,
    this.processId,
    this.lastLaunch,
    this.groupId,
    this.note,
    this.syncMode,
    this.lastSync,
    this.hostOs,
    this.proxyBypassRules = const [],
    this.createdById,
    this.createdByEmail,
    this.isRunning = false,
    this.sourcePrefix,
  });

  final String id;
  final String name;
  final String browser;
  final String version;
  final String releaseType;
  final List<String> tags;
  final ProfileDataSource source;
  final String? proxyId;
  final String? vpnId;
  final int? processId;
  final int? lastLaunch;
  final String? groupId;
  final String? note;
  final String? syncMode;
  final int? lastSync;
  final String? hostOs;
  final List<String> proxyBypassRules;
  final String? createdById;
  final String? createdByEmail;
  final bool isRunning;
  final String? sourcePrefix;

  factory BrowserProfileSummary.fromLocalJson(Map<String, dynamic> json) {
    return BrowserProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed profile',
      browser: json['browser'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '',
      releaseType: json['release_type'] as String? ?? 'stable',
      proxyId: json['proxy_id'] as String?,
      processId: json['process_id'] as int?,
      lastLaunch: json['last_launch'] as int?,
      groupId: json['group_id'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      proxyBypassRules:
          (json['proxy_bypass_rules'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(),
      isRunning: json['is_running'] as bool? ?? false,
      source: ProfileDataSource.local,
    );
  }

  factory BrowserProfileSummary.fromHostedJson(Map<String, dynamic> json) {
    return BrowserProfileSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed profile',
      browser: json['browser'] as String? ?? 'unknown',
      version: json['version'] as String? ?? '',
      releaseType: json['releaseType'] as String? ?? 'stable',
      proxyId: json['proxyId'] as String?,
      vpnId: json['vpnId'] as String?,
      processId: json['processId'] as int?,
      lastLaunch: json['lastLaunch'] as int?,
      groupId: json['groupId'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      note: json['note'] as String?,
      syncMode: json['syncMode'] as String?,
      lastSync: json['lastSync'] as int?,
      hostOs: json['hostOs'] as String?,
      proxyBypassRules: (json['proxyBypassRules'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      createdById: json['createdById'] as String?,
      createdByEmail: json['createdByEmail'] as String?,
      isRunning: json['isRunning'] as bool? ?? false,
      sourcePrefix: json['sourcePrefix'] as String?,
      source: ProfileDataSource.hosted,
    );
  }

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return name.toLowerCase().contains(normalized) ||
        browser.toLowerCase().contains(normalized) ||
        version.toLowerCase().contains(normalized) ||
        releaseType.toLowerCase().contains(normalized) ||
        tags.any((tag) => tag.toLowerCase().contains(normalized)) ||
        (groupId?.toLowerCase().contains(normalized) ?? false) ||
        (note?.toLowerCase().contains(normalized) ?? false) ||
        (createdByEmail?.toLowerCase().contains(normalized) ?? false);
  }

  String get sourceLabel => switch (source) {
    ProfileDataSource.local => 'Local',
    ProfileDataSource.hosted => 'Hosted',
  };

  int get activityTimestamp => lastSync ?? lastLaunch ?? 0;
}
