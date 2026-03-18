import 'package:flutter/cupertino.dart';
import 'package:flutter_shared_core/utils/app_logger.dart';
import 'package:flutter/material.dart' show Colors, Border, Theme, Brightness;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crop settings that define what portion of the original image to show
/// All values are normalized (0-1) relative to the original image dimensions
/// NOTE: Copied from image_cropper_modal.dart to avoid feature dependency
class AvatarCropSettings {
  /// Left edge of the visible crop area (0 = left edge, 1 = right edge)
  final double cropX;

  /// Top edge of the visible crop area (0 = top edge, 1 = bottom edge)
  final double cropY;

  /// Width of the visible crop area as fraction of image width
  final double cropWidth;

  /// Height of the visible crop area as fraction of image height
  final double cropHeight;

  const AvatarCropSettings({
    this.cropX = 0.0,
    this.cropY = 0.0,
    this.cropWidth = 1.0,
    this.cropHeight = 1.0,
  });

  /// Default settings - show entire image
  static const AvatarCropSettings defaults = AvatarCropSettings();

  /// Create from JSON (database storage)
  factory AvatarCropSettings.fromJson(Map<String, dynamic> json) {
    return AvatarCropSettings(
      cropX: (json['cropX'] as num?)?.toDouble() ?? 0.0,
      cropY: (json['cropY'] as num?)?.toDouble() ?? 0.0,
      cropWidth: (json['cropWidth'] as num?)?.toDouble() ?? 1.0,
      cropHeight: (json['cropHeight'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() => {
        'cropX': cropX,
        'cropY': cropY,
        'cropWidth': cropWidth,
        'cropHeight': cropHeight,
      };

  @override
  String toString() =>
      'AvatarCropSettings(cropX: ${cropX.toStringAsFixed(3)}, cropY: ${cropY.toStringAsFixed(3)}, cropWidth: ${cropWidth.toStringAsFixed(3)}, cropHeight: ${cropHeight.toStringAsFixed(3)})';
}

// Static cache for avatar URLs to reduce database calls
class AvatarCache {
  static final Map<String, String?> _cache = {};
  static final Map<String, DateTime> _expiryTimes = {};
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Get cached avatar URL if valid
  static String? get(String userId) {
    final expiryTime = _expiryTimes[userId];
    if (expiryTime != null && DateTime.now().isBefore(expiryTime)) {
      final cachedUrl = _cache[userId];
      // Additional validation: ensure cached URL is not a processed_images URL
      if (cachedUrl != null && _isValidAvatarUrl(cachedUrl)) {
        return cachedUrl;
      } else {
        // Clear invalid cached URL
        AppLogger.log(
            'AvatarCache: Clearing invalid cached URL for user $userId: $cachedUrl');
        clear(userId);
        return null;
      }
    }
    // Expired or not in cache
    return null;
  }

  // Store avatar URL in cache with validation
  static void set(String userId, String? avatarUrl) {
    if (avatarUrl != null && !_isValidAvatarUrl(avatarUrl)) {
      AppLogger.log(
          'AvatarCache: Rejecting invalid avatar URL for user $userId: $avatarUrl');
      return;
    }
    _cache[userId] = avatarUrl;
    _expiryTimes[userId] = DateTime.now().add(_cacheDuration);
  }

  // Validate that the URL is appropriate for an avatar
  static bool _isValidAvatarUrl(String url) {
    if (url.contains('processed_images')) {
      AppLogger.log(
          'AvatarCache: Invalid avatar URL detected - contains processed_images: $url');
      return false;
    }
    return url.startsWith('http') &&
        !url.contains('null') &&
        url != 'null' &&
        url != 'undefined';
  }

  // Clear cache for a specific user
  static void clear(String userId) {
    _cache.remove(userId);
    _expiryTimes.remove(userId);
  }

  // Clear entire cache
  static void clearAll() {
    AppLogger.log('AvatarCache: Clearing all cached avatar URLs');
    _cache.clear();
    _expiryTimes.clear();
  }
}

class ProfileAvatar extends ConsumerStatefulWidget {
  final String? avatarUrl;
  final String? username;
  final String? url;
  final double size;
  final double? iconSize;
  final BorderRadius? borderRadius;
  final Border? border;
  final Color? backgroundColor;
  final bool useCache;
  final bool shouldLog;

  /// Twitter-style crop settings to apply when rendering
  /// If provided, the ORIGINAL image is displayed with crop transform applied
  final AvatarCropSettings? cropSettings;

  /// Hero mode for full-width profile pictures (komi.io/link.me style)
  /// When enabled, renders the image at heroWidth x heroHeight with no border radius
  final bool isHeroMode;
  final double? heroWidth;
  final double? heroHeight;

  // Track URLs that have been scheduled for cleanup to avoid duplicates
  static final Set<String> _cleanupScheduled = <String>{};

  // Track URLs that have failed to load to prevent continuous rebuild attempts
  static final Set<String> _failedUrls = <String>{};

  const ProfileAvatar({
    super.key,
    this.avatarUrl,
    this.url,
    this.username,
    this.size = 48,
    this.iconSize,
    this.borderRadius,
    this.border,
    this.backgroundColor,
    this.useCache = true,
    this.shouldLog = false,
    this.cropSettings,
    this.isHeroMode = false,
    this.heroWidth,
    this.heroHeight,
  });

  /// Force clear all avatar caches - useful when fixing stale data issues
  static void clearAllCaches() {
    AvatarCache.clearAll();
    _cleanupScheduled.clear();
    _failedUrls.clear();
  }

  /// Schedule cleanup of an invalid URL from the database
  /// This prevents repeated HTTP errors for the same bad URL
  static void _scheduleUrlCleanup(String invalidUrl) {
    // Don't spam cleanup requests - only clean up once per URL per session
    if (_cleanupScheduled.contains(invalidUrl)) return;
    _cleanupScheduled.add(invalidUrl);

    // Schedule cleanup after a short delay to avoid blocking the UI
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          AppLogger.log(
              'ProfileAvatar: Cleaning up invalid URL from database: $invalidUrl');

          // Clear from profiles table
          await Supabase.instance.client.from('profiles').update({
            'avatar_url': null,
            'updated_at': DateTime.now().toUtc().toIso8601String()
          }).eq('id', user.id);

          // Clear from auth metadata
          await Supabase.instance.client.auth
              .updateUser(UserAttributes(data: {'avatar_url': null}));

          // Clear local cache
          AvatarCache.clear(user.id);

          AppLogger.log(
              'ProfileAvatar: Successfully cleaned up invalid URL for user ${user.id}');
        }
      } catch (e) {
        AppLogger.log('ProfileAvatar: Error during URL cleanup: $e');
      }
    });
  }

  @override
  ConsumerState<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends ConsumerState<ProfileAvatar> {
  bool _isGoogleAvatarBlocked = false;
  bool _checkingDatabase = false;
  String? _customAvatarUrl;

  @override
  void initState() {
    super.initState();
    _checkAvatarStatus();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If avatar URL changed, re-check avatar status
    if (widget.avatarUrl != oldWidget.avatarUrl) {
      _checkAvatarStatus();
    }
  }

  Future<void> _checkAvatarStatus() async {
    // This method checks database for all URLs, not just Google URLs
    // We need to check database for any avatar to properly handle the case where
    // a user has uploaded a custom avatar

    // IMPORTANT: If avatarUrl is explicitly passed (e.g., from link in bio provider),
    // use it directly without querying database. This ensures link in bio profiles
    // show their own avatars instead of the main user's avatar.

    // CRITICAL FIX: For Supabase storage URLs (link in bio avatars), always use the passed URL
    // without querying the database, as these are scoped profile avatars
    if (widget.avatarUrl != null &&
        (widget.avatarUrl!.contains('supabase.co/storage') ||
         !widget.avatarUrl!.contains('googleusercontent.com'))) {
      if (mounted) {
        setState(() {
          _customAvatarUrl = widget.avatarUrl;
          _isGoogleAvatarBlocked = false;
        });
      }
      return;
    }

    // Avoid multiple simultaneous checks
    if (_checkingDatabase) return;
    _checkingDatabase = true;

    try {
      // Check current user
      final user = Supabase.instance.client.auth.currentUser;

      // Handle guest mode or unauthenticated state
      if (user == null) {
        if (mounted) {
          setState(() {
            // Clear any cached avatar URLs when in guest mode
            _isGoogleAvatarBlocked = false;
            _customAvatarUrl = null;
            AppLogger.log('Guest mode or unauthenticated - using default avatar');
          });
        }
        _checkingDatabase = false;
        return;
      }

      // Check if we have a cached avatar URL for this user
      final cachedAvatarUrl = AvatarCache.get(user.id);
      if (cachedAvatarUrl != null) {
        if (mounted) {
          setState(() {
            _customAvatarUrl = cachedAvatarUrl;
            final isGoogleAvatar =
                widget.avatarUrl?.contains('googleusercontent.com') ?? false;
            if (isGoogleAvatar && _customAvatarUrl != widget.avatarUrl) {
              _isGoogleAvatarBlocked = true;
            } else {
              _isGoogleAvatarBlocked = false;
            }
          });
        }
        _checkingDatabase = false;
        return;
      }

      // Not in cache, query the database
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      // Get avatar URL from database
      final dbAvatarUrl = profile?['avatar_url'] as String?;

      // CRITICAL FIX: Ignore OAuth provider URLs from database
      // These should never be stored in the database, but if they are, ignore them
      final bool isDbUrlOAuthProvider = dbAvatarUrl != null &&
          (dbAvatarUrl.contains('googleusercontent.com') ||
           dbAvatarUrl.contains('facebook.com') ||
           dbAvatarUrl.contains('twitter.com'));

      final effectiveDbUrl = isDbUrlOAuthProvider ? null : dbAvatarUrl;

      // Cache the result (even if null)
      AvatarCache.set(user.id, effectiveDbUrl);

      if (mounted) {
        setState(() {
          // If the widget URL is a Google avatar and the database avatar is NULL,
          // we should block the Google avatar
          final isGoogleAvatar =
              widget.avatarUrl?.contains('googleusercontent.com') ?? false;
          if (profile != null) {
            if (effectiveDbUrl == null && isGoogleAvatar) {
              _isGoogleAvatarBlocked = true;
              _customAvatarUrl = null;
            } else if (effectiveDbUrl != null) {
              // There's a custom avatar in the database - use it
              _customAvatarUrl = effectiveDbUrl;
              // If we have a custom avatar and widget shows Google URL, don't show Google
              if (isGoogleAvatar && _customAvatarUrl != widget.avatarUrl) {
                _isGoogleAvatarBlocked = true;
              } else {
                _isGoogleAvatarBlocked = false;
              }
            } else {
              _isGoogleAvatarBlocked = false;
              _customAvatarUrl = null;
            }
          }
        });
      }
    } catch (e) {
      AppLogger.log('Error checking database for avatar: $e');

      // Reset state on error to ensure we don't display incorrect avatar
      if (mounted) {
        setState(() {
          _isGoogleAvatarBlocked = false;
          _customAvatarUrl = null;
        });
      }
    } finally {
      _checkingDatabase = false;
    }
  }

  /// Build the avatar image widget with optional Twitter-style crop transform
  Widget _buildAvatarImage({
    required String? displayUrl,
    required int? timestamp,
    required BorderRadius effectiveBorderRadius,
    required bool isLightTheme,
    required double defaultIconSize,
  }) {
    final cropSettings = widget.cropSettings;
    // Crop is active if cropWidth or cropHeight is less than 1 (not showing full image)
    final hasCropSettings = cropSettings != null &&
        (cropSettings.cropWidth < 1.0 || cropSettings.cropHeight < 1.0);

    final imageUrl = timestamp != null ? '$displayUrl?t=$timestamp' : displayUrl!;
    final cacheKey = timestamp != null ? '$displayUrl?t=$timestamp' : null;

    // Error widget builder - shared between normal and cropped rendering
    Widget buildErrorWidget(String url, dynamic error) {
      // CRITICAL: Mark this URL as failed to prevent continuous rebuild attempts
      ProfileAvatar._failedUrls.add(url);

      // Enhanced error handling for different types of failures
      String errorType = 'Unknown';
      if (error.toString().contains('HttpException')) {
        if (error.toString().contains('400')) {
          errorType = 'HTTP 400 - Bad Request';
        } else if (error.toString().contains('404')) {
          errorType = 'HTTP 404 - Not Found';
        } else if (error.toString().contains('403')) {
          errorType = 'HTTP 403 - Forbidden';
        } else {
          errorType = 'HTTP Error';
        }
      } else if (error.toString().contains('SocketException')) {
        errorType = 'Network Error';
      } else if (error.toString().contains('EncodingError')) {
        errorType = 'Image Encoding Error';
      }

      // Only log once per URL to reduce noise
      AppLogger.log(
          'ProfileAvatar: Failed to load image from $url - Error Type: $errorType (marked as failed, will not retry)');

      // If this is an HTTP error (like 400/404), the URL is likely invalid
      // Schedule a cleanup of the URL from the database to prevent future errors
      // IMPORTANT: Don't cleanup OAuth provider URLs (Google, etc.) as they're expected to fail
      if (error.toString().contains('HttpException') &&
          url.contains('supabase.co/storage')) {
        ProfileAvatar._scheduleUrlCleanup(url);
      }

      // Return the default icon instead of showing an error
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              (isLightTheme
                  ? const Color(0xFFF2F2F7) // Light theme: light gray
                  : const Color(0xFF1C1C1E)), // Dark theme: dark gray
          borderRadius: effectiveBorderRadius,
          border: widget.border,
        ),
        child: Center(
          child: Icon(
            CupertinoIcons.person_fill,
            color: isLightTheme
                ? CupertinoColors.separator // Light theme: same as container border
                : CupertinoColors.systemGrey, // Dark theme: lighter gray
            size: defaultIconSize,
          ),
        ),
      );
    }

    // Apply Twitter-style crop transform if cropSettings is provided
    // Uses crop rectangle (cropX, cropY, cropWidth, cropHeight) in normalized 0-1 coordinates
    if (hasCropSettings) {
      // Twitter-style crop rendering using crop rectangle:
      // - cropX, cropY: top-left corner of crop region (0-1)
      // - cropWidth, cropHeight: size of crop region as fraction of image (0-1)
      //
      // Strategy:
      // 1. Scale image so crop region fills the container
      //    displayWidth = widget.size / cropWidth
      //    displayHeight = widget.size / cropHeight
      // 2. Position image so crop region's top-left is at container's top-left
      //    left = -cropX * displayWidth = -cropX / cropWidth * widget.size
      //    top = -cropY * displayHeight = -cropY / cropHeight * widget.size
      // 3. ClipRRect clips to container bounds

      final displayWidth = widget.size / cropSettings.cropWidth;
      final displayHeight = widget.size / cropSettings.cropHeight;
      final left = -cropSettings.cropX / cropSettings.cropWidth * widget.size;
      final top = -cropSettings.cropY / cropSettings.cropHeight * widget.size;

      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: left,
                top: top,
                width: displayWidth,
                height: displayHeight,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheKey: cacheKey,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 100),
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => buildErrorWidget(url, error),
                  memCacheHeight: 512,
                  httpHeaders: widget.useCache
                      ? null
                      : const {
                          'Cache-Control': 'no-cache, no-store, must-revalidate',
                          'Pragma': 'no-cache',
                          'Expires': '0',
                        },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No crop - standard image display
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 100),
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: const Duration(milliseconds: 50),
      placeholder: (context, url) => const CupertinoActivityIndicator(),
      errorWidget: (context, url, error) => buildErrorWidget(url, error),
      memCacheHeight: 512,
      httpHeaders: widget.useCache
          ? null
          : const {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme brightness from context instead of watching provider to avoid unnecessary rebuilds
    final brightness = Theme.of(context).brightness;
    final isLightTheme = brightness == Brightness.light;

    final defaultIconSize = widget.size * 0.6;

    // Only generate a timestamp for cache busting if not using cache
    final timestamp =
        widget.useCache ? null : DateTime.now().millisecondsSinceEpoch;

    // Determine which avatar URL to display
    String? displayUrl = widget.url ?? widget.avatarUrl;

    // If this is a Google avatar and we've confirmed it should be blocked
    // from the database, or there is a custom avatar available, use the custom avatar
    final bool isGoogleAvatar =
        displayUrl?.contains('googleusercontent.com') ?? false;

    if (isGoogleAvatar) {
      if (_isGoogleAvatarBlocked) {
        // Block Google avatar - either display custom or default
        displayUrl = _customAvatarUrl;
      }
    } else if (_customAvatarUrl != null) {
      // For non-Google URLs, prioritize custom avatar from database if available
      displayUrl = _customAvatarUrl;
    }

    // Critical validation: Reject processed_images URLs for avatars
    if (displayUrl != null && displayUrl.contains('processed_images')) {
      AppLogger.log(
          'ProfileAvatar: Rejecting processed_images URL for avatar: $displayUrl');
      displayUrl = null;
      // Clear the cache if it contains this invalid URL
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        AvatarCache.clear(user.id);
      }
    }

    // Enhanced avatar URL validation with more specific checks
    // CRITICAL: Skip URLs that have already failed to prevent continuous rebuild attempts
    final bool hasFailedPreviously = displayUrl != null && ProfileAvatar._failedUrls.contains(displayUrl);

    final bool hasValidAvatarUrl = displayUrl != null &&
        displayUrl.isNotEmpty &&
        !displayUrl.contains('null') &&
        displayUrl.startsWith('http') &&
        displayUrl != 'null' &&
        displayUrl != 'undefined' &&
        !displayUrl.contains('processed_images') && // Additional check
        !hasFailedPreviously; // Skip URLs that have failed before

    // Only log if explicitly enabled to reduce noise
    if (widget.shouldLog) {
      AppLogger.log(
          'Building ProfileAvatar with URL: ${hasValidAvatarUrl ? displayUrl : 'null or invalid'} (Google blocked: $isGoogleAvatar && $_isGoogleAvatarBlocked)');
    }

    // Hero mode: full width rendering with no border radius
    if (widget.isHeroMode && widget.heroWidth != null && widget.heroHeight != null) {
      return _buildHeroModeAvatar(
        displayUrl: displayUrl,
        hasValidAvatarUrl: hasValidAvatarUrl,
        timestamp: timestamp,
        isLightTheme: isLightTheme,
        defaultIconSize: defaultIconSize,
      );
    }

    // Calculate the correct border radius to use
    final effectiveBorderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.size / 2);

    // Extract border properties for our custom inside border
    final borderColor = widget.border?.top.color ?? Colors.transparent;
    final borderWidth = widget.border?.top.width ?? 0.0;
    const borderOpacity = 0.24; // 24% opacity as requested
    const borderWidthMultiplier = 0.8; // Reduce the thickness of the stroke

    // Create the base container
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // Background color (if no avatar or as a fallback)
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor ??
                  (isLightTheme
                      ? const Color(
                          0xFFF2F2F7) // Light theme: LIGHT gray background
                      : const Color(0xFF726C68)), // Dark theme: brownish gray
              borderRadius: effectiveBorderRadius,
              // Remove border from here since we'll apply it inside
            ),
          ),

          // Avatar image (if available)
          if (hasValidAvatarUrl)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: effectiveBorderRadius,
                child: _buildAvatarImage(
                  displayUrl: displayUrl,
                  timestamp: timestamp,
                  effectiveBorderRadius: effectiveBorderRadius,
                  isLightTheme: isLightTheme,
                  defaultIconSize: defaultIconSize,
                ),
              ),
            ),

          // Default avatar icon (always present but only visible if no valid avatar or error)
          if (!hasValidAvatarUrl)
            Positioned.fill(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/userProfile_Rounded_fill.svg',
                  width: widget.iconSize ?? defaultIconSize,
                  height: widget.iconSize ?? defaultIconSize,
                  colorFilter: ColorFilter.mode(
                    isLightTheme
                        ? CupertinoColors
                            .separator // Light theme: same as container border
                        : CupertinoColors.white, // Dark theme: white icon
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

          // Inside border with reduced opacity - only if border is provided
          if (widget.border != null)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: effectiveBorderRadius,
                  border: Border.all(
                    color: borderColor.withAlpha((borderOpacity * 255).toInt()),
                    width:
                        borderWidth * borderWidthMultiplier, // Reduce thickness
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build hero mode avatar - full width, no border radius (komi.io/link.me style)
  Widget _buildHeroModeAvatar({
    required String? displayUrl,
    required bool hasValidAvatarUrl,
    required int? timestamp,
    required bool isLightTheme,
    required double defaultIconSize,
  }) {
    final heroWidth = widget.heroWidth!;
    final heroHeight = widget.heroHeight!;
    final cropSettings = widget.cropSettings;

    // Build the image URL with cache busting if needed
    final imageUrl = timestamp != null && displayUrl != null
        ? '$displayUrl?t=$timestamp'
        : displayUrl;
    final cacheKey = timestamp != null && displayUrl != null
        ? '$displayUrl?t=$timestamp'
        : null;

    return SizedBox(
      width: heroWidth,
      height: heroHeight,
      child: Stack(
        children: [
          // Background color (fallback if no avatar)
          Container(
            width: heroWidth,
            height: heroHeight,
            color: widget.backgroundColor ??
                (isLightTheme
                    ? const Color(0xFFF2F2F7)
                    : const Color(0xFF726C68)),
          ),

          // Avatar image (if available)
          if (hasValidAvatarUrl && imageUrl != null)
            Positioned.fill(
              child: _buildHeroImage(
                imageUrl: imageUrl,
                cacheKey: cacheKey,
                cropSettings: cropSettings,
                heroWidth: heroWidth,
                heroHeight: heroHeight,
                isLightTheme: isLightTheme,
                defaultIconSize: defaultIconSize,
              ),
            ),

          // Default avatar icon (if no valid avatar)
          if (!hasValidAvatarUrl)
            Positioned.fill(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/userProfile_Rounded_fill.svg',
                  width: heroHeight * 0.4,
                  height: heroHeight * 0.4,
                  colorFilter: ColorFilter.mode(
                    isLightTheme
                        ? CupertinoColors.separator
                        : CupertinoColors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build hero image with optional crop settings
  Widget _buildHeroImage({
    required String imageUrl,
    required String? cacheKey,
    required AvatarCropSettings? cropSettings,
    required double heroWidth,
    required double heroHeight,
    required bool isLightTheme,
    required double defaultIconSize,
  }) {
    // Check if we have crop settings to apply
    final hasCropSettings = cropSettings != null &&
        (cropSettings.cropWidth < 1.0 || cropSettings.cropHeight < 1.0);

    // Error widget builder
    Widget buildErrorWidget(String url, dynamic error) {
      ProfileAvatar._failedUrls.add(url);
      AppLogger.log('ProfileAvatar Hero: Failed to load image from $url');

      return Container(
        color: widget.backgroundColor ??
            (isLightTheme
                ? const Color(0xFFF2F2F7)
                : const Color(0xFF1C1C1E)),
        child: Center(
          child: Icon(
            CupertinoIcons.person_fill,
            color: isLightTheme
                ? CupertinoColors.separator
                : CupertinoColors.systemGrey,
            size: defaultIconSize,
          ),
        ),
      );
    }

    if (hasCropSettings) {
      // Apply crop transform for hero mode
      // Scale image so crop region fills the hero container
      final displayWidth = heroWidth / cropSettings.cropWidth;
      final displayHeight = heroHeight / cropSettings.cropHeight;
      final left = -cropSettings.cropX / cropSettings.cropWidth * heroWidth;
      final top = -cropSettings.cropY / cropSettings.cropHeight * heroHeight;

      return SizedBox(
        width: heroWidth,
        height: heroHeight,
        child: ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: left,
                top: top,
                width: displayWidth,
                height: displayHeight,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  cacheKey: cacheKey,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 100),
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => const CupertinoActivityIndicator(),
                  errorWidget: (context, url, error) => buildErrorWidget(url, error),
                  memCacheHeight: 1024, // Higher resolution for hero images
                  httpHeaders: widget.useCache
                      ? null
                      : const {
                          'Cache-Control': 'no-cache, no-store, must-revalidate',
                          'Pragma': 'no-cache',
                          'Expires': '0',
                        },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No crop - standard cover fit for hero
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: cacheKey,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 100),
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: const Duration(milliseconds: 50),
      placeholder: (context, url) => const CupertinoActivityIndicator(),
      errorWidget: (context, url, error) => buildErrorWidget(url, error),
      memCacheHeight: 1024, // Higher resolution for hero images
      httpHeaders: widget.useCache
          ? null
          : const {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
    );
  }
}
