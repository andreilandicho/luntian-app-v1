# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


flutter_application_1
├─ 📁.dart_tool
├─ 📁android
│  ├─ 📁.gradle
│  │  -> gradle files
│  ├─ 📁app
│  │
├─ 📁api
│  ├─ 📄check-email-citizen.js
│  ├─ 📄check-email-exists.js
│  ├─ 📄email-expired-reports.js
│  ├─ 📄reset-password.js
│  ├─ 📄send-otp.js
│  └─ 📄verify-otp.js
├─ 📁assets
│  ├─ 📁fonts
│  │  ├─ 📄Marykate.ttf
│  │  └─ 📄Poppins Regular 400.ttf
│  ├─ 📄background.png
│  ├─ 📄barangay.png
│  ├─ 📄clean.jpg
│  ├─ 📄event.jpg
│  ├─ 📄garbage.png
│  ├─ 📄logo only luntian.png
│  ├─ 📄profile picture.png
│  └─ 📄profilepicture.png
├─ 📁backend
│  ├─ 📁controllers
│  │  ├─ 📄notifCitizensForEvent.js
│  │  ├─ 📄notifController.js
│  │  └─ 📄notifEventController.js
│  ├─ 📁db_backups
│  │  └─ 📄2025_10_05db_backup.sql
│  ├─ 📁node_modules
│  ├─ 📁routes
│  │  ├─ 📁maintenance
│  │  │  ├─ 📄official_reports.js
│  │  │  └─ 📄user_official.js
│  │  ├─ 📄auth.js
│  │  ├─ 📄badges.js
│  │  ├─ 📄barangays.js
│  │  ├─ 📄events.js
│  │  ├─ 📄getReportsAssignedToAnOfficial.js
│  │  ├─ 📄leaderboards.js
│  │  ├─ 📄notif.js
│  │  ├─ 📄rating.js
│  │  ├─ 📄reports.js
│  │  ├─ 📄users.js
│  │  ├─ 📄user_notifications.js
│  │  ├─ 📄viewEventsInitiatives.js
│  │  └─ 📄viewOfficialRequests.js
│  ├─ 📄package-lock.json
│  ├─ 📄package.json
│  ├─ 📄server.js
│  └─ 📄supabaseClient.js
├─ 📁lib
│  ├─ 📁models
│  │  ├─ 📁maintenance
│  │  │  ├─ 📄pending_report.dart
│  │  │  └─ 📄submitted_solutions.dart
│  │  ├─ 📄event_model.dart
│  │  ├─ 📄homepage_event_model.dart
│  │  ├─ 📄post_model.dart
│  │  ├─ 📄report_model.dart
│  │  ├─ 📄solved_report_model.dart
│  │  ├─ 📄user_model.dart
│  │  └─ 📄user_official_model.dart
│  ├─ 📁screen
│  │  ├─ 📁admin
│  │  │  ├─ 📁widget notif
│  │  │  │  ├─ 📄event_dialog.dart
│  │  │  │  ├─ 📄event_notif.dart
│  │  │  │  └─ 📄report_notif.dart
│  │  │  ├─ 📁widget reports
│  │  │  │  ├─ 📄inprogress_card.dart
│  │  │  │  ├─ 📄report_card.dart
│  │  │  │  └─ 📄resolved_card.dart
│  │  │  ├─ 📄admin_dashboard.dart
│  │  │  ├─ 📄admin_dashboard_stub.dart
│  │  │  ├─ 📄forgot_screen.dart
│  │  │  ├─ 📄html_stub.dart
│  │  │  ├─ 📄html_web.dart
│  │  │  ├─ 📄inprogress.dart
│  │  │  ├─ 📄leaderboard.dart
│  │  │  ├─ 📄login_screen.dart
│  │  │  ├─ 📄notification_screen.dart
│  │  │  ├─ 📄pdf_download_stub.dart
│  │  │  ├─ 📄pdf_download_Web.dart
│  │  │  ├─ 📄pending.dart
│  │  │  ├─ 📄profile_screen.dart
│  │  │  ├─ 📄report_pdf.dart
│  │  │  ├─ 📄request_screen.dart
│  │  │  ├─ 📄resolved.dart
│  │  │  ├─ 📄signup_screen.dart
│  │  │  ├─ 📄threshold.dart
│  │  │  ├─ 📄web_utils.dart
│  │  │  ├─ 📄web_utils_stub.dart
│  │  │  └─ 📄web_utils_web.dart
│  │  ├─ 📁official_mobile
│  │  │  ├─ 📄action.dart
│  │  │  ├─ 📄completed_reports_page.dart
│  │  │  ├─ 📄leaderboard.dart
│  │  │  ├─ 📄notificationpage.dart
│  │  │  ├─ 📄official.dart
│  │  │  ├─ 📄PendingReportDetailPage.dart
│  │  │  ├─ 📄pending_reports_page.dart
│  │  │  ├─ 📄profilepage.dart
│  │  │  ├─ 📄review_submission_page.dart
│  │  │  ├─ 📄submitted_solutions.dart
│  │  │  ├─ 📄upload.dart
│  │  │  └─ 📄view_report.dart
│  │  ├─ 📁super_admin
│  │  │  └─ 📄super_admin_dashboard.dart
│  │  └─ 📁user
│  │     ├─ 📄add_event_screen.dart
│  │     ├─ 📄add_screen.dart
│  │     ├─ 📄change_password_screen.dart
│  │     ├─ 📄event_Screen.dart
│  │     ├─ 📄feedback_screen.dart
│  │     ├─ 📄forgot_screen.dart
│  │     ├─ 📄home_screen.dart
│  │     ├─ 📄leaderboard_screen.dart
│  │     ├─ 📄loading_screen.dart
│  │     ├─ 📄login_screen.dart
│  │     ├─ 📄notification_detail_screen.dart
│  │     ├─ 📄notification_screen.dart
│  │     ├─ 📄profile_screen.dart
│  │     ├─ 📄report_card.dart
│  │     ├─ 📄reset_password_screen.dart
│  │     ├─ 📄search_screen.dart
│  │     ├─ 📄signupemailscreen.dart
│  │     ├─ 📄signupotpverification.dart
│  │     ├─ 📄signup_screen.dart
│  │     ├─ 📄solved_report_card.dart
│  │     └─ 📄update_profile_screen.dart
│  ├─ 📁services
│  │  ├─ 📁maintenance
│  │  │  ├─ 📄pending_report_service.dart
│  │  │  ├─ 📄solution_service.dart
│  │  │  └─ 📄submitted_solution_service.dart
│  │  ├─ 📄auth_service.dart
│  │  ├─ 📄barangay_service.dart
│  │  ├─ 📄event_service.dart
│  │  ├─ 📄official_profile_service.dart
│  │  ├─ 📄profile_service.dart
│  │  ├─ 📄rating_service.dart
│  │  └─ 📄report_service.dart
│  ├─ 📁utils
│  │  ├─ 📁email-templates
│  │  │  └─ 📄escalated-report.html
│  │  ├─ 📄cron.js
│  │  ├─ 📄image_helper.dart
│  │  ├─ 📄mailer.js
│  │  └─ 📄redisClient.js
│  ├─ 📁widgets
│  │  └─ 📁official
│  │     ├─ 📄offaction.dart
│  │     ├─ 📄offcompleted_post_card.dart
│  │     ├─ 📄offleaderboard.dart
│  │     ├─ 📄offluntian_footer.dart
│  │     ├─ 📄offluntian_header.dart
│  │     ├─ 📄offnotification.dart
│  │     ├─ 📄offpending_post_card.dart
│  │     ├─ 📄offreview_submission.dart
│  │     ├─ 📄offsubmitted_solution_card.dart
│  │     └─ 📄offviewreport.dart
│  └─ 📄main.dart
├─ 📄.gitignore
├─ 📄.metadata
├─ 📄analysis_options.yaml
├─ 📄devtools_options.yaml
├─ 📄package-lock.json
├─ 📄package.json
├─ 📄pubspec.lock
├─ 📄pubspec.yaml
├─ 📄README.md
└─ 📄vercel.json