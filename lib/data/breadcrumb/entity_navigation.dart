import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/models/album_overview.dart';
import 'package:mixlists_project/data/models/artist_overview.dart';
import 'package:mixlists_project/data/models/song_overview.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/albums/album_detail_screen.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/artists/genre_artists_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/screens/songs/song_detail_screen.dart';

// The one way to open each detail screen, so every tile/link pushes the
// same screen with the same breadcrumb entry.

void openMixlist(
  BuildContext context,
  Mixlist mixlist, {
  int? highlightSongId,
  bool isReverse = false,
}) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(
      kind: BreadcrumbKind.mixlist,
      entityId: mixlist.id,
      title: mixlist.title,
    ),
    builder: (context) =>
        MixlistDetailScreen(mixlist: mixlist, highlightSongId: highlightSongId),
    isReverse: isReverse,
  );
}

Future<void> openMixlistById(
  BuildContext context,
  int mixlistId, {
  int? highlightSongId,
}) async {
  final mixlist = await getIt<MusicLibraryRepository>().getMixlistById(
    mixlistId,
  );
  if (!context.mounted || mixlist == null) return;
  openMixlist(context, mixlist, highlightSongId: highlightSongId);
}

void openArtist(BuildContext context, ArtistOverview artist) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(
      kind: BreadcrumbKind.artist,
      entityId: artist.id,
      title: artist.name,
      mosaicUrls: [for (final a in artist.albums.take(4)) a.coverImageURL],
    ),
    builder: (context) => ArtistDetailScreen(artist: artist),
  );
}

Future<void> openArtistById(BuildContext context, int artistId) async {
  final artist = await getIt<MusicLibraryRepository>().getArtistOverviewById(
    artistId,
  );
  if (!context.mounted || artist == null) return;
  openArtist(context, artist);
}

void openAlbum(BuildContext context, AlbumOverview album) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(
      kind: BreadcrumbKind.album,
      entityId: album.id,
      title: album.name,
      subtitle: album.artistName,
      imageUrl: album.coverImageURL,
    ),
    builder: (context) => AlbumDetailScreen(album: album),
  );
}

Future<void> openAlbumById(BuildContext context, int albumId) async {
  final album = await getIt<MusicLibraryRepository>().getAlbumOverviewById(
    albumId,
  );
  if (!context.mounted || album == null) return;
  openAlbum(context, album);
}

void openSong(BuildContext context, SongOverview song) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(
      kind: BreadcrumbKind.song,
      entityId: song.id,
      title: song.name,
      subtitle: song.artistNames,
      imageUrl: song.albumCoverImageURL,
    ),
    builder: (context) => SongDetailScreen(song: song),
  );
}

Future<void> openSongById(BuildContext context, int songId) async {
  final song = await getIt<MusicLibraryRepository>().getSongOverviewById(
    songId,
  );
  if (!context.mounted || song == null) return;
  openSong(context, song);
}

void openGenre(BuildContext context, String genre, {bool isReverse = false}) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(kind: BreadcrumbKind.genre, key: genre, title: genre),
    builder: (context) => GenreArtistsScreen(genre: genre),
    isReverse: isReverse,
  );
}

void openLabel(BuildContext context, String label, {bool isReverse = false}) {
  pushWithBreadcrumb(
    context,
    entry: BreadcrumbEntry(kind: BreadcrumbKind.label, key: label, title: label),
    builder: (context) => AlbumsGridScreen(recordLabel: label),
    isReverse: isReverse,
  );
}
