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
  - `lib/get_it_init.dart` + `lib/main.dart` — DI via `get_it`; singletons (`LibraryManager`, `MusicLibraryRepository`, `ActiveLibraryController`, `SpotifyClientIdStore`, `MixlistFilterController`, `ThemeController`, `BreadcrumbController`, `DuplicateSongIndexController`) are registered once at startup in `main()`.
  - `lib/screens/` and `lib/widgets/` — UI, organized by feature area (`albums/`, `artists/`, `mixlists/`, `songs/`, `search/`, `home/`, `library/`, `spotify_import/`, `breadcrumb/`). Widgets used by more than one feature area live in `lib/widgets/shared/`.
- **`bin/`** holds one-off, already-run maintenance/migration scripts (`backfill_new_format_data.dart`, `squash_duplicate_albums.dart`) — not part of the shipped app, kept for reference/precedent rather than reuse. See "Maintenance scripts" below.

Two future phases are deliberately deferred pending further design (not lower priority, just not concretely specified yet): MusicBrainz/ownership-link enrichment, and an editorial layer (song/mixlist notes, collection tags).

## Domain knowledge & invariants

Code comments are kept to ≤3 lines; the reasoning behind non-obvious decisions lives here instead. Keep it that way — add the "why" here, not in long code comments.

### Mixlists vs. playlists (the filter)

- `Mixlists.is_mixlists` (schema v5, 0/1, default 0) marks a playlist as one of the user's curated "mixlists" rather than any playlist pulled in by a bulk import. Nothing is a mixlist until marked via the "Mark Mixlists" screen (`setMixlistFlags`, currently the **only write path** in the repository).
- `MixlistFilterController` holds the app-wide tri-state filter (all / mixlists only / non-mixlists only). In-memory, not persisted, and it survives navigation. Screens add a listener and reload; `MixlistFilterToggle` (drop into any AppBar's `actions`) reads/writes it directly.
- The filter exists twice: in SQL (`_mixlistFilterSql` in `mixlist_queries.dart`, interpolating a literal 0/1, safe because it's a closed enum) and in memory (`MixlistFilter.matches`) for re-scoping data already fetched.
- Filtered semantics: list/overview queries **drop** entities with zero qualifying appearances (and an artist's `albums` only lists albums with a qualifying song). But `getArtistOverviewById` always returns the artist: filtering thins what's inside a detail view, it never makes an already-selected entity disappear. `ArtistDetailScreen` must read albums/mixlists from its re-fetched `_artist`, not `widget.artist`, or the filter won't apply.
- Wording (`mixlist_wording.dart`): generic UI says "Mixlist" under the default mixlists-only filter and "Playlist" otherwise. The marking feature's own vocabulary (toggle labels, "Mark Mixlists", the "Non-Mixlists" header) always says "mixlist". `AllMixlistsScreen` words its UI from the real global filter, not marking mode's temporary show-everything override.
- Search is fetched unfiltered. `SearchResults` carries a `MixlistScopeIndex` (per artist/album/genre/label: appears on a mixlist and/or a plain playlist; built in one pass, cached indefinitely, invalidated on library switch and `setMixlistFlags`) and re-scopes in memory via `scopedTo` when the filter changes. `MixlistSummary.isMixlist` is only populated for this purpose.

### Mixlist ordering and numbering

- `Mixlists.id` order **is** chronological order: mixlists are never deleted, so ids have no gaps, and the Spotify importer inserts playlists sorted by earliest track `added_at` (`ordering.dart`). `dateCreated` is only a `min(added_at)` proxy (Spotify exposes no creation date) and can drift, so never order by it. The heuristic is known-imperfect (a playlist duplicated from an older one looks old), so sanity-check the proposed order once per bulk import.
- A mixlist's display number is its 1-based position in id order **under the current filter** (`getMixlistPosition`), computed from `(id, filter)` because the detail screen has many entry points. Prev/next (`getAdjacentMixlists`) step within the same filtered set. Reversing `AllMixlistsScreen`'s display order never renumbers; numbers come from the oldest-first order.
- `DuplicateSongIndexController` (the "also on…" badge on the mixlist detail screen) is a getIt singleton that loads eagerly (the self-join is expensive) and reloads on filter change, library switch, or `MusicLibraryRepository` notifying listeners after a write. Await `ready` for an initial load; `value` can still hold the previous filter's data.

### Repository

- `MusicLibraryRepository` is a `ChangeNotifier` only so derived caches hear about writes. Query methods are `extension`s in `part` files, so they call `_notifyMutated()` (wraps `@protected notifyListeners`) after invalidating caches.
- `switchTo(newDb)` closes the old db, rebuilds `ingestion` (it captures `_db`) and invalidates every cached query. `BreadcrumbController` clears the trail on library switch (ids are per-library).
- Songs have no structured per-artist credits: `Songs.artists` is a denormalized display string, so song detail shows artists as plain text and only links the album.

### Libraries and databases

- The bundled asset db can already contain tables/data while sqflite treats it as new (`user_version` unset), so the schema is only created if it's genuinely empty. User-created libraries are always new or app-created, so they skip that check.
- Export reads raw sqlite bytes; safe while the db is open because nothing uses WAL mode.
- On web there's no library switching yet: `LibraryManager.bootstrap` takes a web-specific shortcut and the manifest file is never touched.
- `bin/` scripts and any standalone sqflite_common_ffi code must open dbs by **absolute path**: a relative path resolves against `.dart_tool/sqflite_common_ffi/databases/`, silently creating a different, empty db.

### Ingestion and dedup (`mixlists_core`)

- `MixlistIngestion` is the single write path for importing mixlists from `MixlistCsvRow`s, whether parsed from CSV or built from Spotify API objects. Used by "Add New Mixlist", the Spotify importer and the `bin/` scripts.
- General posture: **ambiguous means don't guess**. Zero or 2+ candidate matches → insert a new row (ingestion) or skip (supplement).
- Albums: match by `spotifyURI`, then case-insensitive `(name, artistId)`, because Spotify serves different URIs for the same album (reissues, regional variants, messy small-label metadata). On a fallback match the stored URI is refreshed. A URI-only match once split albums across 2–4 duplicate rows in a real bulk import.
- Songs: URI, then a same-album `(name, duration)` match with no artist check, then a library-wide fallback that **must** also match the artist. Without it, two different "Note to Self" songs by different artists were once merged into one row (there's a regression test). A library-wide match doesn't reassign album/artist.
- Name/title comparisons happen in Dart, not SQL: sqlite's `lower()` is ASCII-only.
- Known residual behaviour: artist/album get-or-create runs before song get-or-create, so if the song already exists under another album (e.g. a deluxe reissue), the just-created Album row can be left with zero songs.
- Schema v4 adds partial unique indexes on the `spotifyURI` columns (`WHERE spotifyURI IS NOT NULL`). Each index is created independently and a failure is only a warning, because older live dbs can contain duplicate URIs from past bugs.
- `mixlist_supplement.dart` backfills genres/record label/popularity/audio features from CSV (e.g. Exportify) onto **existing** songs: the Spotify Web API no longer serves these four fields to personal (non-Extended-Quota) apps. Matching is library-wide: URI → ISRC → `(name, durationMs ±1000ms)`. It only fills nulls, adds `SongsAudioFeatures` only if absent, and never inserts songs or touches `SongsMixlists`.
- `mergeMixlistCsvRows` combines two exports of the same mixlist (older app-native: URIs/art/ISRC/disc numbers; newer Exportify-style: genres/label/audio features), matched by track URI. The primary's order and non-null fields win, the secondary fills nulls, and secondary-only tracks are appended.

### Spotify import

- Auth is bring-your-own Client ID (Dev Mode caps a shared app at 25 users). The Client ID isn't secret in PKCE, so it lives in plain `shared_preferences`. Tokens are stored with the Client ID they were issued under, so refresh never needs it again. Always persist refreshed tokens: Spotify may rotate the refresh token.
- PKCE (no client secret) and a loopback **IP literal** redirect (`http://127.0.0.1:<port>/callback`; Spotify rejects `localhost`) are Spotify requirements. Desktop stores tokens in a chmod'd per-user JSON file (only a read-only-scoped refresh token is sensitive). Mobile uses `flutter_web_auth_2` with `mixlists://spotify-callback`, which must be registered in `AndroidManifest.xml`/`Info.plist` **and** on the user's Spotify app. Mobile tokens go in `flutter_secure_storage`, implemented in app code because `spotify_import` stays plugin-free.
- API behaviour confirmed live against a Dev Mode app: followed-only playlists 403 on item access (filtered out proactively and counted); `/playlists/{id}/items` entries have a flat `item` and no `preview_url`/`popularity`/`label`; descriptions come HTML-escaped (`//` → `&#x2F;&#x2F;`); simplified artist objects lack `genres`, so genres cost one cached call per artist. Skip local files, delisted tracks (null `item`) and episodes. Pagination follows the `next` URL.
- `Albums.artist` is a single FK: the importer takes the first credited album artist as canonical (the old CSV comma-join workaround is gone).
- `SpotifyClient` forces one refresh on an unexpected 401, retries 429 (honouring `Retry-After`) and 5xx with backoff, and paces every request by a small fixed delay: Dev Mode's rate limit is an undisclosed rolling 30s window.

### UI notes

- Colours come from `Theme.of(context)` (see `AppTheme`), never hardcoded `Colors.*`; album art is never tinted. `ThemeController` is deliberately binary (no "system") so the toggle has one obvious next state.
- Breadcrumbs: only pushes to detail screens (song/album/artist/mixlist/genre/label) use `pushWithBreadcrumb`; other pushes stay plain so the trail ignores them. `BreadcrumbNavigatorObserver` is the only thing that mutates the trail, and `didPop` covers every removal cause. `BreadcrumbOverlay` wraps the whole app via `MaterialApp.builder`, so it sits **above** the app's Navigator: it keeps its own `Overlay` (with one persistent entry, since `initialEntries` is only read on first mount), and `jumpTo` pops via `route.navigator`, never `Navigator.of(context)`. The trail panel stays mounted for the app's lifetime, so per-open work must listen to `isOpen` rather than run in `initState`.
- `SongTableRow` must be keyed with `ValueKey(song.id)`: rows live in an eagerly built `Column`, and re-sorting would otherwise hand an expanded row's state to another song.
- Widgets under test (e.g. `MixlistAudioFeatureChart`) take values like the playlist noun as parameters instead of reading getIt, so tests can construct them with no service locator.
- Web images use `ImageRenderMethodForWeb.HttpGet`: the default HtmlImage renders black after ImageCache eviction (Flutter 3.47 engine regression).

### Maintenance scripts (`bin/`, already run)

Both work on a backup + working copy of `--db` and only replace the original once the full run succeeds.

- `backfill_new_format_data.dart` (`[--db <path>] [--csv-dir <path>] [--apply-titles]`): merged the newer CSV exports in `assets/mixlists_new_format/` (no artist/album URIs, but genres/label/audio features). Files were matched to existing mixlists by Track URI overlap (majority threshold; real data was ~90–100% or ~0%), never by filename, since some filenames had punctuation stripped. It filled null fields on known songs without touching URI/disc/ISRC data and inserted new songs/mixlists via get-or-create. Title renames needed `--apply-titles`, because some existing titles had already lost characters in the 2018-era seeding.
- `squash_duplicate_albums.dart` (`--db <path>`): repaired the album-URI split bug above. For each `(name, artist)` group it picks a canonical row (non-null `spotifyURI` first, then highest id), backfills its null label/cover, repoints `Songs.album` and deletes the duplicates. It then merges exact-name song collisions **within each merged album only** (library-wide would wrongly merge e.g. a studio track and its compilation copy), backfilling `SongsExtraData`, adopting orphaned audio features and repointing `SongsMixlists` without creating duplicate pairs. Finally it deletes Albums with zero songs (the residual behaviour noted above).
