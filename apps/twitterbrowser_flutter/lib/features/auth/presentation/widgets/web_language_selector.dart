import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twitterbrowser_flutter/features/settings/data/models/language_locale.dart';
import 'package:twitterbrowser_flutter/features/settings/data/providers/language_locale_provider.dart';

class WebLanguageSelector extends ConsumerStatefulWidget {
  const WebLanguageSelector({super.key});

  @override
  ConsumerState<WebLanguageSelector> createState() =>
      _WebLanguageSelectorState();
}

class _WebLanguageSelectorState extends ConsumerState<WebLanguageSelector> {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final _buttonKey = GlobalKey();

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _showOverlay() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    const menuWidth = 280.0;
    const horizontalMargin = 12.0;
    final viewportWidth = MediaQuery.of(context).size.width;

    var left = position.dx;
    if (left + menuWidth > viewportWidth - horizontalMargin) {
      left = viewportWidth - menuWidth - horizontalMargin;
    }
    if (left < horizontalMargin) {
      left = horizontalMargin;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: position.dy + size.height + 8,
              left: left,
              child: _buildDropdownMenu(),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  Widget _buildDropdownMenu() {
    final colors = ref.watch(themeColorsProvider);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        decoration: ShapeDecoration(
          color: colors.primaryBackground,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1,
            ),
            side: BorderSide(
              color: colors.primaryBorder.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          shadows: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipSmoothRect(
          radius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.secondaryBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: colors.primaryBorder.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'LANGUAGES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.secondaryText.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: Column(
                    children: LanguageLocale.supportedLanguages
                        .map(_buildLanguageItem)
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(LanguageLocale language) {
    final colors = ref.watch(themeColorsProvider);
    final currentLocale = ref.watch(languageLocaleProvider);
    final isSelected = currentLocale.languageCode == language.languageCode;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        ref.read(languageLocaleProvider.notifier).changeLocale(language);
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: SvgPicture.asset(language.flagAssetPath),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language.displayName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: colors.primaryText,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 18,
                color: colors.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageLocaleProvider);
    final colors = ref.watch(themeColorsProvider);

    return CupertinoButton(
      key: _buttonKey,
      padding: EdgeInsets.zero,
      onPressed: _toggleDropdown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.asset(currentLocale.flagAssetPath),
          ),
          const SizedBox(width: 8),
          Text(
            currentLocale.languageCode.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primaryText.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            _isOpen ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
            size: 14,
            color: colors.primaryText.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
