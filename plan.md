# Biblio — Responsive UI Refactor Plan

## Goal
Make all UI screens look the same on big screens but less bloated on smaller screens. Uses a **MediaQuery scale factor** approach — no `flutter_screenutil`.

## Strategy (see CLAUDE.md for full details)
```dart
// At the top of build():
final screenWidth = MediaQuery.sizeOf(context).width;
final scale = (screenWidth / 393).clamp(0.85, 1.0);

// Then scale sizes from design values:
final titleSize = (28 * scale).clamp(22.0, 28.0);
final iconSize = (44 * scale).roundToDouble();
final padH = (24 * scale).clamp(16.0, 24.0);
```

### Rules
- **Scale factor**: `(screenWidth / 393).clamp(0.85, 1.0)`. Compute once per `build()`.
- **Font sizes**: `(designSize * scale).clamp(min, max)`. Min ~4-6pt below design.
- **Containers**: `(designSize * scale).clamp(min, max)` or `.roundToDouble()`.
- **Small spacing** (4-16px): Leave as-is. **Large spacing** (20+): Scale + clamp.
- **Rows of equal items** (e.g. day circles): Wrap in `Expanded`, pass computed size to child.
- **Do NOT scale**: `strokeWidth`, `Duration`, `Curve`, `viewportFraction`, colors, border radius, animation values.

---

## Progress Tracker

### Phase 1 — Onboarding (screens users see first)
- [x] `lib/onboarding/final_onboarding_screen.dart`
- [x] `lib/onboarding/onboarding_screen.dart`
- [x] `lib/onboarding/reading_goal_screen.dart`
- [x] `lib/onboarding/username_setup_screen.dart`

### Phase 2 — Homepage & Core Navigation
- [x] `lib/Homescreen/homepage.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/homepage_header.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/custom_bottom_navigation.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/currently_reading_card.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/todays_goal_widget.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/daily_quote_widget.dart`
- [x] `lib/Homescreen/widgets/homepage widgets/bookshelves_widget.dart`

### Phase 3 — Library
- [x] `lib/Homescreen/pages/library/library_page.dart`
- [x] `lib/Homescreen/pages/library/widgets/book_card.dart`
- [x] `lib/Homescreen/pages/library/widgets/library_header.dart`
- [x] `lib/Homescreen/pages/library/widgets/library_search_bar.dart`
- [x] `lib/Homescreen/pages/library/widgets/reading_now_card.dart`
- [x] `lib/Homescreen/pages/library/widgets/shelf_card.dart`
- [x] `lib/Homescreen/pages/library/widgets/recent_books_section.dart`
- [x] `lib/Homescreen/pages/library/widgets/all_books_list.dart`
- [x] `lib/Homescreen/pages/library/widgets/book_details_sheet.dart`
- [x] `lib/Homescreen/pages/library/widgets/book_journal_page.dart`
- [x] `lib/Homescreen/pages/library/widgets/sort_options_sheet.dart`
- [x] `lib/Homescreen/pages/library/shelf widgets/add_to_shelf.dart`
- [x] `lib/Homescreen/pages/library/shelf widgets/create_shelf_dialog.dart`
- [x] `lib/Homescreen/pages/library/shelf widgets/edit_shelf_dialog.dart`
- ~~`manage_shelves_dialog.dart`~~ DEAD CODE — delete
- ~~`shelf_tabs/shelf_tabs_widget.dart`~~ DEAD CODE — delete
- ~~`shelf_tabs/shelf_chip.dart`~~ DEAD CODE — delete
- ~~`shelf_tabs/add_shelf_button.dart`~~ DEAD CODE — delete
- [x] `lib/Homescreen/pages/library/widgets/selection/selection_toolbar.dart`
- [x] `lib/Homescreen/pages/library/widgets/selection/bulk_add_to_shelf_dialog.dart`
- [x] `lib/Homescreen/pages/library/widgets/empty_states/empty_library_state.dart`
- [x] `lib/Homescreen/pages/library/widgets/empty_states/empty_shelf_state.dart`

### Phase 4 — Book Upload
- [x] `lib/Homescreen/widgets/book upload/add_book_options_dialog.dart`
- [x] `lib/Homescreen/widgets/book upload/book_search_dialog.dart`
- [x] `lib/Homescreen/widgets/book upload/confirm_book_details_dialog.dart`
- [x] `lib/Homescreen/widgets/book upload/manual book entry/manual_book_entry_dialog.dart`
- [x] `lib/Homescreen/widgets/book upload/manual book entry/book_search_card.dart`
- [x] `lib/Homescreen/widgets/book upload/manual book entry/book_success_sheet.dart`
- [x] `lib/Homescreen/widgets/book upload/manual book entry/search_empty_state.dart`

### Phase 5 — Reading Sessions
- [x] `lib/reading_session/reading_session_page.dart`
- [x] `lib/reading_session/widgets/book_card.dart`
- [x] `lib/reading_session/widgets/timer_circle.dart`
- [x] `lib/reading_session/widgets/action_buttons.dart`
- [x] `lib/reading_session/widgets/stats_card.dart`
- [x] `lib/reading_session/widgets/mode_tabs.dart`
- [x] `lib/manual_reading/manual_reading_page.dart`
- [x] `lib/manual_reading/focus_mode_screen.dart`
- [x] `lib/manual_reading/dialogs/end_session_page_dialog.dart`
- [x] `lib/manual_reading/widgets/physical_book_card.dart`
- [x] `lib/manual_reading/widgets/physical_book_mode_tabs.dart`
- [x] `lib/manual_reading/widgets/physical_book_timer_circle.dart`
- [x] `lib/manual_reading/widgets/physical_book_action_buttons.dart`
- [x] `lib/manual_reading/widgets/physical_book_tool_bar.dart`
- [x] `lib/manual_reading/scan_quote/scan_quote_camera_screen.dart`
- [x] `lib/manual_reading/scan_quote/scan_quote_edit_screen.dart`
- [x] `lib/manual_reading/ask_ai/ask_ai_bottom_sheet.dart`

### Phase 6 — Viewers (EPUB & PDF)
- [X] `lib/epub_viewer/epub_viewer_page.dart`
- [x] `lib/epub_viewer/widgets/epub_bottom_sheet.dart`
- [x] `lib/epub_viewer/widgets/epub_viewer_header.dart`
- [x] `lib/epub_viewer/widgets/epub_viewer_reader.dart`
- [x] `lib/epub_viewer/widgets/epub_font_settings_sheet.dart`
- [x] `lib/epub_viewer/widgets/epub_table_of_contents_sheet.dart`
- [x] `lib/epub_viewer/widgets/text_selection_menu.dart`
- [x] `lib/epub_viewer/widgets/sheet_components.dart`
- [x] `lib/epub_viewer/widgets/table_of_contents_view.dart`
- [x] `lib/epub_viewer/widgets/journal_view.dart`
- [x] `lib/epub_viewer/widgets/journal_entry_cards.dart`
- [x] `lib/epub_viewer/widgets/ai_definition_sheet.dart`
- [x] `lib/epub_viewer/widgets/navigation_warning_banner.dart`
- [x] `lib/epub_viewer/widgets/return_to_current_button.dart`
- [x] `lib/pdf_viewer/presentation/pdf_viewer_page.dart`
- [x] `lib/pdf_viewer/presentation/widgets/pdf_header.dart`
- [x] `lib/pdf_viewer/presentation/widgets/pdf_bottom_sheet_new.dart`
- [x] `lib/pdf_viewer/presentation/widgets/pdf_text_selection_menu.dart`
- [x] `lib/pdf_viewer/presentation/widgets/table_of_contents_sheet.dart`
- [x] `lib/pdf_viewer/presentation/widgets/dark_color_mode.dart`

### Phase 7 — Streak & Stats
- [x] `lib/Homescreen/pages/streak/streak_page.dart`
- [x] `lib/Homescreen/pages/streak/streak_details_screen.dart`
- [x] `lib/Homescreen/pages/streak/goal_streak_details_screen.dart`
- [x] `lib/Homescreen/pages/streak/day_detail_screen.dart`
- [x] `lib/Homescreen/pages/streak/widgets/streak_widget.dart`
- [x] `lib/Homescreen/pages/streak/widgets/streak_header.dart`
- [x] `lib/Homescreen/pages/streak/widgets/daily_progress_card.dart`
- [x] `lib/Homescreen/pages/streak/widgets/xp_level_card.dart`
- [x] `lib/Homescreen/pages/streak/widgets/activity_heatmap_card.dart`

### Phase 8 — Gamification & Settings
- [x] `lib/features/gamification/screens/achievements_screen.dart`
- [x] `lib/features/gamification/screens/levels_screen.dart`
- [x] `lib/features/gamification/screens/notification_screen.dart`
- [x] `lib/features/gamification/screens/reading_stats_screen.dart`
- [x] `lib/features/gamification/screens/streak_saver_screen.dart`
- [x] `lib/features/gamification/widgets/achievement_card.dart`
- [x] `lib/features/gamification/widgets/achievement_unlock_dialog.dart`
- [x] `lib/features/gamification/widgets/level_badge.dart`
- [x] `lib/features/gamification/widgets/notification_badge.dart`
- [x] `lib/features/gamification/widgets/streak_flame_widget.dart`
- [x] `lib/features/gamification/widgets/streak_saver_dialog.dart`
- [x] `lib/features/gamification/widgets/xp_progress_bar.dart`
- [x] `lib/features/settings/user_setting_screen.dart`

### Phase 9 — Core Widgets, Auth, Notebook
- [x] `lib/core/widgets/circle_to_search_overlay.dart`
- [x] `lib/core/widgets/circle_search_result_sheet.dart`
- [x] `lib/auth/auth_screen.dart`
- [x] `lib/notebook/notebook_page.dart`
- [x] `lib/notebook/widgets/quote_card.dart`

---

## Notes
- Auth wiring restored: `authStateProvider` + `_UsernameGate` active in `main.dart`
