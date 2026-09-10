import 'package:flutter/material.dart';
import 'package:mixlists_project/models/view_models/artist_overview.dart';
import 'package:mixlists_project/widgets/text_styles.dart';

/// Artists section row -- no reusable artist ListTile exists elsewhere in
/// the app (AllArtistsScreen builds a bespoke sortable table), so this is
/// new. Subtitle reuses fields ArtistOverview already carries.
class ArtistResultTile extends StatelessWidget {
  const ArtistResultTile({super.key, required this.artist, required this.onTap});

  final ArtistOverview artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(artist.name, style: titleTextStyle),
      subtitle: Text(
        '${artist.albums.length} album${artist.albums.length == 1 ? '' : 's'} • '
        '${artist.uniqueSongCount} song${artist.uniqueSongCount == 1 ? '' : 's'} on mixlists',
        style: metaTextStyle,
      ),
      onTap: onTap,
    );
  }
}
