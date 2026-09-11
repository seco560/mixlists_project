import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

class ArtistResultTile extends StatelessWidget {
  const ArtistResultTile({super.key, required this.artist, required this.onTap});

  final ArtistOverview artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(artist.name, style: titleTextStyle),
      subtitle: Text(
        '${artist.uniqueSongCount} song${artist.uniqueSongCount == 1 ? '' : 's'} on mixlists • '
        '${artist.albums.length} album${artist.albums.length == 1 ? '' : 's'}',
        style: metaTextStyle,
      ),
      onTap: onTap,
    );
  }
}
