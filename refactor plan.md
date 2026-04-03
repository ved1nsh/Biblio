# Biblio Codebase Reorganization Plan

## Context

Reorganize to mirror the app's UI hierarchy. The app has 4 main tabs — each becomes a feature folder. Inside each, widget folders contain the widget + the sub-screens it navigates to + related data files. Cross-cutting services stay in a slim `core/`.

---

## Dead Code — Delete First

| File | Why |
|------|-----|
| `Homescreen/pages/library/shelf widgets/manage_shelves_dialog.dart` | Never imported |
| `Homescreen/pages/library/widgets/shelf_tabs/shelf_tabs_widget.dart` | Old UI, unused |
| `Homescreen/pages/library/widgets/shelf_tabs/shelf_chip.dart` | Only used by dead shelf_tabs_widget |
| `Homescreen/pages/library/widgets/shelf_tabs/add_shelf_button.dart` | Only used by dead shelf_tabs_widget |

---

## Proposed Structure

```
lib/
├── main.dart
├── firebase_options.dart
│
├── core/                                         # Cross-cutting only
│   ├── models/
│   │   ├── user_model.dart                       # auth user — used everywhere
│   │   └── book_model.dart                       # 26+ imports across all features
│   ├── services/
│   │   ├── auth_services.dart                    # Google sign-in, Supabase init
│   │   ├── xp_service.dart                       # called from 5+ features
│   │   ├── notification_service.dart             # called from stats, achievements, xp
│   │   ├── supabase_stats_service.dart           # called from all readers, triggers achievements
│   │   ├── sembast_service.dart                  # local DB across readers
│   │   └── user_profile_migration.dart           # init hook in main.dart
│   ├── providers/
│   │   └── auth_provider.dart
│   └── widgets/
│       ├── circle_to_search_overlay.dart
│       └── circle_search_result_sheet.dart
│
├── features/
│
│   ├── homepage/                                 # ═══ TAB 1: HOMEPAGE ═══
│   │   ├── homepage.dart                         # main page + tab navigator
│   │   ├── widgets/
│   │   │   ├── custom_bottom_navigation.dart     # bottom nav bar
│   │   │   ├── homepage_header.dart              # greeting + avatar → taps to settings
│   │   │   ├── homepage_reading_widget.dart      # currently reading books → taps to reader
│   │   │   ├── bookshelves_widget.dart           # shelf list → taps to shelf detail
│   │   │   ├── todays_goal_widget.dart           # streak + goal cards → taps to streak tab
│   │   │   ├── currently_reading_card.dart
│   │   │   └── daily_quote_widget.dart
│   │   ├── book_upload/                          # add book flow (FAB button)
│   │   │   ├── add_book_options_dialog.dart
│   │   │   ├── book_search_dialog.dart
│   │   │   ├── confirm_book_details_dialog.dart
│   │   │   └── manual_entry/
│   │   │       ├── manual_book_entry_dialog.dart
│   │   │       ├── book_search_card.dart
│   │   │       ├── book_success_sheet.dart
│   │   │       └── search_empty_state.dart
│   │   └── settings/                             # accessed from header avatar
│   │       └── user_setting_screen.dart
│   │
│   ├── library/                                  # ═══ TAB 2: LIBRARY ═══
│   │   ├── library_page.dart                     # main page — shelf grid + search
│   │   ├── shelf_detail_page.dart                # opened when tapping a shelf
│   │   ├── widgets/
│   │   │   ├── book_card.dart
│   │   │   ├── book_details_sheet.dart           # modal on book tap
│   │   │   ├── book_journal_page.dart            # opened from book details
│   │   │   ├── library_header.dart
│   │   │   ├── library_search_bar.dart
│   │   │   ├── reading_now_card.dart
│   │   │   ├── shelf_card.dart
│   │   │   ├── all_books_list.dart
│   │   │   ├── recent_books_section.dart
│   │   │   ├── sort_options_sheet.dart
│   │   │   ├── empty_states/
│   │   │   │   ├── empty_library_state.dart
│   │   │   │   └── empty_shelf_state.dart
│   │   │   └── selection/
│   │   │       ├── selection_toolbar.dart
│   │   │       └── bulk_add_to_shelf_dialog.dart
│   │   ├── shelf_dialogs/
│   │   │   ├── add_to_shelf.dart
│   │   │   ├── create_shelf_dialog.dart
│   │   │   └── edit_shelf_dialog.dart
│   │   ├── actions/
│   │   │   ├── selection_actions.dart
│   │   │   └── shelf_actions.dart
│   │   └── data/
│   │       ├── models/
│   │       │   └── shelf_model.dart
│   │       ├── services/
│   │       │   ├── supabase_book_service.dart
│   │       │   ├── supabase_shelf_service.dart
│   │       │   └── google_books_service.dart
│   │       └── providers/
│   │           ├── book_provider.dart
│   │           └── shelf_provider.dart
│   │
│   ├── streak/                                   # ═══ TAB 3: STREAK ═══
│   │   ├── streak_page.dart                      # main page
│   │   ├── streak_header.dart
│   │   │
│   │   ├── streak_widget/                        # swipeable streak card on page
│   │   │   ├── streak_widget.dart                #   widget shown on streak_page
│   │   │   ├── streak_details_screen.dart        #   → tap card 1
│   │   │   ├── goal_streak_details_screen.dart   #   → tap card 2
│   │   │   └── day_detail_screen.dart            #   → tap a day in details
│   │   │
│   │   ├── daily_progress/                       # daily reading arc on page
│   │   │   ├── daily_progress_card.dart          #   widget shown on streak_page
│   │   │   └── reading_stats_screen.dart         #   → tap to see full stats
│   │   │
│   │   ├── xp_level/                             # XP + level card on page
│   │   │   ├── xp_level_card.dart                #   widget shown on streak_page
│   │   │   ├── levels_screen.dart                #   → tap to see all levels
│   │   │   ├── xp_progress_bar.dart
│   │   │   └── level_badge.dart
│   │   │
│   │   ├── achievements/                         # recent badges section on page
│   │   │   ├── achievement_card.dart             #   badge cards on streak_page
│   │   │   ├── achievements_screen.dart          #   → "View All" tap
│   │   │   └── achievement_unlock_dialog.dart    #   confetti popup on unlock
│   │   │
│   │   ├── streak_saver/                         # broken streak banner on page
│   │   │   ├── streak_saver_screen.dart          #   → tap "Restore" button
│   │   │   ├── streak_saver_dialog.dart
│   │   │   └── streak_flame_widget.dart
│   │   │
│   │   ├── activity_heatmap_card.dart            # heatmap calendar (no sub-screen)
│   │   │
│   │   └── data/
│   │       ├── models/
│   │       │   ├── daily_reading_stats_model.dart
│   │       │   ├── achievement_model.dart
│   │       │   └── user_profile_model.dart
│   │       ├── constants/
│   │       │   ├── level_config.dart
│   │       │   └── achievement_icons.dart
│   │       ├── services/
│   │       │   ├── streak_service.dart
│   │       │   ├── streak_saver_service.dart
│   │       │   ├── achievement_service.dart
│   │       │   └── badge_service.dart
│   │       └── providers/
│   │           ├── xp_provider.dart
│   │           ├── achievement_provider.dart
│   │           └── badge_provider.dart
│   │
│   ├── notebook/                                 # ═══ TAB 4: NOTEBOOK ═══
│   │   ├── notebook_page.dart                    # main page — quote grid
│   │   ├── widgets/
│   │   │   └── quote_card.dart
│   │   └── data/
│   │       └── services/
│   │           └── notebook_service.dart
│   │
│   ├── reader/                                   # ═══ READERS (from book tap) ═══
│   │   ├── epub/
│   │   │   ├── epub_viewer_page.dart
│   │   │   ├── controllers/                      # internal structure preserved
│   │   │   ├── widgets/
│   │   │   ├── quote_dialog/
│   │   │   ├── models/
│   │   │   └── utils/
│   │   ├── pdf/
│   │   │   ├── pdf_viewer_page.dart              # flattened from presentation/
│   │   │   ├── controllers/
│   │   │   └── widgets/
│   │   ├── manual/
│   │   │   ├── manual_reading_page.dart
│   │   │   ├── focus_mode_screen.dart
│   │   │   ├── widgets/
│   │   │   ├── dialogs/
│   │   │   ├── scan_quote/
│   │   │   └── ask_ai/
│   │   ├── session/
│   │   │   ├── reading_session_page.dart
│   │   │   ├── controllers/
│   │   │   ├── widgets/
│   │   │   ├── dialogs/
│   │   │   └── constants/
│   │   └── data/
│   │       └── services/
│   │           ├── highlights_service.dart
│   │           ├── reading_preferences_service.dart
│   │           └── ai_service.dart
│   │
│   ├── notifications/                            # ═══ NOTIFICATIONS ═══
│   │   ├── notification_screen.dart
│   │   ├── widgets/
│   │   │   └── notification_badge.dart
│   │   └── data/
│   │       ├── models/
│   │       │   └── notification_model.dart
│   │       └── providers/
│   │           └── notification_provider.dart
│   │
│   ├── auth/
│   │   └── auth_screen.dart
│   │
│   └── onboarding/
│       ├── onboarding_screen.dart
│       ├── username_setup_screen.dart
│       ├── profile_setup_screen.dart
│       ├── reading_goal_screen.dart
│       ├── final_onboarding_screen.dart
│       └── models/
│           └── feature_card_model.dart
```

---

## File Movement Map

### → `features/homepage/`
| From | To |
|------|-----|
| `Homescreen/homepage.dart` | `features/homepage/homepage.dart` |
| `Homescreen/widgets/homepage widgets/*.dart` (7 files) | `features/homepage/widgets/` |
| `Homescreen/widgets/book upload/*.dart` (3 files) | `features/homepage/book_upload/` |
| `Homescreen/widgets/book upload/manual book entry/*.dart` (4 files) | `features/homepage/book_upload/manual_entry/` |
| `features/settings/user_setting_screen.dart` | `features/homepage/settings/user_setting_screen.dart` |

### → `features/library/`
| From | To |
|------|-----|
| `Homescreen/pages/library/library_page.dart` | `features/library/library_page.dart` |
| `Homescreen/pages/library/shelf_detail_page.dart` | `features/library/shelf_detail_page.dart` |
| `Homescreen/pages/library/widgets/*.dart` | `features/library/widgets/` |
| `Homescreen/pages/library/shelf widgets/*.dart` (3 used files) | `features/library/shelf_dialogs/` |
| `Homescreen/pages/library/actions/*.dart` | `features/library/actions/` |
| `core/models/shelf_model.dart` | `features/library/data/models/` |
| `core/services/supabase_book_service.dart` | `features/library/data/services/` |
| `core/services/supabase_shelf_service.dart` | `features/library/data/services/` |
| `core/services/google_books_service.dart` | `features/library/data/services/` |
| `core/providers/book_provider.dart` | `features/library/data/providers/` |
| `core/providers/shelf_provider.dart` | `features/library/data/providers/` |

### → `features/streak/`
| From | To |
|------|-----|
| `Homescreen/pages/streak/streak_page.dart` | `features/streak/streak_page.dart` |
| `Homescreen/pages/streak/widgets/streak_header.dart` | `features/streak/streak_header.dart` |
| `Homescreen/pages/streak/widgets/streak_widget.dart` | `features/streak/streak_widget/streak_widget.dart` |
| `Homescreen/pages/streak/streak_details_screen.dart` | `features/streak/streak_widget/streak_details_screen.dart` |
| `Homescreen/pages/streak/goal_streak_details_screen.dart` | `features/streak/streak_widget/goal_streak_details_screen.dart` |
| `Homescreen/pages/streak/day_detail_screen.dart` | `features/streak/streak_widget/day_detail_screen.dart` |
| `Homescreen/pages/streak/widgets/daily_progress_card.dart` | `features/streak/daily_progress/daily_progress_card.dart` |
| `features/gamification/screens/reading_stats_screen.dart` | `features/streak/daily_progress/reading_stats_screen.dart` |
| `Homescreen/pages/streak/widgets/xp_level_card.dart` | `features/streak/xp_level/xp_level_card.dart` |
| `features/gamification/screens/levels_screen.dart` | `features/streak/xp_level/levels_screen.dart` |
| `features/gamification/widgets/xp_progress_bar.dart` | `features/streak/xp_level/xp_progress_bar.dart` |
| `features/gamification/widgets/level_badge.dart` | `features/streak/xp_level/level_badge.dart` |
| `features/gamification/screens/achievements_screen.dart` | `features/streak/achievements/achievements_screen.dart` |
| `features/gamification/widgets/achievement_card.dart` | `features/streak/achievements/achievement_card.dart` |
| `features/gamification/widgets/achievement_unlock_dialog.dart` | `features/streak/achievements/achievement_unlock_dialog.dart` |
| `features/gamification/screens/streak_saver_screen.dart` | `features/streak/streak_saver/streak_saver_screen.dart` |
| `features/gamification/widgets/streak_saver_dialog.dart` | `features/streak/streak_saver/streak_saver_dialog.dart` |
| `features/gamification/widgets/streak_flame_widget.dart` | `features/streak/streak_saver/streak_flame_widget.dart` |
| `Homescreen/pages/streak/widgets/activity_heatmap_card.dart` | `features/streak/activity_heatmap_card.dart` |
| `core/models/daily_reading_stats_model.dart` | `features/streak/data/models/` |
| `core/models/achievement_model.dart` | `features/streak/data/models/` |
| `core/models/user_profile_model.dart` | `features/streak/data/models/` |
| `core/constants/level_config.dart` | `features/streak/data/constants/` |
| `core/constants/achievement_icons.dart` | `features/streak/data/constants/` |
| `core/services/streak_service.dart` | `features/streak/data/services/` |
| `core/services/streak_saver_service.dart` | `features/streak/data/services/` |
| `core/services/achievement_service.dart` | `features/streak/data/services/` |
| `core/services/badge_service.dart` | `features/streak/data/services/` |
| `core/providers/xp_provider.dart` | `features/streak/data/providers/` |
| `core/providers/achievement_provider.dart` | `features/streak/data/providers/` |
| `core/providers/badge_provider.dart` | `features/streak/data/providers/` |

### → `features/notebook/`
| From | To |
|------|-----|
| `notebook/notebook_page.dart` | `features/notebook/notebook_page.dart` |
| `notebook/widgets/quote_card.dart` | `features/notebook/widgets/quote_card.dart` |
| `core/services/notebook_service.dart` | `features/notebook/data/services/` |

### → `features/reader/`
| From | To |
|------|-----|
| `epub_viewer/` (entire dir) | `features/reader/epub/` |
| `pdf_viewer/` (entire dir, flatten presentation/) | `features/reader/pdf/` |
| `manual_reading/` (entire dir) | `features/reader/manual/` |
| `reading_session/` (entire dir) | `features/reader/session/` |
| `core/services/highlights_service.dart` | `features/reader/data/services/` |
| `core/services/reading_preferences_service.dart` | `features/reader/data/services/` |
| `core/services/ai_service.dart` | `features/reader/data/services/` |

### → `features/notifications/`
| From | To |
|------|-----|
| `features/gamification/screens/notification_screen.dart` | `features/notifications/notification_screen.dart` |
| `features/gamification/widgets/notification_badge.dart` | `features/notifications/widgets/` |
| `core/models/notification_model.dart` | `features/notifications/data/models/` |
| `core/providers/notification_provider.dart` | `features/notifications/data/providers/` |

### → `features/auth/` and `features/onboarding/`
| From | To |
|------|-----|
| `auth/auth_screen.dart` | `features/auth/auth_screen.dart` |
| `onboarding/*.dart` (all files) | `features/onboarding/` (same structure) |

### Stays in `core/` (truly cross-cutting)
- `models/user_model.dart` — 20+ imports everywhere
- `models/book_model.dart` — 26+ imports everywhere
- `services/auth_services.dart` — auth + main + settings
- `services/xp_service.dart` — 5+ features call it
- `services/notification_service.dart` — 3+ features call it
- `services/supabase_stats_service.dart` — all readers + triggers achievements
- `services/sembast_service.dart` — local DB
- `services/user_profile_migration.dart` — init hook
- `providers/auth_provider.dart` — everywhere
- `widgets/` — circle search overlay

---

## Execution Phases

### Phase 0: Delete dead code + convert relative imports → absolute
- Delete 4 dead files listed above
- Convert ~95 relative imports to `package:biblio/...` absolute imports

### Phase 1: Create `features/homepage/`
- Move `homepage.dart` + homepage widgets + book upload + settings
- Fix space in "book upload" → `book_upload/`, "manual book entry" → `manual_entry/`, "homepage widgets" → just `widgets/`
- Update all imports

### Phase 2: Create `features/library/`
- Move library pages + widgets + shelf dialogs + actions
- Move shelf_model, book/shelf services, book/shelf providers into `data/`
- Fix "shelf widgets" → `shelf_dialogs/`
- Update all imports

### Phase 3: Create `features/streak/`
- Move streak pages + widgets into widget-based subfolders
- Move gamification screens/widgets into matching subfolders (levels_screen → xp_level/, etc.)
- Move streak data files (models, constants, services, providers) into `data/`
- Delete empty `features/gamification/` and `core/constants/`
- Update all imports

### Phase 4: Create `features/notebook/`
- Move notebook page + widgets + notebook_service
- Update imports

### Phase 5: Create `features/reader/`
- Move epub_viewer, pdf_viewer, manual_reading, reading_session
- Flatten pdf_viewer/presentation/
- Move highlights_service, reading_preferences_service, ai_service into `data/services/`
- Update imports

### Phase 6: Create `features/notifications/` + move auth/onboarding
- Split notification_screen + notification_badge out of (now-empty) gamification
- Move notification model + provider into `data/`
- Move auth/ and onboarding/ under features/
- Update imports

### Phase 7: Cleanup
- Delete empty `Homescreen/`, old `core/constants/`, old `features/gamification/`
- Run `flutter analyze` — zero errors
- Verify `core/` only has: 2 models, 6 services, 1 provider, 2 widgets

---

## Verification
After each phase: `flutter analyze` — zero errors
Final: `flutter run` — launch app, tap all 4 tabs, open a book, check streak page
