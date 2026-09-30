import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mixlists_project/data/breadcrumb/entity_navigation.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/artist_connections.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/mixlists/hoverable_link.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/album_art_thumbnail.dart';
import 'package:mixlists_project/widgets/shared/empty_state.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/playlist_cover_grid.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';

/// "Six Degrees": the shortest chain of shared mixlists between two artists.
class SixDegreesScreen extends StatefulWidget {
  const SixDegreesScreen({super.key});

  @override
  State<SixDegreesScreen> createState() => _SixDegreesScreenState();
}

class _SixDegreesScreenState extends State<SixDegreesScreen> {
  final _random = Random();
  ArtistConnectionGraph? _graph;
  bool _isLoading = false;
  int? _fromId;
  int? _toId;
  ConnectionPath? _path;

  @override
  void initState() {
    super.initState();
    getIt<MixlistFilterController>().addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    getIt<MixlistFilterController>().removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final graph = await getIt<MusicLibraryRepository>()
          .getArtistConnectionGraph(
            filter: getIt<MixlistFilterController>().value,
          );
      if (!mounted) return;
      setState(() {
        _graph = graph;
        _isLoading = false;
        // Keep the picks that still exist under the new filter.
        if (_fromId != null && graph.artistById(_fromId!) == null) {
          _fromId = null;
        }
        if (_toId != null && graph.artistById(_toId!) == null) _toId = null;
        _path = _findPath();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
    }
  }

  ConnectionPath? _findPath({bool shuffle = false}) {
    final (graph, from, to) = (_graph, _fromId, _toId);
    if (graph == null || from == null || to == null) return null;
    return graph.shortestPath(from, to, random: shuffle ? _random : null);
  }

  void _select({int? from, int? to}) {
    setState(() {
      _fromId = from;
      _toId = to;
      _path = _findPath();
    });
  }

  /// A random artist and one of the artists furthest from them, for the
  /// longest chains.
  void _surpriseMe() {
    final graph = _graph;
    if (graph == null || graph.artists.length < 2) return;
    for (var attempt = 0; attempt < 20; attempt++) {
      final from = graph.artists[_random.nextInt(graph.artists.length)];
      final (farthest, _) = graph.farthestFrom(from.id);
      if (farthest.isEmpty) continue;
      _select(from: from.id, to: farthest[_random.nextInt(farthest.length)].id);
      return;
    }
  }

  Future<void> _pick({required bool isFrom}) async {
    final graph = _graph;
    if (graph == null) return;
    final picked = await showDialog<ConnectionArtist>(
      context: context,
      builder: (context) => _ArtistSearchDialog(artists: graph.artists),
    );
    if (picked == null) return;
    isFrom
        ? _select(from: picked.id, to: _toId)
        : _select(from: _fromId, to: picked.id);
  }

  @override
  Widget build(BuildContext context) {
    final graph = _graph;
    final noun = getIt<MixlistFilterController>().value.playlistNounPluralLower;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Six Degrees'),
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          if (_isLoading || graph == null)
            const Center(child: CircularProgressIndicator())
          else if (graph.artists.length < 2)
            EmptyState(message: 'Not enough artists on $noun to connect.')
          else
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  children: [
                    Text(
                      'How any two artists connect through the $noun they '
                      'share.',
                      style: metaTextStyle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ArtistPickerField(
                      label: 'From',
                      artist: _fromId == null
                          ? null
                          : graph.artistById(_fromId!),
                      onTap: () => _pick(isFrom: true),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert),
                        tooltip: 'Swap',
                        onPressed: _fromId == null && _toId == null
                            ? null
                            : () => _select(from: _toId, to: _fromId),
                      ),
                    ),
                    _ArtistPickerField(
                      label: 'To',
                      artist: _toId == null ? null : graph.artistById(_toId!),
                      onTap: () => _pick(isFrom: false),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.casino_outlined),
                          label: const Text('Surprise me'),
                          onPressed: _surpriseMe,
                        ),
                        if ((_path?.shortestRouteCount ?? 0) > 1)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Another route'),
                            onPressed: () => setState(
                              () => _path = _findPath(shuffle: true),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._result(context, noun),
                  ],
                ),
              ),
            ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: BreadcrumbTrailButton(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _result(BuildContext context, String noun) {
    if (_fromId == null || _toId == null) return const [];
    final path = _path;
    if (path == null) {
      return [
        EmptyState(
          icon: Icons.link_off,
          message: 'No chain between them through your $noun.',
        ),
      ];
    }
    if (path.degrees == 0) {
      return const [
        EmptyState(
          icon: Icons.person,
          message: "That's the same artist: 0 degrees.",
        ),
      ];
    }
    final routes = path.shortestRouteCount;
    return [
      Text(
        '${path.degrees} ${path.degrees == 1 ? 'degree' : 'degrees'}',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
      Text(
        routes == 1
            ? 'The only shortest route'
            : '1 of $routes shortest routes',
        style: metaTextStyle.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < path.artists.length; i++) ...[
        _ArtistStep(artist: path.artists[i]),
        if (i < path.hops.length) _HopStep(hop: path.hops[i]),
      ],
    ];
  }
}

/// A tappable field showing the picked artist (or a prompt).
class _ArtistPickerField extends StatelessWidget {
  const _ArtistPickerField({
    required this.label,
    required this.artist,
    required this.onTap,
  });

  final String label;
  final ConnectionArtist? artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final picked = artist;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: picked == null
            ? const Icon(Icons.person_search)
            : PlaylistCoverGrid(coverImageUrls: picked.coverImageUrls),
        title: Text(
          picked?.name ?? 'Pick an artist',
          style: subtitleTextStyle.copyWith(
            color: picked == null ? scheme.onSurfaceVariant : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(label, style: metaTextStyle),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: onTap,
      ),
    );
  }
}

class _ArtistSearchDialog extends StatefulWidget {
  const _ArtistSearchDialog({required this.artists});

  final List<ConnectionArtist> artists;

  @override
  State<_ArtistSearchDialog> createState() => _ArtistSearchDialogState();
}

class _ArtistSearchDialogState extends State<_ArtistSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // Case-folded in Dart so non-ASCII names match too.
    final query = _query.trim().toLowerCase();
    final matches = query.isEmpty
        ? widget.artists
        : widget.artists
              .where((a) => a.name.toLowerCase().contains(query))
              .toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search artists',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      message: 'No matching artists.',
                    )
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final artist = matches[index];
                        return ListTile(
                          leading: PlaylistCoverGrid(
                            coverImageUrls: artist.coverImageUrls,
                            size: 40,
                          ),
                          title: Text(
                            artist.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.of(context).pop(artist),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistStep extends StatelessWidget {
  const _ArtistStep({required this.artist});

  final ConnectionArtist artist;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: PlaylistCoverGrid(coverImageUrls: artist.coverImageUrls),
        title: Text(
          artist.name,
          style: titleTextStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openArtistById(context, artist.id),
      ),
    );
  }
}

/// The mixlist linking two artists, with each one's song on it, drawn on a
/// connector line between their cards.
class _HopStep extends StatelessWidget {
  const _HopStep({required this.hop});

  final ConnectionHop hop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget song(ConnectionAppearance a) => Row(
      children: [
        AlbumArtThumbnail(imageUrl: a.coverImageURL, size: 20, borderRadius: 3),
        const SizedBox(width: 6),
        Flexible(
          child: HoverableLink(
            text: a.songName,
            onTap: () => openSongById(context, a.songId),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            verticalPadding: 4,
          ),
        ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Container(
                width: 2,
                color: scheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HoverableLink(
                    text: '#${hop.position} ${hop.mixlist.title}',
                    onTap: () => openMixlist(
                      context,
                      hop.mixlist,
                      highlightSongId: hop.from.songId,
                    ),
                    style: subtitleTextStyle.copyWith(color: scheme.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    verticalPadding: 4,
                  ),
                  song(hop.from),
                  song(hop.to),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
