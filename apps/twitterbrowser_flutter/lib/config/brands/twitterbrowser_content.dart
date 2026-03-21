import 'package:flutter_shared_core/flutter_shared_core.dart';

class TwitterBrowserContent implements BrandContent {
  const TwitterBrowserContent();

  @override
  BrandTestimonial get authTestimonial => const BrandTestimonial(
    quote:
        '"TwitterBrowser keeps local and hosted browser profiles visible in one clean workspace."',
    highlightedPhrase: 'clean profile workspace',
    authorName: 'Maya Bennett',
    authorTitle: 'Revenue Operations Lead at Northfield Labs',
    avatarAsset: 'assets/images/testimonials/user20.webp',
  );

  @override
  BrandTestimonial get subscribeTestimonial => authTestimonial;

  @override
  BrandTestimonial get compactTestimonial => authTestimonial;

  @override
  List<BrandFaqItem> get faqItems => const [
    BrandFaqItem(
      question: 'What can I do in the companion app?',
      answer:
          'You can authenticate, choose a local or hosted workspace, and inspect the profiles that already exist in TwitterBrowser.',
    ),
    BrandFaqItem(
      question: 'Does this app edit profiles?',
      answer:
          'No. The companion is intentionally read-only in this first version.',
    ),
  ];
}
