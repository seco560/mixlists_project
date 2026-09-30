# YouTube Music playlists (pending import)

Raw `YTMusic().get_playlist(id, limit=None)` responses from
[ytmusicapi](https://github.com/sigma67/ytmusicapi) 1.12.3, fetched
unauthenticated on 2026-09-30. One file per playlist, named by playlist id. 
They're kept in the repo so the import can be finished on any machine. They are **not** bundled with the app, because
`pubspec.yaml` lists only `assets/database/mixlists.db`.

| File | Title | Tracks |
|---|---|---|
| `PLhKHCVhC73KxoYBKVBbuvF4cm7pLmvJPy.json` | gap in the fence | 17 |
| `PLhKHCVhC73Kx032XTML7g41RpUA6tbBRi.json` | it's Ok // we are One | 28 |
| `PLhKHCVhC73KwjCZgGd-JR2I2V2dSJhdYT.json` | valentine's day (not now) | 17 |
| `PLhKHCVhC73KzM2lDPF3j1AAyqHKsqNYTt.json` | today is tomorrow's yesterday | 24 |
| `PLhKHCVhC73Kz7Drg0y4u5cfob-r_xrT5E.json` | head change | 15 |

## Plan

1. Match each track to a Spotify track (title + artists + duration via Spotify
   search). Pace the requests: a burst of ~600 calls once earned a ~22h 429
   lockout. Review unclear matches by hand.
2. Import the matched tracks through the normal Spotify ingestion path
   (`MixlistIngestion`), so artists, albums and dedup behave like any other
   mixlist.
3. Slot the five playlists into the chronology by **renumbering mixlist ids**
   (ids are the chronological order; see CLAUDE.md). `SongsMixlists.mixlist`
   references them, so renumber inside one transaction with foreign keys on.

## Caveats

- **No per-track "date added"**: YouTube Music only reports `year: 2026` per
  playlist, so each playlist's date/position has to be supplied by hand.
  We might end up just guesstimating a date and putting that down for each song.
- 15 of the 101 tracks are user uploads (`videoType: MUSIC_VIDEO_TYPE_UGC`)
  rather than official releases, and are the likeliest to need a manual match.
  Those could have some special entries created for them.
