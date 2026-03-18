import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider to track expanded FAQ items
final expandedFaqProvider = StateProvider<Set<int>>((ref) => {});

/// Reusable FAQ Section Widget
/// Used across landing page and subscribe screen
/// Supports two heading styles: landing page (badge + centered) and subscribe screen (compact + left-aligned)
class FaqSection extends ConsumerWidget {
  /// Theme colors from themeColorsProvider (required for proper theme support)
  final dynamic colors;

  /// Optional maximum width constraint for the FAQ section
  final double? maxWidth;

  /// Optional custom FAQ items (if null, uses default items)
  final List<Map<String, String>>? customFaqItems;

  /// Show landing page style (badge + centered heading) or subscribe screen style (compact + left-aligned)
  final bool showLandingStyle;

  const FaqSection({
    super.key,
    required this.colors,
    this.maxWidth,
    this.customFaqItems,
    this.showLandingStyle = false, // Default to subscribe screen style
  });

  /// Default FAQ items used in subscribe screen (matches landing page)
  static const List<Map<String, String>> defaultFaqItems = [
    // Subscription/Payment related questions first
    {
      'question': 'What plan is made for me?',
      'answer': 'It depends on your needs:\n• Essential: Perfect for solopreneurs and small businesses with 1 website.\n• Professional: Best for growing businesses with up to 3 websites and backlink needs.\n• Business: Ideal for agencies and enterprises managing up to 10 websites.',
    },
    {
      'question': 'Do you offer a free trial period?',
      'answer': 'Yes! You can try RankPeak for free for 3 days with full access to all features. Cancel anytime during the trial and you won\'t be charged.',
    },
    {
      'question': 'Can I cancel my subscription at any time?',
      'answer': 'Yes, absolutely. You can cancel at any time with no questions asked. Your subscription will remain active until the end of your billing period.',
    },
    {
      'question': 'Do you offer discounts?',
      'answer': 'Yes! By choosing annual billing, you save 30% compared to monthly payments. We also offer special promotions throughout the year.',
    },
    {
      'question': 'How can I contact you if I have another question?',
      'answer': 'You can reach us anytime at hello@rankpeak.co and we\'ll respond quickly. You can also join our Discord community for real-time support.',
    },
    // Product/Feature related questions
    {
      'question': 'How does the article automation work?',
      'answer': 'Once you enter your website URL, our AI analyzes your niche, competitors, and target audience to discover high-potential keywords. It then creates a 30-day content plan and generates SEO-optimized articles daily. Articles are automatically published to your blog or integrated platform while you focus on your business.',
    },
    {
      'question': 'How quickly will I see results?',
      'answer': 'Most users start seeing increased impressions within 2-4 weeks. Significant traffic growth typically occurs within 6-12 weeks as Google indexes your new content. Some users report going from a few hundred impressions to thousands within the first month.',
    },
    {
      'question': 'Is AI content really as good as human writers?',
      'answer': 'Our AI creates 3,000+ word SEO-optimized articles with proper research, internal/external linking, and AI-generated images. Many users report the quality exceeds what they got from content agencies. The content is optimized to rank on both Google and AI search platforms like ChatGPT and Claude.',
    },
    {
      'question': 'What platforms do you integrate with?',
      'answer': 'RankPeak integrates with WordPress, Webflow, Shopify, Wix, Framer, Notion, and 10+ other platforms. You can also use our free Notion-style blog hosting, or connect via webhooks to any custom platform.',
    },
    {
      'question': 'Can I manage multiple websites?',
      'answer': 'Yes! Essential plan includes 1 website, Professional includes 3 websites, and Business includes 10 websites. Each website gets its own keyword research, content calendar, and automation settings.',
    },
    {
      'question': 'Do I need SEO experience to use this?',
      'answer': 'No SEO experience required. Just paste your website URL and our AI handles everything: keyword research, content strategy, article creation, and publishing. The platform is designed to work on autopilot.',
    },
    {
      'question': 'Can I review articles before they go live?',
      'answer': 'Yes! You have full control. Review, edit, or rewrite any article before publishing. You also get unlimited AI rewrites to refine content until it matches your voice perfectly.',
    },
    {
      'question': 'Will this help me show up in AI search (ChatGPT, Claude)?',
      'answer': 'Absolutely. RankPeak optimizes your content for both traditional search (Google) and AI platforms including ChatGPT, Claude, Gemini, Perplexity, and others. Our Professional plan includes AI visibility tracking so you can monitor your presence across all major AI models.',
    },
    {
      'question': 'What if I\'m not sure it\'s right for me?',
      'answer': 'We offer a 3-day trial for just \$1 so you can test the full platform risk-free. You can cancel anytime with no questions asked. Your subscription remains active until the end of your billing period.',
    },
    {
      'question': 'How much does Rankpeak cost compared to alternatives?',
      'answer': 'RankPeak replaces multiple expensive tools and services. Users report saving \$2-3K/month compared to hiring content agencies or freelance writers. You get keyword research, content creation, SEO optimization, and auto-publishing all in one platform starting at \$90/month (billed annually).',
    },
  ];

  /// Build heading section based on style variant
  Widget _buildHeading({required bool isMobile}) {
    if (showLandingStyle) {
      // Landing page style: Two-line heading (matching CTA/testimonials formatting)
      return Column(
        crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start, // Center on mobile
        children: [
          Text(
            'Still have questions?',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: isMobile ? 28 : 32, // Responsive font size (28 matches CTA mobile)
              fontWeight: FontWeight.bold,
              height: isMobile ? 1.2 : 1.3, // Responsive height (1.2 matches CTA mobile)
              letterSpacing: -0.5,
            ).copyWith(color: colors.primaryText),
            textAlign: isMobile ? TextAlign.center : TextAlign.left, // Center on mobile
          ),
          Text(
            'We have the answers',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: isMobile ? 28 : 32, // Responsive font size (28 matches CTA mobile)
              fontWeight: FontWeight.bold,
              height: isMobile ? 1.2 : 1.3, // Responsive height (1.2 matches CTA mobile)
              letterSpacing: -0.5,
            ).copyWith(color: colors.primaryText),
            textAlign: isMobile ? TextAlign.center : TextAlign.left, // Center on mobile
          ),
        ],
      );
    } else {
      // Subscribe screen style: Compact left-aligned heading
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Still have questions?',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: isMobile ? 20 : 22, // Responsive font size
              fontWeight: FontWeight.bold,
              height: 1.3,
              letterSpacing: -0.3,
            ).copyWith(color: colors.primaryText),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              'We have the answers',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: isMobile ? 20 : 22, // Responsive font size
                fontWeight: FontWeight.w400,
                height: 1.3,
                letterSpacing: -0.3,
              ).copyWith(color: colors.secondaryText),
            ),
          ),
        ],
      );
    }
  }

  /// Build subtitle with "Send a message" link
  Widget _buildSubtitle({required bool isMobile}) {
    return RichText(
      textAlign: isMobile && showLandingStyle ? TextAlign.center : TextAlign.left, // Center on mobile for landing style
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: isMobile ? 14 : 16, // Responsive font size
          fontWeight: FontWeight.w400,
          color: colors.secondaryText,
        ),
        children: [
          const TextSpan(text: 'Didn\'t find what you were looking for? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse('mailto:hello@rankpeak.co');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              child: Text(
                'Send a message',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 14 : 16, // Responsive font size
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF918DF6), // Purple color
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLightMode = colors.primaryBackground == const Color(0xFFFFFFFF) ||
                         colors.primaryBackground == CupertinoColors.white;
    final faqItems = customFaqItems ?? defaultFaqItems;

    // Responsive detection
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = kIsWeb && screenWidth > 900;
    final isMobile = !isDesktop;

    Widget content;

    if (showLandingStyle) {
      // Landing page style: Two-column layout (heading left, FAQ items right) on desktop
      // Mobile: Stacked vertically
      content = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20, // Responsive padding
          vertical: isMobile ? 40 : 60, // Responsive padding
        ),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Heading + subtitle
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeading(isMobile: false),
                        const SizedBox(height: 16),
                        // Subtitle with link
                        _buildSubtitle(isMobile: false),
                      ],
                    ),
                  ),

                  const SizedBox(width: 60),

                  // Right column: FAQ items
                  Expanded(
                    flex: 6,
                    child: Column(
                      children: List.generate(faqItems.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: index < faqItems.length - 1 ? 12 : 0),
                          child: _FaqItem(
                            index: index,
                            question: faqItems[index]['question']!,
                            answer: faqItems[index]['answer']!,
                            colors: colors,
                            isLightMode: isLightMode,
                            isMobile: false,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              )
            : Column(
                // Mobile: Stacked layout
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Heading
                  _buildHeading(isMobile: true),
                  const SizedBox(height: 16),
                  // Subtitle with link
                  _buildSubtitle(isMobile: true),
                  const SizedBox(height: 32),
                  // FAQ items
                  ...List.generate(faqItems.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: index < faqItems.length - 1 ? 12 : 0),
                      child: _FaqItem(
                        index: index,
                        question: faqItems[index]['question']!,
                        answer: faqItems[index]['answer']!,
                        colors: colors,
                        isLightMode: isLightMode,
                        isMobile: true,
                      ),
                    );
                  }),
                ],
              ),
      );
    } else {
      // Subscribe screen style: Vertical column layout (responsive)
      content = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20, // Responsive padding
          vertical: isMobile ? 40 : 60, // Responsive padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            _buildHeading(isMobile: isMobile),
            const SizedBox(height: 16),
            // Subtitle with link
            _buildSubtitle(isMobile: isMobile),
            const SizedBox(height: 32),
            // FAQ Items
            ...List.generate(faqItems.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index < faqItems.length - 1 ? 12 : 0),
                child: _FaqItem(
                  index: index,
                  question: faqItems[index]['question']!,
                  answer: faqItems[index]['answer']!,
                  colors: colors,
                  isLightMode: isLightMode,
                  isMobile: isMobile,
                ),
              );
            }),
          ],
        ),
      );
    }

    // Optionally wrap with max width constraint
    if (maxWidth != null) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Individual FAQ item widget
class _FaqItem extends ConsumerWidget {
  final int index;
  final String question;
  final String answer;
  final dynamic colors;
  final bool isLightMode;
  final bool isMobile;

  const _FaqItem({
    required this.index,
    required this.question,
    required this.answer,
    required this.colors,
    required this.isLightMode,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedFaqs = ref.watch(expandedFaqProvider);
    final isExpanded = expandedFaqs.contains(index);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final currentExpanded = ref.read(expandedFaqProvider);
        if (isExpanded) {
          ref.read(expandedFaqProvider.notifier).state =
              Set.from(currentExpanded)..remove(index);
        } else {
          ref.read(expandedFaqProvider.notifier).state =
              Set.from(currentExpanded)..add(index);
        }
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20), // Responsive padding
        decoration: ShapeDecoration(
          color: isLightMode
              ? const Color(0xFFFFFFFF) // White for light mode
              : colors.cardBackground, // Dark mode card background
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 12,
              cornerSmoothing: 0.8,
            ),
            side: isLightMode
                ? const BorderSide(
                    color: Color(0xFFE5E5EA), // Light border
                    width: 1,
                  )
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 15 : 16, // Responsive font size
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16), // Responsive spacing
                // Plus/Minus icon (no background container)
                Icon(
                  isExpanded ? CupertinoIcons.minus : CupertinoIcons.plus,
                  size: isMobile ? 16 : 18, // Responsive icon size
                  color: colors.primaryText,
                ),
              ],
            ),
            if (isExpanded) ...[
              SizedBox(height: isMobile ? 10 : 12), // Responsive spacing
              Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 13 : 14, // Responsive font size
                  fontWeight: FontWeight.w400,
                  color: colors.secondaryText,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
