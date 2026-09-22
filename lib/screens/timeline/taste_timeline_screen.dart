import 'package:flutter/material.dart';
import 'package:mixlists_core/mixlists_core.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_entry.dart';
import 'package:mixlists_project/data/breadcrumb/breadcrumb_push.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/models/taste_timeline.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/artists/artist_detail_screen.dart';
import 'package:mixlists_project/screens/mixlists/mixlist_detail_screen.dart';
import 'package:mixlists_project/widgets/breadcrumb/breadcrumb_trail_button.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/section_header.dart';
import 'package:mixlists_project/widgets/timeline/artist_lifespan_list.dart';
import 'package:mixlists_project/widgets/timeline/feature_trend_chart.dart';
import 'package:mixlists_project/widgets/timeline/genre_drift_chart.dart';
import 'package:mixlists_project/widgets/timeline/music_age_chart.dart';

/// Library-wide trends across mixlists in chronological order: audio
/// features, genre mix, music age and artist lifespans.
class TasteTimelineScreen extends StatefulWidget {
  const TasteTimelineScreen({super.key});

  @override
  State<TasteTimelineScreen> createState() => _TasteTimelineScreenState();
}

class _TasteTimelineScreenState extends State<TasteTimelineScreen> {
  TasteTimeline? _timeline;
  bool _isLoading = true;
  String? _error;

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
    try {
      final timeline = await getIt<MusicLibraryRepository>().getTasteTimeline(
        filter: getIt<MixlistFilterController>().value,
      );
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading timeline: $e';
        _isLoading = false;
      });
    }
  }

  void _openMixlist(TimelineMixlistPoint point) {
    final Mixlist mixlist = point.mixlist;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.mixlist,
        entityId: mixlist.id,
        title: mixlist.title,
      ),
      builder: (context) => MixlistDetailScreen(mixlist: mixlist),
    );
  }

  Future<void> _openArtist(ArtistLifespan lifespan) async {
    final overview = await getIt<MusicLibraryRepository>()
        .getArtistOverviewById(lifespan.artistId);
    if (!mounted || overview == null) return;
    pushWithBreadcrumb(
      context,
      entry: BreadcrumbEntry(
        kind: BreadcrumbKind.artist,
        entityId: overview.id,
        title: overview.name,
        mosaicUrls: [for (final a in overview.albums.take(4)) a.coverImageURL],
      ),
      builder: (context) => ArtistDetailScreen(artist: overview),
    );
  }

  Widget _buildBody(TasteTimeline timeline) {
    final filter = getIt<MixlistFilterController>().value;
    final singular = filter.playlistNounSingularLower;
    final plural = filter.playlistNounPluralLower;
    if (timeline.isEmpty) {
      return Center(child: Text('No $plural yet.'));
    }
    final points = timeline.points;
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        const SectionHeader('Artist Lifespans'),
        ArtistLifespanList(
          points: points,
          lifespans: timeline.artistLifespans,
          onArtistTap: _openArtist,
          playlistNounPluralLower: plural,
        ),
        const Divider(),
        const SectionHeader('Audio Features Over Time'),
        FeatureTrendChart(
          points: points,
          onPointTap: _openMixlist,
          playlistNounSingularLower: singular,
          playlistNounPluralLower: plural,
        ),
        const Divider(),
        const SectionHeader('Genre Drift'),
        GenreDriftChart(
          points: points,
          bands: timeline.genreBands,
          windows: timeline.genreWindows,
          playlistNounPluralLower: plural,
        ),
        const Divider(),
        const SectionHeader('Age of Music When Added'),
        MusicAgeChart(
          points: points,
          overallMedianYears: timeline.overallMedianMusicAgeYears,
          onPointTap: _openMixlist,
          playlistNounSingularLower: singular,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _timeline;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timelines'),
        centerTitle: true,
        actions: const [MixlistFilterToggle()],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(timeline!),
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
}
