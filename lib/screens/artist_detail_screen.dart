import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/artist_overview.dart';
import 'package:mixlists_project/models/artist_song_appearance.dart';
import 'package:mixlists_project/models/mixlist_summary.dart';
import 'package:mixlists_project/screens/mixlist_detail_screen.dart';

// Text scale borrowed from `MixlistDetailScreen`'s track tiles: a bold
// ~18px title for a row's identity (song/album name), ~14px semi-bold for
// its secondary line, and ~12px for meta info (dates), so this screen's
// typography doesn't feel out of step with the rest of the app.
const _titleTextStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
const _subtitleTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
const _metaTextStyle = TextStyle(fontSize: 12);
// Matches `MixlistDetailScreen`'s dense "also appears in" list style.
const _compactTitleTextStyle = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

class ArtistDetailScreen extends StatefulWidget {
  const ArtistDetailScreen({super.key, required this.artist});

  final ArtistOverview artist;

  @override
  State<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  List<ArtistSongAppearance> _songs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await getIt<MusicLibraryRepository>()
          .getArtistSongAppearances(widget.artist.id);
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading songs: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openMixlist(int mixlistId, int highlightSongId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>().mixlists
        .getById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MixlistDetailScreen(
          mixlist: fullMixlistData,
          highlightSongId: highlightSongId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView(
              children: [
                _SectionHeader('Songs on Mixlists (${_songs.length})'),
                if (_songs.isEmpty)
                  const _EmptySectionTile()
                else
                  for (final song in _songs)
                    _SongTile(song: song, onOpenMixlist: _openMixlist),
                const Divider(height: 32),
                _SectionHeader('Albums Featured (${artist.albums.length})'),
                if (artist.albums.isEmpty)
                  const _EmptySectionTile()
                else
                  for (final album in artist.albums)
                    ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: album.coverImageURL,
                        width: 48,
                        height: 48,
                      ),
                      title: Text(album.name, style: _titleTextStyle),
                      subtitle: Text(
                        album.releaseDate.split('T')[0],
                        style: _metaTextStyle,
                      ),
                    ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _EmptySectionTile extends StatelessWidget {
  const _EmptySectionTile();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Text('—'),
    );
  }
}

/// A song (left) paired with the mixlist it's on (right). A song with a
/// single mixlist appearance taps straight through to it -- one that
/// shows up on more than one mixlist expands in place to list them, same
/// "tap to reveal" idea as `MixlistDetailScreen`'s duplicate-track
/// handling. A mixlist with more than one song from this artist just
/// shows up as separate rows, one per song.
class _SongTile extends StatefulWidget {
  const _SongTile({required this.song, required this.onOpenMixlist});

  final ArtistSongAppearance song;
  final void Function(int mixlistId, int songId) onOpenMixlist;

  @override
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final hasSingleMixlist = song.mixlists.length == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CachedNetworkImage(
            imageUrl: song.albumCoverImageURL,
            width: 48,
            height: 48,
          ),
          title: Text(song.songName, style: _titleTextStyle),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.albumName, style: _subtitleTextStyle),
              Text(
                'Added on ${song.datesAdded.map((d) => d.split('T')[0]).join(', ')}',
                style: _metaTextStyle,
              ),
            ],
          ),
          trailing: hasSingleMixlist
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              song.mixlists.first.title,
                              style: _subtitleTextStyle,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              (song.mixlists.first.dateCreated ?? '').split(
                                'T',
                              )[0],
                              style: _metaTextStyle,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                )
              : Chip(label: Text('${song.mixlists.length} mixlists')),
          onTap: hasSingleMixlist
              ? () => widget.onOpenMixlist(song.mixlists.first.id, song.songId)
              : () => setState(() => _isExpanded = !_isExpanded),
        ),
        if (!hasSingleMixlist && _isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: song.mixlists
                  .map(
                    (mixlist) => _MixlistRow(
                      mixlist: mixlist,
                      onTap: () =>
                          widget.onOpenMixlist(mixlist.id, song.songId),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _MixlistRow extends StatelessWidget {
  const _MixlistRow({required this.mixlist, required this.onTap});

  final MixlistSummary mixlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        mixlist.title,
        style: _compactTitleTextStyle,
        textAlign: TextAlign.right,
      ),
      subtitle: Text(
        (mixlist.dateCreated ?? '').split('T')[0],
        style: _metaTextStyle,
        textAlign: TextAlign.right,
      ),
      onTap: onTap,
    );
  }
}
