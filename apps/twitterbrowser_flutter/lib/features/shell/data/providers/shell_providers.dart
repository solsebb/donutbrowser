import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CompanionDestination { profiles }

final companionDestinationProvider = StateProvider<CompanionDestination>((ref) {
  return CompanionDestination.profiles;
});

final sidebarExpandedProvider = StateProvider<bool>((ref) => true);
