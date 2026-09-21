import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:mixlists_project/widgets/mixlist_filter_toggle.dart';
import 'package:mixlists_project/widgets/quick_style_page_route.dart';
import 'package:mixlists_project/widgets/text_styles.dart';
import 'package:mixlists_project/widgets/theme_mode_toggle.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: .center,
                    mainAxisAlignment: .center,
                    children: [
                      Text(
                        "The Mixlists Project",
                        textAlign: .center,
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: .bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SearchField(),
                      const SizedBox(height: 24),
                      if (!kIsWeb) ...[
                        HomeNavCard(
                          icon: Icons.library_music,
                          label: 'Libraries',
                          onTap: () {
                            Navigator.push(
                              context,
                              QuickStylePageRoute(
                                builder: (context) => const LibraryPickerScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        ValueListenableBuilder<LibraryRecord>(
                          valueListenable: getIt<ActiveLibraryController>(),
                          builder: (context, library, _) => Text(
                            "Active library: ${library.displayName}",
                            textAlign: .center,
                            style: metaTextStyle,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const MixlistFilterToggle(),
                      const SizedBox(height: 8),
                      const Text(
                        'Show only mixlists, all playlists in the app,'
                        'or only the ones that aren\'t marked.',
                        textAlign: .center,
                        style: metaTextStyle,
                      ),
                      const SizedBox(height: 24),
                      HomeNavCard(
                        icon: Icons.queue_music,
                        title: const PlaylistsFilterLabel(),
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AllMixlistsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      HomeNavCard(
                        icon: Icons.person,
                        label: 'Artists',
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AllArtistsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      HomeNavCard(
                        icon: Icons.album,
                        label: 'Albums',
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AlbumsGridScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      HomeNavCard(
                        icon: Icons.music_note,
                        label: 'Songs',
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AllSongsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      HomeNavCard(
                        icon: Icons.sell_outlined,
                        label: 'Genres',
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AllGenresScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      HomeNavCard(
                        icon: Icons.business_outlined,
                        label: 'Labels',
                        onTap: () {
                          Navigator.push(
                            context,
                            QuickStylePageRoute(
                              builder: (context) => AllLabelsScreen(),
                            ),
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
