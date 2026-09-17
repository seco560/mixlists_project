import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mixlists_project/data/database/app_database.dart';
import 'package:mixlists_project/data/filter/mixlist_filter_controller.dart';
import 'package:mixlists_project/get_it_init.dart';
import 'package:mixlists_project/data/repository/music_library_repository.dart';
import 'package:mixlists_project/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await openAppDatabase();
  getIt.registerSingleton<MusicLibraryRepository>(MusicLibraryRepository(database));
  getIt.registerSingleton<MixlistFilterController>(MixlistFilterController());
  unawaited(getIt<MusicLibraryRepository>().duplicateSongIndex);

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
    return MaterialApp(
      title: 'The Mixlists Project',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepOrange)),
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      home: HomeScreen(),
    );
  }
}
