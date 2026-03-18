import 'package:flutter_test/flutter_test.dart';
import 'package:twitterbrowser_flutter/features/profiles/data/models/browser_profile_summary.dart';

void main() {
  test('profile query matching covers name, browser, and tags', () {
    const profile = BrowserProfileSummary(
      id: 'profile-1',
      name: 'Amanda Chase',
      browser: 'chromium',
      version: '138',
      releaseType: 'stable',
      tags: ['sales', 'macos'],
      source: ProfileDataSource.hosted,
    );

    expect(profile.matchesQuery('amanda'), isTrue);
    expect(profile.matchesQuery('chrom'), isTrue);
    expect(profile.matchesQuery('sales'), isTrue);
    expect(profile.matchesQuery('windows'), isFalse);
  });
}
