# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working agreement (read this first)

- **Never run or launch the app** (`flutter run`, launching a built executable, `tool/run_web.sh`, etc.) and **never take screenshots** to demonstrate or verify a change. Just finish the code change and tell the user it's done — they run/review it themselves.
- **You may and should** run `flutter analyze` and the unit test suites (`flutter test`, `dart test` inside a package) to check correctness — these are the verification tools for this project.
- **Never create git commits.** Only `git add`/stage files if the user explicitly asks you to for that turn — staging is not a default part of "finishing" a task.
- Optimize for easy review: keep diffs focused and let the user inspect/run/commit everything themselves rather than doing it for them.
- If a task involves repairing real data in a live library database (`bundled.db` or any user-created library), don't guess: investigate read-only first (throwaway `dart run bin/inspect_*.dart` scripts against the db are the established pattern here), cross-reference against Spotify's public pages or MusicBrainz's API before writing anything, ask the user rather than guess when something can't be independently verified, back up the db file before any write, wrap repairs in a transaction with pre-checks, and delete the one-off script afterward (it's incident-specific, unlike the real maintenance scripts in `bin/`).

## Commands

```
flutter pub get                          # install deps (run from repo root; also fetches workspace packages)
flutter analyze                          # static analysis across the app (excludes build/ and platform dirs, see analysis_options.yaml)
flutter test                             # run the app's widget/unit tests in test/
flutter test test/widget_test.dart       # run a single test file
dart test                                # run tests inside packages/mixlists_core or packages/spotify_import (cd into the package first)
dart test test/csv/mixlist_csv_merge_test.dart   # run a single test in a package
```

Web-only setup (only relevant if the user is the one running/building for web): the web build needs `web/sqlite3.wasm` and `web/sqflite_sw.js`, generated (not checked into git) via `dart run sqflite_common_ffi_web:setup`. `tool/run_web.sh` wraps `flutter run -d chrome` and generates them automatically if missing. This is part of the "don't run the app" boundary above — leave actually running it to the user.

CI (`.github/workflows/deploy-pages.yml`) builds and deploys the web target to GitHub Pages on push to `main`: `flutter pub get` → `dart run sqflite_common_ffi_web:setup` → `flutter build web --release`.

## Architecture

This is a Dart/Flutter **pub workspace** (declared in the root `pubspec.yaml`): the app at the repo root, plus two local packages under `packages/` that are the shared, stable foundation the app is built on. **Prefer putting new shared logic in these packages rather than duplicating it in app code**, and don't propose re-merging them back into a single target — the separation is intentional.

- **`packages/mixlists_core`** — Flutter-free core: the sqlite schema (`schema_v2`..`schema_v5`, applied cumulatively both on create and on upgrade), entity classes (`Album`, `Artist`, `Mixlist`, `Song`, etc.), the CSV row parser/merge logic, and the get-or-create/dedup ingestion logic (`MixlistIngestion`, `mixlist_supplement.dart`). This package is also used by the separate `mixlists_importer` CLI (now retired as an active dev location; this workspace is the single source of truth), so schema/dedup logic has one home.
- **`packages/spotify_import`** — Pure Dart (no Flutter plugin deps) Spotify OAuth (PKCE) + Web API client for importing a user's own playlists. Platform-specific pieces (redirect capture, secure token storage) deliberately live in the app instead: desktop uses a loopback server (`loopback_server.dart`), mobile uses `flutter_web_auth_2` with a custom URL scheme. Not used on web (Phase 1 excludes Spotify import from web).
- **App (`lib/`)** wires the two packages together and adds Flutter UI:
  - `lib/data/database/app_database.dart` — opens a library's sqlite file (via `sqflite_common_ffi` on desktop/Linux/Windows, `sqflite_common_ffi_web` on web, plain `sqflite` on mobile), seeding the bundled dataset once from `assets/database/mixlists.db` if missing, and applies schema migrations from `mixlists_core` on create/upgrade.
  - `lib/data/library/` — the **switchable libraries** model: each imported library (Spotify or CSV) is its own sqlite file under `<appSupportDir>/libraries/`, tracked in a JSON manifest (`LibraryManager` + `LibraryManifestStore`). The maintainer's bundled dataset is always registered as library id `"bundled"` and is the fallback if the active library's file is missing/corrupt. `ActiveLibraryController` holds the currently-active `LibraryRecord` for the UI.
  - `lib/data/repository/music_library_repository.dart` — the app's read query layer over the active database (`part`-file organization: `mixlist_queries.dart`, `artist_queries.dart`, `album_queries.dart`, `song_queries.dart`, `search_queries.dart`). Currently read-only by design ("strengthen when we implement editing DB entries" — see the doc comment in that file). `switchTo()` swaps the underlying `Database` when the active library changes and invalidates its caches.
  - `lib/data/spotify/` — app-side platform glue for `spotify_import`: picks desktop vs. mobile credential storage and redirect handling, stores the user's own Spotify Client ID (Spotify's Developer Dashboard caps a shared app at 25 users in Development Mode, so auth is bring-your-own-Client-ID).
  - `lib/get_it_init.dart` + `lib/main.dart` — DI via `get_it`; singletons (`LibraryManager`, `MusicLibraryRepository`, `ActiveLibraryController`, `SpotifyClientIdStore`, `MixlistFilterController`) are registered once at startup in `main()`.
  - `lib/screens/` and `lib/widgets/` — UI, organized by feature area (`albums/`, `artists/`, `mixlists/`, `songs/`, `search/`, `home/`, `library/`, `spotify_import/`).
- **`bin/`** holds one-off, already-run maintenance/migration scripts (`backfill_new_format_data.dart`, `squash_duplicate_albums.dart`) documented with their own usage/safety notes at the top of each file — not part of the shipped app, kept for reference/precedent rather than reuse.

Two future phases are deliberately deferred pending further design (not lower priority, just not concretely specified yet): MusicBrainz/ownership-link enrichment, and an editorial layer (song/mixlist notes, collection tags).
