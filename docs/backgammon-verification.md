# Backgammon implementation handoff

Implementation phase for t_0b0b315f; independent acceptance belongs to Kiro t_3740968a. Workspace /home/gsus/wuerfelblock, branch master, starting HEAD 6c130e3ba05c7cad29cee827fc7c062e38fbd807. Changes are local and uncommitted. No push, commit, tag, release, upload, deployment, Actions invocation, or vault change. Pixel's pre-existing untracked docs/backgammon-design.md preserved.

## Delivered

Classical offline two-human Backgammon, physical/manual or secure digital dice. Fixed light/dark names and direction, opening/ties, hits/bar priority/entry, doubles, exact/oversized bearing off, globally maximal dice use and higher-value obligation, explicit turn completion, all three victory types. No doubling or match system; setup/help clearly disclose this. Persisted immutable board, roll consumption and move-only undo history. Pending-save state retained, all progress blocked until exact retry; winning results only become visible after successful save. Complete setup/start/continue/rules/result integration with DE/EN. Native move list is primary at 200% text; minimum-width scrollable wooden board remains available. Pip counts and complete 24-point overview provided.

New production files: lib/models/backgammon_models.dart, lib/controllers/backgammon_controller.dart, lib/screens/backgammon_game_screen.dart, lib/screens/backgammon_rules_screen.dart, lib/widgets/backgammon_board.dart.
Integration files: lib/app.dart, lib/screens/setup_screen.dart, lib/screens/home_screen.dart, lib/screens/rules_selection_screen.dart, lib/services/game_repository.dart, tool/translations_en.json, generated lib/l10n/translations.g.dart, pubspec.yaml.
Tests: four new test/backgammon_*_test.dart files; existing widget_test.dart, colordice_widget_test.dart, rules_ux_test.dart updated for actual scrolling with the expanded selection and revised home copy.
Flutter automatically added android.builtInKotlin=false and android.newDsl=false with migration comments to android/gradle.properties during the requested release build. No signing/build dependencies were changed manually.

## Verification

- Rules source https://www.bkgm.com/rules.html re-extracted in full including movement rule 4, bar entry, bearing off and win types.
- flutter test --no-pub test/backgammon_integration_test.dart: successful before additional matrix tests.
- Targeted domain/controller/UI/integration run: 38 passed before two additional domain cases.
- Targeted old-game regression run: 56 passed.
- Final domain run: 13 passed, including a complete seeded game from classical setup through victory with save roundtrips.
- flutter analyze --fatal-infos: exit 0, No issues found.
- Final flutter test --no-pub: exit 0, 469 tests passed.
- git diff --check: exit 0.
- dart format --output=none --set-exit-if-changed lib test: exit 1 due ONLY to three untouched HEAD files: quattrodice_models.dart, quattrodice_game_screen.dart, quattrodice_rules_screen.dart. Extracting these exact files from HEAD and checking them independently reproduces exit 1. No unrelated formatting applied. Changed/new Dart files checked separately: exit 0.
- flutter build apk --release --target-platform android-arm64: exit 0, signed production APK generated. Existing Gradle/AGP/Kotlin future-support warnings remain, no dependency upgrade attempted.

Logs under /home/gsus/wuerfelblock/build: backgammon-analyze-final.log, backgammon-full-test-final.log, backgammon-release-build.log, backgammon-format.log, backgammon-format-baseline.log, backgammon-format-owned.log, backgammon-targeted-final.log, backgammon-domain-final.log, backgammon-regression.log. Earlier failed test logs retained: compilation mistake fixed; initial fullsuite's six tests were outdated copy/scroll assumptions, fixed and verified by the final suite.

## Production visual checks

PNG directory /home/gsus/wuerfelblock/build/backgammon-screenshots contains DE/EN portrait360x800/landscape800x360, 100%/200%, plus selection, bar9stack, doubles, bearoff, error and win. Forge loaded actual images: selection.png, bar9stack.png, start-de-2-360.png, board-en-2-800.png, error.png, win.png, start-en-1-360.png. Walnut/leather/checker materials and count badges are distinguishable; white checkers received darker outlines. Portrait deliberately shows a scrollable home-board slice rather than shrinking all 24 points. 200% labels wrap, actions remain scroll-reachable; the long German opening heading can break within the word at large text, without clipped/overflowed text. Tests exercise board and native list access, manual input and error/retry paths at large text. No real-device TalkBack/physical Android installation performed.

Calculated opaque sRGB WCAG contrast: text #382D36 / paper #FFFAF3 = 12.66:1; plum #673A62 / paper = 8.57:1; paper selection halo / red point #783F36 = 7.89:1, / green #486052 = 6.59:1; light-checker dark outline #68432D / darkest inlay #CABB9E = 4.57:1; dark-checker outline #121916 / inlay = 9.45:1. Native target/count badges use text/paper. Dual paper/plum selection outlines provide contrast on both leather and triangles.

## Internal APK only — Kiro delivers

SUPERSEDED: the universal APK described below is not the delivered update. Its versionCode 65 is lower than the installed release's 2064 and it includes foreign plugin ABIs. Use only the independently accepted split APK in the final section.

Path /home/gsus/wuerfelblock/build/wuerfelblock-v1.18.0+65-arm64.apk
SHA256 da3c5d9dc13991427f125fc4b59415028e4e5abac40586a234916ce59c9ecf57
Package at.weltenwanderer.wuerfelblock; versionName 1.18.0; versionCode 65; minSdk24; targetSdk36. v2 APK signature verified by apksigner. Certificate SHA256 e02887b69d0e8c6d4a927c775d0a34bfa8f445132ecfa14b711c177fe13b92ef.
Compared against the actual existing GitHub release v1.17.38+64 APK, downloaded read-only into build/backgammon-baseline (no release writes). Baseline SHA256 5e28f0c2b5b54eab37baa4a0cad6c509ddca54b9f0cbbf02571b0c1139e446e5 matches GitHub asset digest; apksigner confirms exactly the same certificate.
ARM64 libapp.so SHA256 changed from 4446159773c73e6e1252614ae031fdff37ba4b1e17aead4fefc5b4cbe549b2f0 to bcaa59ace2cb4e8b49a93145c58c408b27136191d0d62923b3ebcd7bb012e2f1. Flutter engine and app AOT are arm64-v8a only. The shared_preferences datastore native helper also packages armeabi-v7a/x86_64 variants, so aapt lists three native ABIs; these other ABIs do not contain libapp.so/libflutter.so. Only permission is app-scoped DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION; no INTERNET or sensitive permission.

## Remaining boundaries

Independent review and device testing remain with Kiro. No doubling, bot, online or match/Crawford system. Full-repository formatter cleanliness is pre-existing debt, demonstrated against HEAD and not hidden. Required skills development-workflow/flutter-project-workflow loaded; requested app-projects/game-domain-engineering/persistence references were not present in the available skill installation, so repository patterns and authoritative rule source were used directly. Actual provider/model for parent and both scoped internal helpers: openai-codex / gpt-6.1-sol; no fallback.

## Kiro independent acceptance — 2026-10-10

- Read production domain, controller, shared transaction helper, board geometry/paint/hit regions, screen/rules, setup/resume routes and repository diff. Existing persistence key and discriminators remain unchanged.
- Independently reran all four Backgammon test files: 40 passed, covering maximal use, higher die, bar, oversized bearing off, opening/doubles, exact failed-save retry with no RNG, undo, resume and all victory classes. This run regenerated the production PNGs.
- Personally viewed selection, bar9stack, start-de-1-360, start-de-2-360, board-de-2-800, error and win PNGs. Board/checker materials, legal targets, stack counts, save-error retry and English victory are readable. Large-text German opening title wraps inside the word; this minor cosmetic limitation is disclosed. Portrait uses a horizontally scrollable board; 200% text defaults to the native move list, with the board still accessible. No overflow occurred in the DE/EN portrait/landscape matrix.
- Added test/backgammon_acceptance_test.dart: 7 additional production-path tests, including real SharedPreferences repository with mocked platform storage and the original active_game_v1 key, legacy untyped classic save, retained undo, all 3 completed-result types in DE/EN at 200% text, both game-help and home rule-selection routes. Ran these plus existing repository tests: 13 passed. Total independently exercised: 53 test cases; parent full-suite log shows 469 passed before these 7 additions. Full suite not redundantly rerun.
- Confirmed actual original release APK versionCode 2064. Rebuilt locally using `flutter build apk --release --target-platform android-arm64 --split-per-abi`; exit 0. No production changes needed. Final versionCode 2065, not 65.
- FINAL DELIVERABLE: /home/gsus/wuerfelblock/build/wuerfelblock-v1.18.0+65-arm64-test.apk
- SHA256: bf4647ee8e641f66f08c2eadbc77a8c6642ec096b6fe5cd64fd7ec7249f85ce6; size 37905872 bytes.
- Package at.weltenwanderer.wuerfelblock; versionName 1.18.0; versionCode 2065; minSdk24/targetSdk36. apksigner verifies v2 and the same original certificate SHA256 e02887b69d0e8c6d4a927c775d0a34bfa8f445132ecfa14b711c177fe13b92ef.
- Every native library (libapp, libflutter, datastore counter) is exclusively arm64-v8a. AOT SHA256 bcaa59ace2cb4e8b49a93145c58c408b27136191d0d62923b3ebcd7bb012e2f1 differs from original release. Only app-scoped DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, no network/sensitive permissions.
- Evidence: build/backgammon-kiro-tests.log, build/backgammon-kiro-acceptance.log, build/backgammon-kiro-split-build.log, build/backgammon-kiro-apk-verification.json.
- No commit/push/release/remote APK publication. Device install/rotation/TalkBack and practical two-player acceptance remain with Günther; install as an update without uninstalling. No doubling/bot/online/match system. Actual model openai-codex/gpt-6.1-sol; no fallback.
