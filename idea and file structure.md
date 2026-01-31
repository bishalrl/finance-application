# Personal OS / Life Vault - Technical Architecture Document

## 1. PROJECT OVERVIEW

**Product Name**: Personal OS / Life Vault / PocketOS  
**Architecture**: Clean Architecture with Feature-Based Structure  
**Framework**: Flutter (Cross-platform)  
**State Management**: BLoC Pattern  
**Database**: Hive (Encrypted Local Storage)  
**Encryption**: AES-256-GCM with Zero-Knowledge Architecture

---

## 2. TECHNOLOGY STACK

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: flutter_bloc (^8.1.3)
- **Local Database**: hive (^2.2.3), hive_flutter
- **Encryption**: 
  - encrypt (^5.0.1)
  - flutter_secure_storage (^9.0.0)
  - pointycastle (^3.7.3)
- **File Operations**: 
  - path_provider (^2.1.1)
  - file_picker (^6.1.1)
  - open_file (^3.3.2)
- **Authentication**: local_auth (^2.1.7)
- **Notifications**: flutter_local_notifications (^16.3.0)
- **PDF**: pdf, printing
- **Markdown**: flutter_markdown (^0.6.18)
- **SMS Parsing**: telephony (^0.2.0) - Android only

### Backend (Optional Sync Feature)
- **API**: Node.js with Express or NestJS
- **Database**: PostgreSQL (encrypted metadata only)
- **Storage**: AWS S3 / MinIO (encrypted blobs)
- **Authentication**: JWT with zero-knowledge proof

### Security Architecture
- **Encryption Standard**: AES-256-GCM
- **Key Derivation**: Argon2id / PBKDF2
- **Storage**: Encrypted Hive boxes with user-controlled keys
- **Biometric**: Device biometric + PIN fallback

---

## 3. COMPLETE FILE STRUCTURE

```
personal_os/
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── storage_keys.dart
│   │   │   ├── routes.dart
│   │   │   └── api_endpoints.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_dimensions.dart
│   │   │
│   │   ├── config/
│   │   │   ├── dependency_injection.dart
│   │   │   ├── router.dart
│   │   │   └── env_config.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── date_formatter.dart
│   │   │   ├── file_utils.dart
│   │   │   ├── validators.dart
│   │   │   ├── extensions.dart
│   │   │   └── permission_handler.dart
│   │   │
│   │   ├── errors/
│   │   │   ├── failures.dart
│   │   │   ├── exceptions.dart
│   │   │   └── error_handler.dart
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   ├── network_info.dart
│   │   │   └── dio_interceptor.dart
│   │   │
│   │   ├── security/
│   │   │   ├── encryption_service.dart
│   │   │   ├── key_manager.dart
│   │   │   ├── biometric_service.dart
│   │   │   └── secure_storage_service.dart
│   │   │
│   │   ├── database/
│   │   │   ├── hive_service.dart
│   │   │   ├── database_helper.dart
│   │   │   └── type_adapters/
│   │   │       ├── document_adapter.dart
│   │   │       ├── note_adapter.dart
│   │   │       └── reminder_adapter.dart
│   │   │
│   │   └── widgets/
│   │       ├── custom_app_bar.dart
│   │       ├── custom_button.dart
│   │       ├── custom_text_field.dart
│   │       ├── loading_indicator.dart
│   │       ├── error_widget.dart
│   │       ├── empty_state_widget.dart
│   │       └── confirmation_dialog.dart
│   │
│   └── features/
│       │
│       ├── 01_splash/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── splash_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── app_config_model.dart
│       │   │   └── repositories/
│       │   │       └── splash_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── app_config.dart
│       │   │   ├── repositories/
│       │   │   │   └── splash_repository.dart
│       │   │   └── usecases/
│       │   │       ├── check_first_launch.dart
│       │   │       ├── initialize_app.dart
│       │   │       └── check_app_lock.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── splash_bloc.dart
│       │       │   ├── splash_event.dart
│       │       │   └── splash_state.dart
│       │       └── pages/
│       │           └── splash_page.dart
│       │
│       ├── 02_onboarding/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── onboarding_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── onboarding_slide_model.dart
│       │   │   └── repositories/
│       │   │       └── onboarding_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── onboarding_slide.dart
│       │   │   ├── repositories/
│       │   │   │   └── onboarding_repository.dart
│       │   │   └── usecases/
│       │   │       ├── get_onboarding_slides.dart
│       │   │       └── complete_onboarding.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── onboarding_bloc.dart
│       │       │   ├── onboarding_event.dart
│       │       │   └── onboarding_state.dart
│       │       ├── pages/
│       │       │   └── onboarding_page.dart
│       │       └── widgets/
│       │           ├── onboarding_slide_widget.dart
│       │           ├── page_indicator.dart
│       │           └── skip_button.dart
│       │
│       ├── 03_auth/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── auth_local_datasource.dart
│       │   │   │   ├── biometric_datasource.dart
│       │   │   │   └── pin_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── user_auth_model.dart
│       │   │   │   └── security_settings_model.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── user_auth.dart
│       │   │   │   └── security_settings.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart
│       │   │   └── usecases/
│       │   │       ├── setup_pin.dart
│       │   │       ├── verify_pin.dart
│       │   │       ├── setup_biometric.dart
│       │   │       ├── verify_biometric.dart
│       │   │       ├── change_pin.dart
│       │   │       └── lock_app.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── auth_bloc.dart
│       │       │   ├── auth_event.dart
│       │       │   └── auth_state.dart
│       │       ├── pages/
│       │       │   ├── setup_pin_page.dart
│       │       │   ├── verify_pin_page.dart
│       │       │   ├── app_lock_page.dart
│       │       │   └── security_settings_page.dart
│       │       └── widgets/
│       │           ├── pin_input_widget.dart
│       │           ├── biometric_button.dart
│       │           └── security_option_tile.dart
│       │
│       ├── 04_home/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── home_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── dashboard_stats_model.dart
│       │   │   └── repositories/
│       │   │       └── home_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── dashboard_stats.dart
│       │   │   ├── repositories/
│       │   │   │   └── home_repository.dart
│       │   │   └── usecases/
│       │   │       ├── get_dashboard_stats.dart
│       │   │       ├── get_recent_items.dart
│       │   │       └── get_upcoming_reminders.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── home_bloc.dart
│       │       │   ├── home_event.dart
│       │       │   └── home_state.dart
│       │       ├── pages/
│       │       │   └── home_page.dart
│       │       └── widgets/
│       │           ├── stats_card.dart
│       │           ├── quick_action_button.dart
│       │           ├── recent_items_list.dart
│       │           └── upcoming_reminders_card.dart
│       │
│       ├── 05_documents/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── document_local_datasource.dart
│       │   │   │   └── file_storage_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── document_model.dart
│       │   │   │   └── document_category_model.dart
│       │   │   └── repositories/
│       │   │       └── document_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── document.dart
│       │   │   │   └── document_category.dart
│       │   │   ├── repositories/
│       │   │   │   └── document_repository.dart
│       │   │   └── usecases/
│       │   │       ├── add_document.dart
│       │   │       ├── get_all_documents.dart
│       │   │       ├── get_document_by_id.dart
│       │   │       ├── update_document.dart
│       │   │       ├── delete_document.dart
│       │   │       ├── search_documents.dart
│       │   │       └── filter_by_category.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── document_bloc.dart
│       │       │   ├── document_event.dart
│       │       │   └── document_state.dart
│       │       ├── pages/
│       │       │   ├── documents_list_page.dart
│       │       │   ├── document_detail_page.dart
│       │       │   ├── add_document_page.dart
│       │       │   └── document_viewer_page.dart
│       │       └── widgets/
│       │           ├── document_card.dart
│       │           ├── document_grid_item.dart
│       │           ├── category_chip.dart
│       │           ├── document_filter_bottom_sheet.dart
│       │           └── file_type_icon.dart
│       │
│       ├── 06_notes/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── note_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── note_model.dart
│       │   │   │   └── note_folder_model.dart
│       │   │   └── repositories/
│       │   │       └── note_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── note.dart
│       │   │   │   └── note_folder.dart
│       │   │   ├── repositories/
│       │   │   │   └── note_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_note.dart
│       │   │       ├── get_all_notes.dart
│       │   │       ├── get_note_by_id.dart
│       │   │       ├── update_note.dart
│       │   │       ├── delete_note.dart
│       │   │       ├── search_notes.dart
│       │   │       └── organize_in_folders.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── note_bloc.dart
│       │       │   ├── note_event.dart
│       │       │   └── note_state.dart
│       │       ├── pages/
│       │       │   ├── notes_list_page.dart
│       │       │   ├── note_editor_page.dart
│       │       │   └── note_folders_page.dart
│       │       └── widgets/
│       │           ├── note_card.dart
│       │           ├── markdown_editor.dart
│       │           ├── note_preview.dart
│       │           ├── folder_selector.dart
│       │           └── formatting_toolbar.dart
│       │
│       ├── 07_ideas/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── idea_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── idea_model.dart
│       │   │   │   └── project_model.dart
│       │   │   └── repositories/
│       │   │       └── idea_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── idea.dart
│       │   │   │   └── project.dart
│       │   │   ├── repositories/
│       │   │   │   └── idea_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_idea.dart
│       │   │       ├── get_ideas_inbox.dart
│       │   │       ├── like_idea.dart
│       │   │       ├── move_to_project.dart
│       │   │       ├── create_project.dart
│       │   │       ├── get_all_projects.dart
│       │   │       └── sort_by_likes.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── idea_bloc.dart
│       │       │   ├── idea_event.dart
│       │       │   ├── idea_state.dart
│       │       │   ├── project_bloc.dart
│       │       │   ├── project_event.dart
│       │       │   └── project_state.dart
│       │       ├── pages/
│       │       │   ├── ideas_inbox_page.dart
│       │       │   ├── idea_detail_page.dart
│       │       │   ├── projects_page.dart
│       │       │   └── project_detail_page.dart
│       │       └── widgets/
│       │           ├── idea_card.dart
│       │           ├── like_button.dart
│       │           ├── project_card.dart
│       │           ├── idea_sorting_options.dart
│       │           └── move_to_project_dialog.dart
│       │
│       ├── 08_reminders/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── reminder_local_datasource.dart
│       │   │   │   └── notification_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── reminder_model.dart
│       │   │   └── repositories/
│       │   │       └── reminder_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── reminder.dart
│       │   │   ├── repositories/
│       │   │   │   └── reminder_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_reminder.dart
│       │   │       ├── get_all_reminders.dart
│       │   │       ├── get_upcoming_reminders.dart
│       │   │       ├── update_reminder.dart
│       │   │       ├── delete_reminder.dart
│       │   │       ├── mark_as_complete.dart
│       │   │       └── schedule_notification.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── reminder_bloc.dart
│       │       │   ├── reminder_event.dart
│       │       │   └── reminder_state.dart
│       │       ├── pages/
│       │       │   ├── reminders_page.dart
│       │       │   ├── add_reminder_page.dart
│       │       │   └── reminder_detail_page.dart
│       │       └── widgets/
│       │           ├── reminder_card.dart
│       │           ├── reminder_type_selector.dart
│       │           ├── date_time_picker.dart
│       │           └── recurrence_settings.dart
│       │
│       ├── 09_calendar/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── calendar_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── calendar_event_model.dart
│       │   │   └── repositories/
│       │   │       └── calendar_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── calendar_event.dart
│       │   │   ├── repositories/
│       │   │   │   └── calendar_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_event.dart
│       │   │       ├── get_events_by_date.dart
│       │   │       ├── get_month_events.dart
│       │   │       ├── update_event.dart
│       │   │       └── delete_event.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── calendar_bloc.dart
│       │       │   ├── calendar_event.dart
│       │       │   └── calendar_state.dart
│       │       ├── pages/
│       │       │   ├── calendar_page.dart
│       │       │   ├── add_event_page.dart
│       │       │   └── event_detail_page.dart
│       │       └── widgets/
│       │           ├── calendar_view.dart
│       │           ├── month_view.dart
│       │           ├── day_view.dart
│       │           ├── event_card.dart
│       │           └── event_list.dart
│       │
│       ├── 10_finance/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── finance_local_datasource.dart
│       │   │   │   └── sms_parser_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── transaction_model.dart
│       │   │   │   └── finance_category_model.dart
│       │   │   └── repositories/
│       │   │       └── finance_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── transaction.dart
│       │   │   │   └── finance_category.dart
│       │   │   ├── repositories/
│       │   │   │   └── finance_repository.dart
│       │   │   └── usecases/
│       │   │       ├── parse_sms_transactions.dart
│       │   │       ├── add_transaction.dart
│       │   │       ├── get_all_transactions.dart
│       │   │       ├── categorize_transaction.dart
│       │   │       ├── get_monthly_summary.dart
│       │   │       └── export_transactions.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── finance_bloc.dart
│       │       │   ├── finance_event.dart
│       │       │   └── finance_state.dart
│       │       ├── pages/
│       │       │   ├── finance_page.dart
│       │       │   ├── transactions_page.dart
│       │       │   ├── add_transaction_page.dart
│       │       │   └── finance_summary_page.dart
│       │       └── widgets/
│       │           ├── transaction_card.dart
│       │           ├── category_icon.dart
│       │           ├── monthly_chart.dart
│       │           ├── expense_summary.dart
│       │           └── sms_permission_dialog.dart
│       │
│       ├── 11_vault/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── vault_local_datasource.dart
│       │   │   │   └── encrypted_storage_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── vault_item_model.dart
│       │   │   │   └── vault_folder_model.dart
│       │   │   └── repositories/
│       │   │       └── vault_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── vault_item.dart
│       │   │   │   └── vault_folder.dart
│       │   │   ├── repositories/
│       │   │   │   └── vault_repository.dart
│       │   │   └── usecases/
│       │   │       ├── add_to_vault.dart
│       │   │       ├── get_vault_items.dart
│       │   │       ├── unlock_vault.dart
│       │   │       ├── lock_vault.dart
│       │   │       ├── move_to_vault.dart
│       │   │       ├── hide_item.dart
│       │   │       └── delete_from_vault.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── vault_bloc.dart
│       │       │   ├── vault_event.dart
│       │       │   └── vault_state.dart
│       │       ├── pages/
│       │       │   ├── vault_page.dart
│       │       │   ├── vault_unlock_page.dart
│       │       │   ├── vault_items_page.dart
│       │       │   └── vault_settings_page.dart
│       │       └── widgets/
│       │           ├── vault_item_card.dart
│       │           ├── vault_unlock_widget.dart
│       │           ├── hidden_indicator.dart
│       │           └── vault_folder_selector.dart
│       │
│       ├── 12_tags/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── tag_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── tag_model.dart
│       │   │   └── repositories/
│       │   │       └── tag_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── tag.dart
│       │   │   ├── repositories/
│       │   │   │   └── tag_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_tag.dart
│       │   │       ├── get_all_tags.dart
│       │   │       ├── assign_tag.dart
│       │   │       ├── remove_tag.dart
│       │   │       ├── get_items_by_tag.dart
│       │   │       └── delete_tag.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── tag_bloc.dart
│       │       │   ├── tag_event.dart
│       │       │   └── tag_state.dart
│       │       ├── pages/
│       │       │   ├── tags_page.dart
│       │       │   └── tag_items_page.dart
│       │       └── widgets/
│       │           ├── tag_chip.dart
│       │           ├── tag_selector.dart
│       │           ├── create_tag_dialog.dart
│       │           └── tag_color_picker.dart
│       │
│       ├── 13_search/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── search_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── search_result_model.dart
│       │   │   └── repositories/
│       │   │       └── search_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── search_result.dart
│       │   │   ├── repositories/
│       │   │   │   └── search_repository.dart
│       │   │   └── usecases/
│       │   │       ├── search_all.dart
│       │   │       ├── search_documents.dart
│       │   │       ├── search_notes.dart
│       │   │       ├── search_by_tag.dart
│       │   │       └── filter_search_results.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── search_bloc.dart
│       │       │   ├── search_event.dart
│       │       │   └── search_state.dart
│       │       ├── pages/
│       │       │   └── search_page.dart
│       │       └── widgets/
│       │           ├── search_bar.dart
│       │           ├── search_filter_chips.dart
│       │           ├── search_result_card.dart
│       │           └── recent_searches.dart
│       │
│       ├── 14_sync/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── sync_remote_datasource.dart
│       │   │   │   └── sync_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   ├── sync_status_model.dart
│       │   │   │   └── sync_conflict_model.dart
│       │   │   └── repositories/
│       │   │       └── sync_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   ├── sync_status.dart
│       │   │   │   └── sync_conflict.dart
│       │   │   ├── repositories/
│       │   │   │   └── sync_repository.dart
│       │   │   └── usecases/
│       │   │       ├── sync_data.dart
│       │   │       ├── upload_changes.dart
│       │   │       ├── download_changes.dart
│       │   │       ├── resolve_conflicts.dart
│       │   │       ├── link_device.dart
│       │   │       └── get_sync_status.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── sync_bloc.dart
│       │       │   ├── sync_event.dart
│       │       │   └── sync_state.dart
│       │       ├── pages/
│       │       │   ├── sync_settings_page.dart
│       │       │   ├── device_management_page.dart
│       │       │   └── sync_conflict_resolution_page.dart
│       │       └── widgets/
│       │           ├── sync_status_indicator.dart
│       │           ├── device_card.dart
│       │           ├── conflict_item.dart
│       │           └── sync_progress_dialog.dart
│       │
│       ├── 15_backup/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   ├── backup_local_datasource.dart
│       │   │   │   └── export_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── backup_model.dart
│       │   │   └── repositories/
│       │   │       └── backup_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── backup.dart
│       │   │   ├── repositories/
│       │   │   │   └── backup_repository.dart
│       │   │   └── usecases/
│       │   │       ├── create_backup.dart
│       │   │       ├── restore_backup.dart
│       │   │       ├── export_data.dart
│       │   │       ├── import_data.dart
│       │   │       └── schedule_auto_backup.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── backup_bloc.dart
│       │       │   ├── backup_event.dart
│       │       │   └── backup_state.dart
│       │       ├── pages/
│       │       │   ├── backup_page.dart
│       │       │   └── restore_page.dart
│       │       └── widgets/
│       │           ├── backup_card.dart
│       │           ├── backup_progress.dart
│       │           └── restore_options.dart
│       │
│       ├── 16_settings/
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── settings_local_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── app_settings_model.dart
│       │   │   └── repositories/
│       │   │       └── settings_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── app_settings.dart
│       │   │   ├── repositories/
│       │   │   │   └── settings_repository.dart
│       │   │   └── usecases/
│       │   │       ├── get_settings.dart
│       │   │       ├── update_theme.dart
│       │   │       ├── update_language.dart
│       │   │       ├── toggle_feature.dart
│       │   │       └── reset_settings.dart
│       │   └── presentation/
│       │       ├── bloc/
│       │       │   ├── settings_bloc.dart
│       │       │   ├── settings_event.dart
│       │       │   └── settings_state.dart
│       │       ├── pages/
│       │       │   ├── settings_page.dart
│       │       │   ├── appearance_settings_page.dart
│       │       │   ├── privacy_settings_page.dart
│       │       │   └── about_page.dart
│       │       └── widgets/
│       │           ├── settings_tile.dart
│       │           ├── theme_selector.dart
│       │           └── language_selector.dart
│       │
│       └── 17_subscription/
│           ├── data/
│           │   ├── datasources/
│           │   │   ├── subscription_local_datasource.dart
│           │   │   └── payment_remote_datasource.dart
│           │   ├── models/
│           │   │   ├── subscription_model.dart
│           │   │   └── payment_model.dart
│           │   └── repositories/
│           │       └── subscription_repository_impl.dart
│           ├── domain/
│           │   ├── entities/
│           │   │   ├── subscription.dart
│           │   │   └── payment.dart
│           │   ├── repositories/
│           │   │   └── subscription_repository.dart
│           │   └── usecases/
│           │       ├── get_subscription_status.dart
│           │       ├── purchase_pro.dart
│           │       ├── purchase_sync.dart
│           │       ├── purchase_maintenance.dart
│           │       ├── restore_purchases.dart
│           │       └── check_features_access.dart
│           └── presentation/
│               ├── bloc/
│               │   ├── subscription_bloc.dart
│               │   ├── subscription_event.dart
│               │   └── subscription_state.dart
│               ├── pages/
│               │   ├── subscription_page.dart
│               │   ├── pricing_page.dart
│               │   └── payment_success_page.dart
│               └── widgets/
│                   ├── pricing_card.dart
│                   ├── feature_comparison_table.dart
│                   └── subscription_badge.dart
│
├── test/
│   ├── core/
│   │   ├── security/
│   │   │   └── encryption_service_test.dart
│   │   └── database/
│   │       └── hive_service_test.dart
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── documents/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── notes/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── widget_test.dart
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   ├── onboarding/
│   │   └── icons/
│   ├── fonts/
│   └── animations/
│
├── android/
├── ios/
├── web/
├── windows/
├── macos/
├── linux/
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── .gitignore
```

---

## 4. DATA MODELS & ENTITIES

### Core Entity Structure

```dart
// Example: Document Entity
class Document {
  final String id;
  final String title;
  final String filePath;
  final String fileType;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final List<String> tags;
  final String? category;
  final bool isVault;
  final bool isHidden;
}

// Example: Note Entity
class Note {
  final String id;
  final String title;
  final String content; // Markdown
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final List<String> tags;
  final bool isVault;
}

// Example: Reminder Entity
class Reminder {
  final String id;
  final String title;
  final String? description;
  final DateTime reminderDate;
  final ReminderType type; // Bill, Expiry, Custom
  final bool isRecurring;
  final RecurrencePattern? recurrence;
  final bool isCompleted;
  final String? linkedDocumentId;
}
```

---

## 5. DEPENDENCY INJECTION (GetIt)

```dart
// lib/core/config/dependency_injection.dart

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<EncryptionService>(() => EncryptionService());
  sl.registerLazySingleton<HiveService>(() => HiveService());
  sl.registerLazySingleton<BiometricService>(() => BiometricService());
  
  // Feature: Auth
  sl.registerFactory(() => AuthBloc(
    setupPin: sl(),
    verifyPin: sl(),
    setupBiometric: sl(),
  ));
  
  sl.registerLazySingleton(() => SetupPin(sl()));
  sl.registerLazySingleton(() => VerifyPin(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl())
  );
  
  // Feature: Documents
  sl.registerFactory(() => DocumentBloc(
    addDocument: sl(),
    getAllDocuments: sl(),
    deleteDocument: sl(),
  ));
  
  // ... repeat for all features
}
```

---

## 6. ROUTING STRUCTURE

```dart
// lib/core/config/router.dart

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String setupPin = '/setup-pin';
  static const String appLock = '/app-lock';
  static const String home = '/home';
  
  // Documents
  static const String documents = '/documents';
  static const String documentDetail = '/documents/:id';
  static const String addDocument = '/documents/add';
  
  // Notes
  static const String notes = '/notes';
  static const String noteEditor = '/notes/editor';
  
  // Ideas
  static const String ideas = '/ideas';
  static const String projects = '/projects';
  
  // Vault
  static const String vault = '/vault';
  static const String vaultUnlock = '/vault/unlock';
  
  // Settings
  static const String settings = '/settings';
  static const String security = '/settings/security';
  static const String subscription = '/settings/subscription';
}
```

---

## 7. DATABASE SCHEMA (Hive)

### Hive Boxes Structure

```dart
// Documents Box
Box<DocumentModel> documentsBox;

// Notes Box
Box<NoteModel> notesBox;

// Ideas Box
Box<IdeaModel> ideasBox;

// Reminders Box
Box<ReminderModel> remindersBox;

// Tags Box
Box<TagModel> tagsBox;

// Vault Box (Encrypted)
Box<VaultItemModel> vaultBox;

// Settings Box
Box<AppSettingsModel> settingsBox;

// Auth Box (Secure Storage)
Box<UserAuthModel> authBox;
```

### Encryption Strategy

```
User Data Flow:
1. User creates PIN → Derives encryption key using Argon2
2. Key stored in flutter_secure_storage
3. All Hive boxes encrypted with this key
4. Vault box has additional layer of encryption
5. Sync: Data encrypted before upload (zero-knowledge)
```

---

## 8. SECURITY IMPLEMENTATION

### Key Management

```dart
class KeyManager {
  // Generate master key from PIN
  Future<String> deriveMasterKey(String pin) async {
    final salt = await _getOrCreateSalt();
    return Argon2().hashPasswordString(pin, salt);
  }
  
  // Store in secure storage
  Future<void> storeMasterKey(String key) async {
    await secureStorage.write(key: 'master_key', value: key);
  }
  
  // Retrieve key
  Future<String?> getMasterKey() async {
    return await secureStorage.read(key: 'master_key');
  }
}
```

### Encryption Service

```dart
class EncryptionService {
  Future<String> encrypt(String plainText, String key) async {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    final iv = IV.fromLength(16);
    return encrypter.encrypt(plainText, iv: iv).base64;
  }
  
  Future<String> decrypt(String encrypted, String key) async {
    final encrypter = Encrypter(AES(Key.fromUtf8(key)));
    final iv = IV.fromLength(16);
    return encrypter.decrypt64(encrypted, iv: iv);
  }
}
```

---

## 9. STATE MANAGEMENT (BLoC Pattern)

### Example: Document BLoC

```dart
// Event
abstract class DocumentEvent {}
class LoadDocuments extends DocumentEvent {}
class AddDocument extends DocumentEvent {
  final Document document;
  AddDocument(this.document);
}
class DeleteDocument extends DocumentEvent {
  final String id;
  DeleteDocument(this.id);
}

// State
abstract class DocumentState {}
class DocumentInitial extends DocumentState {}
class DocumentLoading extends DocumentState {}
class DocumentLoaded extends DocumentState {
  final List<Document> documents;
  DocumentLoaded(this.documents);
}
class DocumentError extends DocumentState {
  final String message;
  DocumentError(this.message);
}

// BLoC
class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final GetAllDocuments getAllDocuments;
  final AddDocument addDocument;
  final DeleteDocument deleteDocument;
  
  DocumentBloc({
    required this.getAllDocuments,
    required this.addDocument,
    required this.deleteDocument,
  }) : super(DocumentInitial());
}
```

---

## 10. API STRUCTURE (For Sync Feature)

### Backend Endpoints

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/verify-device

POST   /api/v1/sync/upload
GET    /api/v1/sync/download
GET    /api/v1/sync/status
POST   /api/v1/sync/resolve-conflict

GET    /api/v1/devices
DELETE /api/v1/devices/:id

POST   /api/v1/subscription/purchase
GET    /api/v1/subscription/status
```

### Zero-Knowledge Sync Flow

```
1. Client encrypts data locally with user's key
2. Client uploads encrypted blob to server
3. Server stores encrypted data (cannot decrypt)
4. Client downloads encrypted blob
5. Client decrypts with local key
```

---

## 11. TESTING STRATEGY

### Unit Tests
- Repository tests
- UseCase tests
- Encryption service tests
- Validation logic tests

### Widget Tests
- Custom widgets
- Page layouts
- Form validations

### Integration Tests
- Complete user flows
- Authentication flow
- Document CRUD operations
- Sync operations

### Test Coverage Target: 80%+

---

## 12. BUILD CONFIGURATION

### Environment Variables

```dart
// lib/core/config/env_config.dart

class EnvConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.personalos.app',
  );
  
  static const String syncEndpoint = '$apiBaseUrl/sync';
  static const bool enableSync = bool.fromEnvironment('ENABLE_SYNC');
  static const bool enableAds = bool.fromEnvironment('ENABLE_ADS');
}
```

### Build Flavors

```yaml
# Development
flutter run --flavor dev --dart-define=API_BASE_URL=https://dev-api.personalos.app

# Staging
flutter run --flavor staging --dart-define=API_BASE_URL=https://staging-api.personalos.app

# Production
flutter run --flavor prod --dart-define=API_BASE_URL=https://api.personalos.app
```

---

## 13. PERFORMANCE OPTIMIZATION

### Lazy Loading
- Load documents in pages (20 items/page)
- Use ListView.builder for large lists
- Implement pagination for search results

### Caching Strategy
- Cache frequently accessed data in memory
- Use Hive for persistent cache
- Clear cache on logout

### Image Optimization
- Compress images before storage
- Generate thumbnails for documents
- Use cached_network_image for remote images

---

## 14. ACCESSIBILITY & LOCALIZATION

### Accessibility
- Semantic labels for screen readers
- Minimum touch target size: 48x48 dp
- High contrast mode support
- Font scaling support

### Localization
```
lib/l10n/
├── app_en.arb
├── app_es.arb
├── app_fr.arb
└── app_hi.arb
```

---

## 15. DEPLOYMENT CHECKLIST

### Pre-launch
- [ ] Security audit complete
- [ ] Encryption tested thoroughly
- [ ] Privacy policy published
- [ ] Terms of service ready
- [ ] App store assets prepared
- [ ] Beta testing completed
- [ ] Performance benchmarks met
- [ ] Offline functionality verified

### Post-launch
- [ ] Analytics integrated (privacy-focused)
- [ ] Crash reporting enabled
- [ ] User feedback system
- [ ] Support documentation
- [ ] Monitoring dashboards

---

## 16. FUTURE ENHANCEMENTS (Post-MVP)

- Web clipper browser extension
- Desktop widget integration
- API for third-party integrations
- Advanced search with AI
- Custom templates for documents
- Collaboration features (optional)
- Dark mode variants
- Widget support for home screen

---

## 17. DOCUMENTATION REQUIREMENTS

- [ ] API documentation (if sync enabled)
- [ ] User guide
- [ ] Developer onboarding guide
- [ ] Security whitepaper
- [ ] Privacy documentation
- [ ] Architecture decision records (ADRs)

---

This technical document provides the complete structure for building the Personal OS application using clean architecture principles with a feature-based approach.