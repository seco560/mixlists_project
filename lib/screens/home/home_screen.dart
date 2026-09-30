import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/filter/mixlist_wording.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_record.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/screens/albums/albums_grid_screen.dart';
import 'package:mixlists_project/screens/albums/all_labels_screen.dart';
import 'package:mixlists_project/screens/artists/all_artists_screen.dart';
import 'package:mixlists_project/screens/artists/all_genres_screen.dart';
import 'package:mixlists_project/screens/home/home_nav_card.dart';
import 'package:mixlists_project/screens/home/playlists_filter_label.dart';
import 'package:mixlists_project/screens/home/search_field.dart';
import 'package:mixlists_project/screens/library/library_picker_screen.dart';
import 'package:mixlists_project/screens/mixlists/all_mixlists_screen.dart';
import 'package:mixlists_project/screens/songs/all_songs_screen.dart';
import 'package:mixlists_project/screens/timeline/taste_timeline_screen.dart';
import 'package:mixlists_project/widgets/shared/category_tile.dart';
import 'package:mixlists_project/widgets/shared/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/shared/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/shared/text_styles.dart';
import 'package:mixlists_project/widgets/home/theme_mode_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _maxWidth = 760.0;
  static const _spacing = 12.0;

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, QuickStylePageRoute(builder: (context) => screen));
  }

  List<Widget> _cards(BuildContext context) => [
    HomeNavCard(
      icon: Icons.queue_music,
      title: const PlaylistsFilterLabel(),
      caption: Text(
        'Simplest view',
      ),
      onTap: () => _push(context, const AllMixlistsScreen()),
    ),
    HomeNavCard(
      icon: Icons.timeline,
      label: 'Timelines',
      caption: const Text('Visualizations of trends'),
      onTap: () => _push(context, const TasteTimelineScreen()),
    ),
    HomeNavCard(
      icon: Icons.person,
      label: 'Artists',
      caption: const Text('A proper leaderboard'),
      onTap: () => _push(context, const AllArtistsScreen()),
    ),
    HomeNavCard(
      icon: Icons.album,
      label: 'Albums',
      caption: const Text('The records of origin'),
      onTap: () => _push(context, const AlbumsGridScreen()),
    ),
    HomeNavCard(
      icon: Icons.music_note,
      label: 'Songs',
      caption: const Text('Leaderboard, for songs'),
      onTap: () => _push(context, const AllSongsScreen()),
    ),
    HomeNavCard(
      icon: CategoryTile.genreIcon,
      label: 'Genres',
      caption: const Text('Artists in genre buckets'),
      onTap: () => _push(context, const AllGenresScreen()),
    ),
    HomeNavCard(
      icon: CategoryTile.labelIcon,
      label: 'Labels',
      caption: const Text('Albums in label buckets'),
      onTap: () => _push(context, const AllLabelsScreen()),
    ),
    if (!kIsWeb)
      HomeNavCard(
        icon: Icons.library_music,
        label: 'Libraries',
        caption: ValueListenableBuilder<LibraryRecord>(
          valueListenable: getIt<ActiveLibraryController>(),
          builder: (context, library, _) =>
              Text('Active: ${library.displayName}'),
        ),
        onTap: () => _push(context, const LibraryPickerScreen()),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = _cards(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      Text(
                        'The Mixlists Project',
                        textAlign: .center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: .w800,
                          letterSpacing: -0.5,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SearchField(),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const MixlistFilterToggle(),
                          Text(
                            'Filter by mixlists only, all playlists, or only unmarked ones',
                            style: metaTextStyle.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 640
                              ? 4
                              : width >= 420
                              ? 3
                              : 2;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: _spacing,
                            crossAxisSpacing: _spacing,
                            childAspectRatio:
                                ((width - _spacing * (columns - 1)) / columns) /
                                HomeNavCard.height,
                            children: cards,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: ThemeModeToggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
