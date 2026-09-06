import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mixlists_project/helpers/app_database.dart';
import 'package:mixlists_project/helpers/get_it_init.dart';
import 'package:mixlists_project/helpers/music_library_repository.dart';
import 'package:mixlists_project/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final database = await openAppDatabase();
  getIt.registerSingleton<MusicLibraryRepository>(MusicLibraryRepository(database));
  unawaited(getIt<MusicLibraryRepository>().duplicateSongIndex);

  runApp(const MixlistsMain());
}

class MixlistsMain extends StatelessWidget {
  const MixlistsMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Mixlists Project',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepOrange)),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
