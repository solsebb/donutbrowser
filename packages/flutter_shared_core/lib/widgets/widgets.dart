/// Shared UI widgets for RankPeak and Liink
///
/// These widgets are truly generic with no feature-specific dependencies.
/// Feature-coupled widgets remain in the main app's lib/shared/widgets/.
library;

export 'action_button.dart';
export 'ads_label.dart';
export 'ai_prompt_input.dart';
export 'app_modal.dart';
export 'app_toast.dart';
export 'article_hover_preview.dart';
export 'black_friday_badge.dart';
// Hide all physics constants - they conflict with draggable_overlay_modal.dart and static_overlay_modal.dart
export 'bottom_app_modal.dart' hide kUpwardResistance, kDownwardResistance, kSpringMass, kSpringStiffness, kSpringDampingRatio;
export 'bottom_sheet_modal.dart';
export 'coming_soon_modal.dart';
export 'coming_soon_nav_item.dart';
export 'custom_back_button.dart';
export 'dashed_border_painter.dart';
export 'desktop_landscape_modal.dart';
// Hide all constants/types/functions that conflict with static_overlay_modal.dart (primary exporter)
export 'draggable_overlay_modal.dart' hide kModalFixedHeight, kAnimationDuration, kDismissThreshold, kUpwardResistance, kDownwardResistance, kMaxHeightExtension, kSpringMass, kSpringStiffness, kSpringDampingRatio, OnDragUpdateCallback, calculateModalHeight;
export 'email_button_input_modal.dart';
export 'email_signup_input_modal.dart';
export 'faq_section.dart';
export 'floating_prompt_field.dart';
export 'font_picker_modal.dart';
export 'gauge_slider.dart';
export 'hover_preview_card.dart';
export 'hover_tooltip.dart';
export 'ios_context_menu.dart';
export 'item_picker.dart';
export 'loading_indicator.dart';
export 'notification_popup.dart';
export 'notion_dropdown.dart';
export 'notion_table.dart';
export 'optimized_image.dart';
export 'positioned_text_layer.dart';
export 'pro_label.dart';
export 'processing_overlay.dart';
export 'profile_avatar.dart';
export 'profile_avatar_skeleton.dart';
export 'profile_picture_options_modal.dart';
export 'responsive_app_container.dart';
export 'responsive_onboarding_container.dart';
export 'rounded_button.dart';
export 'save_to_gallery_button.dart';
export 'search_header.dart';
export 'section_title_input_modal.dart';
export 'shared_cupertino_search_field.dart';
export 'static_overlay_modal.dart';
export 'styled_block_container.dart';
export 'url_input_modal.dart';
export 'web_color_picker_dropdown.dart';
export 'web_dropdown_base.dart';
