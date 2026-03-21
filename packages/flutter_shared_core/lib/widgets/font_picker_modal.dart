import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_shared_core/theme/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Modal for selecting a Google Font
/// Shows a list of popular Google Fonts with previews
class FontPickerModal extends ConsumerStatefulWidget {
  final String currentFont;
  final ValueChanged<String> onFontSelected;

  const FontPickerModal({
    super.key,
    required this.currentFont,
    required this.onFontSelected,
  });

  @override
  ConsumerState<FontPickerModal> createState() => _FontPickerModalState();

  /// Show the font picker modal
  static Future<String?> show({
    required BuildContext context,
    required String currentFont,
  }) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => FontPickerModal(
        currentFont: currentFont,
        onFontSelected: (font) => Navigator.of(context).pop(font),
      ),
    );
  }
}

class _FontPickerModalState extends ConsumerState<FontPickerModal> {
  late String _selectedFont;
  String _searchQuery = '';

  // Popular Google Fonts - carefully curated list
  static const List<String> _availableFonts = [
    'Inter',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Raleway',
    'Nunito',
    'Ubuntu',
    'Playfair Display',
    'Merriweather',
    'PT Sans',
    'Noto Sans',
    'Work Sans',
    'Quicksand',
    'Rubik',
    'Bebas Neue',
    'Oswald',
    'Source Sans 3',
    'Mukta',
    'Barlow',
    'DM Sans',
    'Space Grotesk',
    'Plus Jakarta Sans',
    'Manrope',
    'Outfit',
    'Sora',
    'JetBrains Mono',
    'Fira Code',
    'IBM Plex Sans',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFont = widget.currentFont;
  }

  List<String> get _filteredFonts {
    if (_searchQuery.isEmpty) return _availableFonts;
    return _availableFonts
        .where((font) => font.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  TextStyle _getFontStyle(String fontName) {
    try {
      switch (fontName) {
        case 'Inter':
          return GoogleFonts.inter(fontSize: 16);
        case 'Roboto':
          return GoogleFonts.roboto(fontSize: 16);
        case 'Open Sans':
          return GoogleFonts.openSans(fontSize: 16);
        case 'Lato':
          return GoogleFonts.lato(fontSize: 16);
        case 'Montserrat':
          return GoogleFonts.montserrat(fontSize: 16);
        case 'Poppins':
          return GoogleFonts.poppins(fontSize: 16);
        case 'Raleway':
          return GoogleFonts.raleway(fontSize: 16);
        case 'Nunito':
          return GoogleFonts.nunito(fontSize: 16);
        case 'Ubuntu':
          return GoogleFonts.ubuntu(fontSize: 16);
        case 'Playfair Display':
          return GoogleFonts.playfairDisplay(fontSize: 16);
        case 'Merriweather':
          return GoogleFonts.merriweather(fontSize: 16);
        case 'PT Sans':
          return GoogleFonts.ptSans(fontSize: 16);
        case 'Noto Sans':
          return GoogleFonts.notoSans(fontSize: 16);
        case 'Work Sans':
          return GoogleFonts.workSans(fontSize: 16);
        case 'Quicksand':
          return GoogleFonts.quicksand(fontSize: 16);
        case 'Rubik':
          return GoogleFonts.rubik(fontSize: 16);
        case 'Bebas Neue':
          return GoogleFonts.bebasNeue(fontSize: 16);
        case 'Oswald':
          return GoogleFonts.oswald(fontSize: 16);
        case 'Source Sans 3':
          return GoogleFonts.sourceSans3(fontSize: 16);
        case 'Mukta':
          return GoogleFonts.mukta(fontSize: 16);
        case 'Barlow':
          return GoogleFonts.barlow(fontSize: 16);
        case 'DM Sans':
          return GoogleFonts.dmSans(fontSize: 16);
        case 'Space Grotesk':
          return GoogleFonts.spaceGrotesk(fontSize: 16);
        case 'Plus Jakarta Sans':
          return GoogleFonts.plusJakartaSans(fontSize: 16);
        case 'Manrope':
          return GoogleFonts.manrope(fontSize: 16);
        case 'Outfit':
          return GoogleFonts.outfit(fontSize: 16);
        case 'Sora':
          return GoogleFonts.sora(fontSize: 16);
        case 'JetBrains Mono':
          return GoogleFonts.jetBrainsMono(fontSize: 16);
        case 'Fira Code':
          return GoogleFonts.firaCode(fontSize: 16);
        case 'IBM Plex Sans':
          return GoogleFonts.ibmPlexSans(fontSize: 16);
        default:
          return GoogleFonts.inter(fontSize: 16);
      }
    } catch (e) {
      return GoogleFonts.inter(fontSize: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: colors.modalBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.primaryBorder.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Font',
                  style: GoogleFonts.inter(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: colors.tertiaryText,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              placeholder: 'Search fonts...',
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              style: GoogleFonts.inter(color: colors.primaryText),
              placeholderStyle: GoogleFonts.inter(color: colors.tertiaryText),
              backgroundColor: colors.searchBarBackground,
            ),
          ),

          // Font list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFonts.length,
              itemBuilder: (context, index) {
                final font = _filteredFonts[index];
                final isSelected = font == _selectedFont;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedFont = font);
                    widget.onFontSelected(font);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryBorder.withValues(alpha: 0.08)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: colors.primaryBorder.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Font preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                font,
                                style: GoogleFonts.inter(
                                  color: colors.primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The quick brown fox jumps',
                                style: _getFontStyle(font).copyWith(
                                  color: colors.secondaryText,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Checkmark
                        if (isSelected)
                          SvgPicture.asset(
                            'assets/icons/check_big_RoundedFill.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              colors.primaryText,
                              BlendMode.srcIn,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
