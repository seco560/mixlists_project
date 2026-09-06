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

  void _showOtherMixlists(List<MixlistSummary> otherMixlists) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Also appears in'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final mixlist in otherMixlists)
              ListTile(
                title: Text(mixlist.title),
                onTap: () async {
                  Navigator.pop(context);
                  final fullMixlistData = await getIt<MusicLibraryRepository>()
                      .mixlists
                      .getById(mixlist.id);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MixlistDetailScreen(mixlist: fullMixlistData!),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mixlist.title), centerTitle: true),
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

                return ListTile(
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
                    mainAxisAlignment: .end,
                    crossAxisAlignment: .end,
                    children: [
                      if (otherMixlists.isNotEmpty)
                        ActionChip(
                          avatar: const Icon(Icons.repeat, size: 16),
                          label: Text('${otherMixlists.length}'),
                          onPressed: () => _showOtherMixlists(otherMixlists),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          _durationInSeconds(track.durationMs!),
                          style: TextStyle(fontSize: 20, fontWeight: .bold),
                        ),
                      ),
                    ],
                  ),
                  leading: Image.network(track.albumCoverImageURL),
                );
              },
            ),
    );
  }
}