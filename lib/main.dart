import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/data/library/active_library_controller.dart';
import 'package:mixlists_project/data/library/library_manager.dart';
import 'package:mixlists_project/data/spotify/spotify_client_id_store.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/screens/home/home_screen.dart';
import 'package:mixlists_project/theme/app_theme.dart';
import 'package:mixlists_project/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final libraryManager = await LibraryManager.create();
  final (:database, :record) = await libraryManager.bootstrap();
  final prefs = await SharedPreferences.getInstance();

  getIt.registerSingleton<LibraryManager>(libraryManager);
  getIt.registerSingleton<MusicLibraryRepository>(MusicLibraryRepository(database));
  getIt.registerSingleton<ActiveLibraryController>(ActiveLibraryController(record));
  getIt.registerSingleton<SpotifyClientIdStore>(SpotifyClientIdStore(prefs));
  getIt.registerSingleton<MixlistFilterController>(MixlistFilterController());
  getIt.registerSingleton<ThemeController>(ThemeController.load(prefs));
  unawaited(
    getIt<MusicLibraryRepository>().duplicateSongIndex(
      filter: getIt<MixlistFilterController>().value,
    ),
  );

  runApp(const MixlistsMain());
}

/// Enable click-and-drag for mouse based interfaces
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    ...super.dragDevices,
    PointerDeviceKind.mouse,
  };
}

class MixlistsMain extends StatelessWidget {
  const MixlistsMain({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: getIt<ThemeController>(),
      builder: (context, themeMode, _) => MaterialApp(
        title: 'The Mixlists Project',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        scrollBehavior: _AppScrollBehavior(),
        home: const HomeScreen(),
      ),
    );
  }
}
