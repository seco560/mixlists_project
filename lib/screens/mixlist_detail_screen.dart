import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/models/mixlist.dart';
import 'package:mixlists_project/models/mixlist_summary.dart';
import 'package:mixlists_project/models/mixlist_track.dart';

class MixlistDetailScreen extends StatefulWidget {
  const MixlistDetailScreen({super.key, required this.mixlist});

  final Mixlist mixlist;

  @override
  State<MixlistDetailScreen> createState() => _MixlistDetailScreenState();
}

class _MixlistDetailScreenState extends State<MixlistDetailScreen> {
  List<MixlistTrack> _tracks = [];
  Map<int, List<MixlistSummary>> _duplicateSongIndex = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _durationInSeconds(int durationMs) {
    final minutes = (durationMs / 1000 / 60).toInt();
    final seconds = (durationMs / 1000 % 60).toInt();
    return "$minutes:${seconds < 10 ? '0' : ''}$seconds";
  }

  Future<void> _loadData() async {
    final repository = getIt<MusicLibraryRepository>();
    try {
      final tracksFuture = repository.getTracksForMixlist(widget.mixlist.id);
      final duplicateIndexFuture = repository.duplicateSongIndex;
      final tracks = await tracksFuture;
      final duplicateIndex = await duplicateIndexFuture;
      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _duplicateSongIndex = duplicateIndex;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading tracks: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openMixlist(int mixlistId) async {
    final fullMixlistData = await getIt<MusicLibraryRepository>().mixlists
        .getById(mixlistId);
    if (!mounted || fullMixlistData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MixlistDetailScreen(mixlist: fullMixlistData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${widget.mixlist.id}) ${widget.mixlist.title} | ${widget.mixlist.dateCreated.split('T')[0]}",
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
              separatorBuilder: (_, _) => Divider(color: Colors.blueGrey),
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final otherMixlists =
                    (_duplicateSongIndex[track.songId] ??
                            const <MixlistSummary>[])
                        .where((m) => m.id != widget.mixlist.id)
                        .toList();

                return _TrackTile(
                  key: ValueKey(track.position),
                  track: track,
                  durationLabel: _durationInSeconds(track.durationMs!),
                  otherMixlists: otherMixlists,
                  onOtherMixlistTap: _openMixlist,
                );
              },
            ),
    );
  }
}

class _TrackTile extends StatefulWidget {
  const _TrackTile({
    super.key,
    required this.track,
    required this.durationLabel,
    required this.otherMixlists,
    required this.onOtherMixlistTap,
  });

  final MixlistTrack track;
  final String durationLabel;
  final List<MixlistSummary> otherMixlists;
  final ValueChanged<int> onOtherMixlistTap;

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _revealAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<double> _popAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final hasDuplicates = widget.otherMixlists.isNotEmpty;

    return Column(
      crossAxisAlignment: .start,
      children: [
        ListTile(
          title: Text(
            "${track.position}) ${track.songName}",
            style: TextStyle(fontSize: 18, fontWeight: .bold),
          ),
          subtitle: Text(
            '${track.artistNames} \u2022 ${track.albumName}',
            style: TextStyle(fontSize: 14, fontWeight: .w500),
          ),
          trailing: Row(
            mainAxisSize: .min,
            children: [
              if (hasDuplicates)
                Padding(
                  padding: .only(right: 8.0),
                  child: ActionChip(
                    avatar: const Icon(Icons.repeat, size: 16),
                    label: Text('${widget.otherMixlists.length}'),
                    onPressed: _toggleExpanded,
                  ),
                ),
              Text(
                widget.durationLabel,
                style: TextStyle(fontSize: 20, fontWeight: .bold),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  mainAxisAlignment: .center,
                  children: [
                    Text(widget.track.dateAdded.split("T")[0]),
                    Text(widget.track.dateAdded.split("T")[1].split("Z")[0]),
                  ],
                ),
              ),
            ],
          ),
          leading: Image.network(track.albumCoverImageURL),
        ),
        if (hasDuplicates)
          Align(
            alignment: .topRight,
            child: SizeTransition(
              sizeFactor: _revealAnimation,
              alignment: .bottomLeft,
              child: ScaleTransition(
                scale: _popAnimation,
                alignment: .topRight,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Align(
                    alignment: .centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: _OtherMixlistsList(
                        mixlists: widget.otherMixlists,
                        onTap: widget.onOtherMixlistTap,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _OtherMixlistsList extends StatelessWidget {
  const _OtherMixlistsList({required this.mixlists, required this.onTap});

  final List<MixlistSummary> mixlists;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: .only(top: 4, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: .circular(12),
      ),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: .only(left: 12, top: 8, right: 12, bottom: 4),
            child: Text(
              'Also appears in',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final mixlist in mixlists)
            Material(
              child: ListTile(
                dense: true,
                visualDensity: .compact,
                title: Text(
                  "${mixlist.id}) ${mixlist.title}",
                  style: TextStyle(fontSize: 12, fontWeight: .w600),
                ),
                onTap: () => onTap(mixlist.id),
              ),
            ),
        ],
      ),
    );
  }
}
