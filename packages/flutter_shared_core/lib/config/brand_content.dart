/// Brand-specific content for multi-domain white-labeling.
///
/// This file contains data classes for brand-specific content like
/// testimonials and FAQ items that vary between brands.
library;

/// Represents a customer testimonial for marketing screens.
///
/// Used in auth screens, subscribe screens, and other marketing contexts.
class BrandTestimonial {
  /// The full quote text (including quotation marks if desired)
  final String quote;

  /// The phrase within the quote to highlight/bold
  /// Set to empty string if no highlighting needed
  final String highlightedPhrase;

  /// Author's full name
  final String authorName;

  /// Author's job title and company
  final String authorTitle;

  /// Path to author's avatar image asset
  final String avatarAsset;

  const BrandTestimonial({
    required this.quote,
    required this.highlightedPhrase,
    required this.authorName,
    required this.authorTitle,
    required this.avatarAsset,
  });
}

/// Represents a single FAQ item.
class BrandFaqItem {
  /// The question text
  final String question;

  /// The answer text (can include brand name placeholders)
  final String answer;

  const BrandFaqItem({
    required this.question,
    required this.answer,
  });
}

/// Abstract class for brand-specific content.
///
/// Each brand implements this to provide its own testimonials and FAQ.
abstract class BrandContent {
  /// Testimonial shown on auth/login screens
  BrandTestimonial get authTestimonial;

  /// Testimonial shown on subscribe/pricing screens
  BrandTestimonial get subscribeTestimonial;

  /// Compact testimonial for side panels
  BrandTestimonial get compactTestimonial;

  /// List of FAQ items for the FAQ section
  List<BrandFaqItem> get faqItems;
}
